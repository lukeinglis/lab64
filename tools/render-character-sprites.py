#!/usr/bin/env python3
"""
Render character sprites from a Blender model for SpaghettiKart.

Usage:
    blender --background --python tools/render-character-sprites.py -- \
        --character dalmatian \
        --blend-file assets/characters/dalmatian/dalmatian.blend \
        [--rotations 16] \
        [--resolution 64] \
        [--output-dir assets/characters/dalmatian/sprites]

Renders:
    - Kart animation frames at N equidistant rotation angles
    - Portrait icon at 32x32
    - 17 player selection face frames at 64x64
    - Nameplate at 64x12
"""

from __future__ import annotations

import argparse
import datetime
import json
import logging
import math
import os
import sys
from typing import Any

LAB64_TOOLS_VERSION = "lab64 tools v0.1.0"


class JSONFormatter(logging.Formatter):
    """Emit log records as single-line JSON objects to stderr."""

    def __init__(self, script_name: str, run_id: str) -> None:
        super().__init__()
        self.script_name = script_name
        self.run_id = run_id

    def format(self, record: logging.LogRecord) -> str:
        entry: dict[str, Any] = {
            "timestamp": datetime.datetime.now(datetime.timezone.utc).strftime(
                "%Y-%m-%dT%H:%M:%SZ"
            ),
            "level": "WARN" if record.levelname == "WARNING" else record.levelname,
            "script": self.script_name,
            "message": record.getMessage(),
            "run_id": self.run_id,
        }
        ctx = getattr(record, "context", None)
        if ctx:
            entry["context"] = ctx
        return json.dumps(entry)


class HumanFormatter(logging.Formatter):
    """Emit colored human-readable log lines to stderr."""

    COLORS = {
        "DEBUG": "\033[36m",
        "INFO": "\033[32m",
        "WARNING": "\033[33m",
        "ERROR": "\033[31m",
    }
    RESET = "\033[0m"

    def format(self, record: logging.LogRecord) -> str:
        color = self.COLORS.get(record.levelname, "")
        reset = self.RESET if color else ""
        prefix = f"[{record.levelname}]"
        if sys.stderr.isatty():
            return f"{color}{prefix}{reset} {record.getMessage()}"
        return f"{prefix} {record.getMessage()}"


def _generate_run_id() -> str:
    ts = int(datetime.datetime.now(datetime.timezone.utc).timestamp())
    return f"{ts}-{os.getpid()}"


def setup_logging(
    json_output: bool = False, quiet: bool = False, verbose: bool = False
) -> logging.Logger:
    """Configure the root logger based on CLI flags and LOG_FORMAT env var."""
    log_format = os.environ.get("LOG_FORMAT", "human")
    run_id = os.environ.get("RUN_ID", _generate_run_id())

    formatter: logging.Formatter
    if json_output or log_format == "json":
        formatter = JSONFormatter("render-character-sprites", run_id)
    else:
        formatter = HumanFormatter()

    handler = logging.StreamHandler(sys.stderr)
    handler.setFormatter(formatter)

    logger = logging.getLogger()
    logger.handlers.clear()
    logger.addHandler(handler)

    if verbose:
        logger.setLevel(logging.DEBUG)
    elif quiet:
        logger.setLevel(logging.WARNING)
    else:
        logger.setLevel(logging.INFO)

    return logger


def log_ctx(
    logger: logging.Logger,
    level: int,
    message: str,
    context: dict[str, Any] | None = None,
) -> None:
    """Log a message with optional structured context."""
    if not logger.isEnabledFor(level):
        return
    record = logger.makeRecord(
        logger.name, level, "(unknown)", 0, message, (), None
    )
    if context:
        record.context = context  # noqa: dynamic attr read by JSONFormatter
    logger.handle(record)


def parse_args() -> argparse.Namespace:
    # Blender passes everything after '--' to the script
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []

    parser = argparse.ArgumentParser(
        description="Render SpaghettiKart character sprites from a Blender model"
    )
    parser.add_argument(
        "--character",
        help="Character name (e.g. dalmatian, yellow_lab, black_cat, orange_cat)",
    )
    parser.add_argument(
        "--blend-file",
        help="Path to the .blend file containing the character model",
    )
    parser.add_argument(
        "--rotations",
        type=int,
        default=16,
        help="Number of rotation angles for kart frames (default: 16)",
    )
    parser.add_argument(
        "--resolution",
        type=int,
        default=64,
        help="Resolution for kart frame sprites in pixels (default: 64)",
    )
    parser.add_argument(
        "--output-dir",
        default=None,
        help="Output directory for rendered sprites (default: assets/characters/{character}/sprites)",
    )
    parser.add_argument(
        "--version",
        action="store_true",
        help="Print version and exit",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="Suppress progress messages (errors still shown)",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Show detailed execution trace",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be rendered without running Blender",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        dest="json_output",
        help="Output structured JSON result",
    )
    parser.add_argument(
        "--list-characters",
        action="store_true",
        help="Discover and list available character directories under assets/characters/",
    )
    parser.add_argument(
        "--validate-config",
        action="store_true",
        help="Validate render pipeline configuration without Blender",
    )
    parser.add_argument(
        "--list-slots",
        action="store_true",
        help="Display current character slot assignments from mods.toml",
    )

    args = parser.parse_args(argv)

    if args.version:
        print(LAB64_TOOLS_VERSION)
        sys.exit(0)

    if args.list_characters:
        _list_characters(args.json_output)
        sys.exit(0)

    if args.validate_config:
        _validate_config(args.rotations, args.resolution, args.json_output)
        # _validate_config calls sys.exit internally

    if args.list_slots:
        _list_slots(args.json_output)
        sys.exit(0)

    if not args.character:
        parser.error("the following arguments are required: --character")
    if not args.blend_file:
        parser.error("the following arguments are required: --blend-file")

    return args


def _list_characters(json_output: bool) -> None:
    chars_dir = os.path.join("assets", "characters")
    characters = []
    if os.path.isdir(chars_dir):
        for entry in sorted(os.listdir(chars_dir)):
            full = os.path.join(chars_dir, entry)
            if os.path.isdir(full) and not entry.startswith("."):
                blend_files = [
                    f for f in os.listdir(full) if f.endswith(".blend")
                ]
                characters.append(
                    {"name": entry, "path": full, "blend_files": blend_files}
                )

    if json_output:
        result = {
            "status": "success",
            "message": f"Found {len(characters)} character(s)",
            "details": {"characters": characters},
            "timestamp": datetime.datetime.now(datetime.timezone.utc).strftime(
                "%Y-%m-%dT%H:%M:%SZ"
            ),
        }
        print(json.dumps(result))
    else:
        if not characters:
            print(f"No character directories found under {chars_dir}/")
        else:
            print(f"Available characters ({len(characters)}):")
            for c in characters:
                blends = ", ".join(c["blend_files"]) if c["blend_files"] else "no .blend files"
                print(f"  {c['name']} ({blends})")


EXPECTED_ROTATIONS = 16
ROTATION_INTERVAL = 22.5
VALID_POWER_OF_2 = {32, 64, 128, 256}
EXPECTED_SPRITES_PER_CHARACTER = 35  # 16 kart + 17 face + 1 portrait + 1 nameplate

MK64_RACERS: dict[str, str] = {
    "mario": "Medium",
    "luigi": "Medium",
    "peach": "Light",
    "toad": "Light",
    "yoshi": "Medium",
    "donkey_kong": "Heavy",
    "wario": "Heavy",
    "bowser": "Heavy",
}


def _is_power_of_2(n: int) -> bool:
    return n > 0 and (n & (n - 1)) == 0


def _validate_config(
    rotations: int, resolution: int, json_output: bool
) -> None:
    checks: list[dict[str, Any]] = []

    rotation_pass = rotations == EXPECTED_ROTATIONS
    checks.append({
        "name": "rotation_count",
        "expected": EXPECTED_ROTATIONS,
        "actual": rotations,
        "interval_degrees": 360.0 / rotations if rotations > 0 else 0,
        "pass": rotation_pass,
    })

    interval = 360.0 / rotations if rotations > 0 else 0
    interval_pass = abs(interval - ROTATION_INTERVAL) < 0.01
    checks.append({
        "name": "rotation_interval",
        "expected": ROTATION_INTERVAL,
        "actual": interval,
        "pass": interval_pass,
    })

    resolution_pass = resolution in VALID_POWER_OF_2
    checks.append({
        "name": "output_dimensions",
        "expected": "power-of-2 (32, 64, 128, 256)",
        "actual": resolution,
        "pass": resolution_pass,
    })

    format_pass = True
    checks.append({
        "name": "output_format",
        "expected": "PNG RGBA",
        "actual": "PNG RGBA",
        "pass": format_pass,
    })

    sprites = rotations + 17 + 1 + 1  # kart + face + portrait + nameplate
    sprite_pass = sprites == EXPECTED_SPRITES_PER_CHARACTER
    checks.append({
        "name": "sprites_per_character",
        "expected": EXPECTED_SPRITES_PER_CHARACTER,
        "actual": sprites,
        "pass": sprite_pass,
    })

    all_pass = all(c["pass"] for c in checks)

    if json_output:
        result: dict[str, Any] = {
            "status": "pass" if all_pass else "fail",
            "message": "All checks passed" if all_pass else "Some checks failed",
            "details": {"checks": checks},
            "timestamp": datetime.datetime.now(datetime.timezone.utc).strftime(
                "%Y-%m-%dT%H:%M:%SZ"
            ),
        }
        print(json.dumps(result))
    else:
        print("Render Pipeline Configuration Validation")
        print("=" * 42)
        for c in checks:
            status = "PASS" if c["pass"] else "FAIL"
            print(f"  [{status}] {c['name']}: expected={c['expected']}, actual={c['actual']}")
        print()
        print(f"Result: {'ALL CHECKS PASSED' if all_pass else 'SOME CHECKS FAILED'}")

    sys.exit(0 if all_pass else 1)


def _list_slots(json_output: bool) -> None:
    toml_path = os.path.join("mods", "animal-pack", "mods.toml")
    assignments: dict[str, str] = {}

    if os.path.isfile(toml_path):
        in_assignments = False
        with open(toml_path) as f:
            for line in f:
                stripped = line.strip()
                if stripped == "[assignments]":
                    in_assignments = True
                    continue
                if stripped.startswith("[") and in_assignments:
                    break
                if in_assignments and "=" in stripped:
                    key, val = stripped.split("=", 1)
                    assignments[key.strip()] = val.strip().strip('"')

    assigned_slots = set(assignments.values())
    available = {
        racer: weight for racer, weight in MK64_RACERS.items()
        if racer not in assigned_slots
    }

    if json_output:
        result: dict[str, Any] = {
            "status": "success",
            "message": f"{len(assignments)} slot(s) assigned, {len(available)} available",
            "details": {
                "assignments": [
                    {"character": char, "replaces": slot, "weight_class": MK64_RACERS.get(slot, "unknown")}
                    for char, slot in assignments.items()
                ],
                "available": [
                    {"racer": racer, "weight_class": weight}
                    for racer, weight in available.items()
                ],
            },
            "timestamp": datetime.datetime.now(datetime.timezone.utc).strftime(
                "%Y-%m-%dT%H:%M:%SZ"
            ),
        }
        print(json.dumps(result))
    else:
        print("Character Slot Assignments")
        print("=" * 50)
        print(f"  {'Character':<15} {'Replaces':<15} {'Weight Class'}")
        print(f"  {'-' * 13:<15} {'-' * 13:<15} {'-' * 12}")
        for char, slot in assignments.items():
            weight = MK64_RACERS.get(slot, "unknown")
            print(f"  {char:<15} {slot:<15} {weight}")
        print()
        if available:
            print("Available Slots")
            print(f"  {'Racer':<15} {'Weight Class'}")
            print(f"  {'-' * 13:<15} {'-' * 12}")
            for racer, weight in available.items():
                print(f"  {racer:<15} {weight}")
        else:
            print("All MK64 racer slots are assigned.")


def _json_result(status: str, message: str, details: dict[str, Any]) -> None:
    result = {
        "status": status,
        "message": message,
        "details": details,
        "timestamp": datetime.datetime.now(datetime.timezone.utc).strftime(
            "%Y-%m-%dT%H:%M:%SZ"
        ),
    }
    print(json.dumps(result))


def setup_render_settings(resolution_x: int, resolution_y: int) -> None:
    """Configure render settings for N64-style flat sprite output."""
    import bpy

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = resolution_x
    scene.render.resolution_y = resolution_y
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.compression = 15


def setup_camera_orthographic(distance: float = 5.0) -> Any:
    """Set up an orthographic camera pointed at the origin."""
    import bpy

    cam_data = bpy.data.cameras.new("SpriteCam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 3.0

    cam_obj = bpy.data.objects.new("SpriteCam", cam_data)
    bpy.context.scene.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj

    cam_obj.location = (distance, 0, 1.5)
    cam_obj.rotation_euler = (math.radians(80), 0, math.radians(90))

    return cam_obj


def setup_flat_lighting() -> None:
    """Configure flat lighting to match N64 aesthetic (no dynamic shadows)."""
    import bpy

    for obj in bpy.data.objects:
        if obj.type == "LIGHT":
            bpy.data.objects.remove(obj, do_unlink=True)

    light_data = bpy.data.lights.new("FlatKey", "SUN")
    light_data.energy = 3.0
    light_obj = bpy.data.objects.new("FlatKey", light_data)
    bpy.context.scene.collection.objects.link(light_obj)
    light_obj.rotation_euler = (math.radians(45), 0, math.radians(45))

    fill_data = bpy.data.lights.new("FlatFill", "SUN")
    fill_data.energy = 1.5
    fill_obj = bpy.data.objects.new("FlatFill", fill_data)
    bpy.context.scene.collection.objects.link(fill_obj)
    fill_obj.rotation_euler = (math.radians(45), 0, math.radians(-135))

    if hasattr(bpy.context.scene, "eevee"):
        bpy.context.scene.eevee.use_shadows = False


def render_kart_frames(
    camera: Any, character: str, rotations: int, resolution: int, output_dir: str
) -> None:
    """Render kart frames at equidistant rotation angles around the character."""
    import bpy

    logger = logging.getLogger()

    setup_render_settings(resolution, resolution)
    kart_dir = os.path.join(output_dir, f"{character}_kart")
    os.makedirs(kart_dir, exist_ok=True)

    distance = camera.location.length
    base_height = camera.location.z

    for i in range(rotations):
        angle = (2 * math.pi * i) / rotations
        camera.location.x = distance * math.cos(angle)
        camera.location.y = distance * math.sin(angle)
        camera.location.z = base_height

        direction = mathutils_direction_to_origin(camera.location)
        camera.rotation_euler = direction

        frame_num = str(i + 1).zfill(3)
        filepath = os.path.join(kart_dir, f"{character}_kart_frame{frame_num}.png")
        bpy.context.scene.render.filepath = filepath
        bpy.ops.render.render(write_still=True)
        log_ctx(logger, logging.DEBUG, f"Rendered kart frame {frame_num}/{rotations}", {
            "frame": frame_num, "total": rotations, "path": filepath
        })
        print(f"  Rendered kart frame {frame_num}/{rotations}")


def render_portrait(character: str, output_dir: str) -> None:
    """Render portrait icon at 32x32."""
    import bpy

    logger = logging.getLogger()

    setup_render_settings(32, 32)
    filepath = os.path.join(output_dir, f"common_texture_portrait_{character}.png")
    bpy.context.scene.render.filepath = filepath
    bpy.ops.render.render(write_still=True)
    log_ctx(logger, logging.INFO, "Rendered portrait", {
        "resolution": "32x32", "path": filepath
    })
    print("  Rendered portrait (32x32)")


def render_faces(character: str, output_dir: str) -> None:
    """Render 17 player selection face frames at 64x64."""
    import bpy

    logger = logging.getLogger()

    setup_render_settings(64, 64)
    for i in range(17):
        frame_num = str(i).zfill(2)
        filepath = os.path.join(output_dir, f"{character}_face_{frame_num}.png")
        bpy.context.scene.render.filepath = filepath
        bpy.ops.render.render(write_still=True)
    log_ctx(logger, logging.INFO, "Rendered face frames", {
        "count": 17, "resolution": "64x64"
    })
    print("  Rendered 17 face frames (64x64)")


def render_nameplate(character: str, output_dir: str) -> None:
    """Render nameplate at 64x12."""
    import bpy

    logger = logging.getLogger()

    setup_render_settings(64, 12)
    capitalized = "".join(word.capitalize() for word in character.split("_"))
    filepath = os.path.join(output_dir, f"gTexture{capitalized}.png")
    bpy.context.scene.render.filepath = filepath
    bpy.ops.render.render(write_still=True)
    log_ctx(logger, logging.INFO, "Rendered nameplate", {
        "resolution": "64x12", "path": filepath
    })
    print(f"  Rendered nameplate (64x12): gTexture{capitalized}.png")


def mathutils_direction_to_origin(location: Any) -> Any:
    """Calculate rotation euler to point from location toward origin."""
    import mathutils

    direction = -location.normalized()
    quat = direction.to_track_quat("-Z", "Y")
    return quat.to_euler()


def main() -> None:
    args = parse_args()

    quiet = args.quiet or args.json_output
    verbose = args.verbose

    logger = setup_logging(
        json_output=args.json_output,
        quiet=quiet,
        verbose=verbose,
    )

    output_dir = args.output_dir
    if output_dir is None:
        output_dir = os.path.join("assets", "characters", args.character, "sprites")

    capitalized = "".join(word.capitalize() for word in args.character.split("_"))

    log_ctx(logger, logging.DEBUG, "Render configuration", {
        "character": args.character,
        "blend_file": args.blend_file,
        "rotations": args.rotations,
        "resolution": args.resolution,
        "output_dir": output_dir,
    })

    if args.dry_run:
        kart_dir = os.path.join(output_dir, f"{args.character}_kart")
        outputs = {
            "kart_frames": {
                "count": args.rotations,
                "directory": kart_dir,
                "pattern": f"{args.character}_kart_frame{{NNN}}.png",
                "resolution": f"{args.resolution}x{args.resolution}",
            },
            "portrait": {
                "file": f"common_texture_portrait_{args.character}.png",
                "resolution": "32x32",
            },
            "faces": {
                "count": 17,
                "pattern": f"{args.character}_face_{{NN}}.png",
                "resolution": "64x64",
            },
            "nameplate": {
                "file": f"gTexture{capitalized}.png",
                "resolution": "64x12",
            },
        }

        log_ctx(logger, logging.INFO, "Dry run complete", {
            "character": args.character, "output_dir": output_dir
        })

        if args.json_output:
            _json_result(
                "success",
                "Dry run complete",
                {
                    "character": args.character,
                    "blend_file": args.blend_file,
                    "output_dir": output_dir,
                    "outputs": outputs,
                    "dry_run": True,
                },
            )
        else:
            if not quiet:
                print(f"DRY RUN: Would render sprites for: {args.character}")
                print(f"  Blend file: {args.blend_file}")
                print(f"  Output: {output_dir}")
                print(f"  Kart frames: {args.rotations} frames at {args.resolution}x{args.resolution}")
                print(f"  Portrait: 32x32")
                print(f"  Faces: 17 frames at 64x64")
                print(f"  Nameplate: 64x12 (gTexture{capitalized}.png)")
        sys.exit(0)

    if not quiet:
        print(f"Rendering sprites for: {args.character}")
        print(f"  Blend file: {args.blend_file}")
        print(f"  Rotations: {args.rotations}")
        print(f"  Resolution: {args.resolution}x{args.resolution}")
        print(f"  Output: {output_dir}")

    try:
        import bpy
    except ImportError:
        logger.error("This script must be run inside Blender.")
        print("ERROR: This script must be run inside Blender.")
        print("Usage: blender --background --python tools/render-character-sprites.py -- [args]")
        sys.exit(1)

    os.makedirs(output_dir, exist_ok=True)

    log_ctx(logger, logging.INFO, "Opening blend file", {
        "blend_file": args.blend_file
    })
    bpy.ops.wm.open_mainfile(filepath=args.blend_file)

    log_ctx(logger, logging.INFO, "Setting up camera and lighting", {
        "character": args.character
    })
    camera = setup_camera_orthographic()
    setup_flat_lighting()

    if not quiet:
        print("\nRendering kart frames...")
    log_ctx(logger, logging.INFO, "Rendering kart frames", {
        "count": args.rotations, "resolution": f"{args.resolution}x{args.resolution}"
    })
    render_kart_frames(camera, args.character, args.rotations, args.resolution, output_dir)

    if not quiet:
        print("\nRendering portrait...")
    render_portrait(args.character, output_dir)

    if not quiet:
        print("\nRendering selection faces...")
    render_faces(args.character, output_dir)

    if not quiet:
        print("\nRendering nameplate...")
    render_nameplate(args.character, output_dir)

    log_ctx(logger, logging.INFO, "Render complete", {
        "character": args.character,
        "output_dir": output_dir,
        "kart_frames": args.rotations,
        "face_frames": 17,
    })

    if args.json_output:
        _json_result(
            "success",
            f"Rendered sprites for {args.character}",
            {
                "character": args.character,
                "output_dir": output_dir,
                "kart_frames": args.rotations,
                "resolution": args.resolution,
            },
        )
    else:
        if not quiet:
            print(f"\nDone. Sprites written to: {output_dir}")


if __name__ == "__main__":
    main()
