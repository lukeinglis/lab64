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

import argparse
import math
import os
import sys


def parse_args():
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
        required=True,
        help="Character name (e.g. dalmatian, yellow_lab, black_cat, orange_cat)",
    )
    parser.add_argument(
        "--blend-file",
        required=True,
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
    return parser.parse_args(argv)


def setup_render_settings(resolution_x, resolution_y):
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


def setup_camera_orthographic(distance=5.0):
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


def setup_flat_lighting():
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


def render_kart_frames(camera, character, rotations, resolution, output_dir):
    """Render kart frames at equidistant rotation angles around the character."""
    import bpy

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
        print(f"  Rendered kart frame {frame_num}/{rotations}")


def render_portrait(character, output_dir):
    """Render portrait icon at 32x32."""
    import bpy

    setup_render_settings(32, 32)
    filepath = os.path.join(output_dir, f"common_texture_portrait_{character}.png")
    bpy.context.scene.render.filepath = filepath
    bpy.ops.render.render(write_still=True)
    print("  Rendered portrait (32x32)")


def render_faces(character, output_dir):
    """Render 17 player selection face frames at 64x64."""
    import bpy

    setup_render_settings(64, 64)
    for i in range(17):
        frame_num = str(i).zfill(2)
        filepath = os.path.join(output_dir, f"{character}_face_{frame_num}.png")
        bpy.context.scene.render.filepath = filepath
        bpy.ops.render.render(write_still=True)
    print("  Rendered 17 face frames (64x64)")


def render_nameplate(character, output_dir):
    """Render nameplate at 64x12."""
    import bpy

    setup_render_settings(64, 12)
    capitalized = "".join(word.capitalize() for word in character.split("_"))
    filepath = os.path.join(output_dir, f"gTexture{capitalized}.png")
    bpy.context.scene.render.filepath = filepath
    bpy.ops.render.render(write_still=True)
    print(f"  Rendered nameplate (64x12): gTexture{capitalized}.png")


def mathutils_direction_to_origin(location):
    """Calculate rotation euler to point from location toward origin."""
    import mathutils

    direction = -location.normalized()
    quat = direction.to_track_quat("-Z", "Y")
    return quat.to_euler()


def main():
    args = parse_args()

    output_dir = args.output_dir
    if output_dir is None:
        output_dir = os.path.join("assets", "characters", args.character, "sprites")
    os.makedirs(output_dir, exist_ok=True)

    print(f"Rendering sprites for: {args.character}")
    print(f"  Blend file: {args.blend_file}")
    print(f"  Rotations: {args.rotations}")
    print(f"  Resolution: {args.resolution}x{args.resolution}")
    print(f"  Output: {output_dir}")

    try:
        import bpy
    except ImportError:
        print("ERROR: This script must be run inside Blender.")
        print("Usage: blender --background --python tools/render-character-sprites.py -- [args]")
        sys.exit(1)

    bpy.ops.wm.open_mainfile(filepath=args.blend_file)

    camera = setup_camera_orthographic()
    setup_flat_lighting()

    print("\nRendering kart frames...")
    render_kart_frames(camera, args.character, args.rotations, args.resolution, output_dir)

    print("\nRendering portrait...")
    render_portrait(args.character, output_dir)

    print("\nRendering selection faces...")
    render_faces(args.character, output_dir)

    print("\nRendering nameplate...")
    render_nameplate(args.character, output_dir)

    print(f"\nDone. Sprites written to: {output_dir}")


if __name__ == "__main__":
    main()
