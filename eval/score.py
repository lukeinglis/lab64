#!/usr/bin/env python3
"""Eval script for Lab 64 modding toolchain.

Measures four dimensions:
  1. tooling_completeness  — pipeline scripts exist and are executable
  2. documentation_coverage — key docs exist with meaningful content
  3. asset_pipeline_readiness — render script is functional, character dirs exist
  4. mod_packaging — packaging/validation tooling is wired up correctly

Output format:
    {"results": [{"name": str, "score": float, "weight": float, "passed": bool, "details": str}, ...]}
"""

import json
import os
import re
import stat
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


def _is_executable(path: Path) -> bool:
    if not path.exists():
        return False
    st = path.stat()
    return bool(st.st_mode & (stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH))


def _is_valid_python(path: Path) -> bool:
    if not path.exists():
        return False
    try:
        text = path.read_text()
    except OSError:
        return False
    if text.startswith("#!") and "python" in text.split("\n")[0]:
        return True
    try:
        compile(text, str(path), "exec")
        return True
    except SyntaxError:
        return False


def _file_has_content(path: Path, min_bytes: int = 100) -> bool:
    if not path.exists():
        return False
    try:
        return path.stat().st_size > min_bytes
    except OSError:
        return False


def _file_contains(path: Path, pattern: str) -> bool:
    if not path.exists():
        return False
    try:
        text = path.read_text(errors="replace")
    except OSError:
        return False
    return bool(re.search(pattern, text))


def eval_tooling_completeness() -> dict:
    scripts = {
        "render-character-sprites.py": ROOT / "tools" / "render-character-sprites.py",
        "pack-character-mod.sh": ROOT / "tools" / "pack-character-mod.sh",
        "validate-mod.sh": ROOT / "tools" / "validate-mod.sh",
        "sync-to-windows.sh": ROOT / "tools" / "sync-to-windows.sh",
        "check-feasibility.sh": ROOT / "tools" / "check-feasibility.sh",
    }

    passed_scripts = []
    failed_scripts = []

    for name, path in scripts.items():
        if name.endswith(".py"):
            ok = _is_valid_python(path)
        else:
            ok = _is_executable(path)

        if ok:
            passed_scripts.append(name)
        else:
            reason = "missing" if not path.exists() else "not executable/valid"
            failed_scripts.append(f"{name} ({reason})")

    total = len(scripts)
    score = len(passed_scripts) / total if total else 0.0

    details_parts = [f"{len(passed_scripts)}/{total} scripts OK"]
    if failed_scripts:
        details_parts.append("failed: " + ", ".join(failed_scripts))

    return {
        "name": "tooling_completeness",
        "score": round(score, 3),
        "weight": 0.25,
        "passed": score >= 0.8,
        "details": "; ".join(details_parts),
    }


def eval_documentation_coverage() -> dict:
    docs = {
        "docs/setup.md": ROOT / "docs" / "setup.md",
        "docs/controller-testing.md": ROOT / "docs" / "controller-testing.md",
        "docs/modding-notes.md": ROOT / "docs" / "modding-notes.md",
        "docs/legal-boundaries.md": ROOT / "docs" / "legal-boundaries.md",
        "ROADMAP.md": ROOT / "ROADMAP.md",
        "CLAUDE.md": ROOT / "CLAUDE.md",
    }

    present = []
    missing = []

    for name, path in docs.items():
        if _file_has_content(path, min_bytes=100):
            present.append(name)
        else:
            reason = "missing" if not path.exists() else "too small (<100 bytes)"
            missing.append(f"{name} ({reason})")

    total = len(docs)
    score = len(present) / total if total else 0.0

    details_parts = [f"{len(present)}/{total} docs with meaningful content"]
    if missing:
        details_parts.append("missing/insufficient: " + ", ".join(missing))

    return {
        "name": "documentation_coverage",
        "score": round(score, 3),
        "weight": 0.25,
        "passed": score >= 0.8,
        "details": "; ".join(details_parts),
    }


def eval_asset_pipeline_readiness() -> dict:
    render_script = ROOT / "tools" / "render-character-sprites.py"
    checks = {}

    checks["argparse_handling"] = (
        _file_contains(render_script, r"argparse|sys\.argv")
        and _file_contains(render_script, r"--character")
        and _file_contains(render_script, r"--blend-file")
    )

    checks["imports_bpy"] = _file_contains(render_script, r"\bimport\s+bpy\b|\bfrom\s+bpy\b")

    checks["camera_setup"] = _file_contains(
        render_script, r"camera|Camera|bpy\.data\.cameras|bpy\.ops\.object\.camera"
    )

    checks["render_logic"] = _file_contains(
        render_script, r"bpy\.ops\.render|render_settings|scene\.render|filepath|output"
    )

    animals = ["dalmatian", "yellow-lab", "black-cat", "orange-cat"]
    chars_dir = ROOT / "assets" / "characters"
    all_dirs_exist = all((chars_dir / a).is_dir() for a in animals)
    checks["character_dirs"] = all_dirs_exist

    passed_checks = [k for k, v in checks.items() if v]
    failed_checks = [k for k, v in checks.items() if not v]
    total = len(checks)
    score = len(passed_checks) / total if total else 0.0

    details_parts = [f"{len(passed_checks)}/{total} checks passed"]
    if failed_checks:
        details_parts.append("failed: " + ", ".join(failed_checks))

    return {
        "name": "asset_pipeline_readiness",
        "score": round(score, 3),
        "weight": 0.25,
        "passed": score >= 0.6,
        "details": "; ".join(details_parts),
    }


def eval_mod_packaging() -> dict:
    pack_script = ROOT / "tools" / "pack-character-mod.sh"
    validate_script = ROOT / "tools" / "validate-mod.sh"
    mods_toml = ROOT / "mods" / "animal-pack" / "mods.toml"

    checks = {}

    checks["pack_exists_executable"] = _is_executable(pack_script)
    checks["validate_exists_executable"] = _is_executable(validate_script)

    if mods_toml.exists():
        try:
            text = mods_toml.read_text()
            has_name = bool(re.search(r'name\s*=', text))
            has_version = bool(re.search(r'version\s*=', text))
            checks["mods_toml_valid"] = has_name and has_version
        except OSError:
            checks["mods_toml_valid"] = False
    else:
        checks["mods_toml_valid"] = False

    checks["pack_has_archive_logic"] = _file_contains(
        pack_script, r"zip|tar|archive|\.o2r|cp.*\.zip"
    )

    checks["validate_checks_patterns"] = _file_contains(
        validate_script, r"kart_frame|portrait|face_|mods\.toml|gTexture"
    )

    passed_checks = [k for k, v in checks.items() if v]
    failed_checks = [k for k, v in checks.items() if not v]
    total = len(checks)
    score = len(passed_checks) / total if total else 0.0

    details_parts = [f"{len(passed_checks)}/{total} checks passed"]
    if failed_checks:
        details_parts.append("failed: " + ", ".join(failed_checks))

    return {
        "name": "mod_packaging",
        "score": round(score, 3),
        "weight": 0.25,
        "passed": score >= 0.6,
        "details": "; ".join(details_parts),
    }


EVALS = [
    eval_tooling_completeness,
    eval_documentation_coverage,
    eval_asset_pipeline_readiness,
    eval_mod_packaging,
]


def main() -> None:
    results = [fn() for fn in EVALS]
    output = {"results": results}
    json.dump(output, sys.stdout, indent=2)
    print()


if __name__ == "__main__":
    main()
