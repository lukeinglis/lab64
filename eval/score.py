#!/usr/bin/env python3
"""Eval script for Lab 64 modding toolchain.

Measures four dimensions with quality checks (not just existence):
  1. tooling_completeness  — scripts respond to --help, --version, handle errors
  2. documentation_coverage — docs have required sections, headings, content length
  3. asset_pipeline_readiness — render script has --dry-run, --json, character support
  4. mod_packaging — pack/validate scripts validate inputs, mods.toml has required fields

Output format:
    {"results": [{"name": str, "score": float, "weight": float, "passed": bool, "details": str}, ...]}
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from collections.abc import Callable
from typing import TypedDict


class EvalResult(TypedDict):
    name: str
    score: float
    weight: float
    passed: bool
    details: str


class _DocRequirements(TypedDict):
    sections: list[str]
    min_headings: int
    min_chars: int


ROOT = Path(__file__).resolve().parent.parent
SUBPROCESS_TIMEOUT = 5


def _run(
    cmd: list[str], timeout: int = SUBPROCESS_TIMEOUT
) -> subprocess.CompletedProcess[str] | None:
    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=timeout, cwd=str(ROOT)
        )
        return result
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        return None


def _score_from_checks(
    checks: dict[str, bool],
) -> tuple[float, list[str], list[str]]:
    total = len(checks)
    if total == 0:
        return 0.0, [], []
    passed = [k for k, v in checks.items() if v]
    failed = [k for k, v in checks.items() if not v]
    return len(passed) / total, passed, failed


def _build_result(
    name: str,
    checks: dict[str, bool],
    weight: float,
    pass_threshold: float = 0.6,
) -> EvalResult:
    score, passed, failed = _score_from_checks(checks)
    details_parts = [f"{len(passed)}/{len(checks)} quality checks passed"]
    if failed:
        details_parts.append("failed: " + ", ".join(failed))
    return {
        "name": name,
        "score": round(score, 3),
        "weight": weight,
        "passed": score >= pass_threshold,
        "details": "; ".join(details_parts),
    }


def eval_tooling_completeness() -> EvalResult:
    bash_scripts = [
        "tools/check-feasibility.sh",
        "tools/pack-character-mod.sh",
        "tools/validate-mod.sh",
        "tools/sync-to-windows.sh",
    ]
    py_scripts = [
        "tools/render-character-sprites.py",
    ]
    all_scripts = bash_scripts + py_scripts

    checks = {}

    for script in all_scripts:
        path = ROOT / script
        if not path.exists():
            base = Path(script).name
            checks[f"{base}_help"] = False
            checks[f"{base}_version"] = False
            checks[f"{base}_error_handling"] = False
            checks[f"{base}_bad_args"] = False
            continue

        base = Path(script).name

        if script.endswith(".py"):
            cmd_help = [sys.executable, str(path), "--help"]
            cmd_version = [sys.executable, str(path), "--version"]
            cmd_bad = [sys.executable, str(path), "--nonexistent-flag"]
        else:
            cmd_help = ["bash", str(path), "--help"]
            cmd_version = ["bash", str(path), "--version"]
            cmd_bad = ["bash", str(path), "--nonexistent-flag"]

        r = _run(cmd_help)
        help_output = (r.stdout + r.stderr) if r else ""
        checks[f"{base}_help"] = r is not None and len(help_output.strip()) > 10

        r = _run(cmd_version)
        version_output = (r.stdout + r.stderr) if r else ""
        checks[f"{base}_version"] = r is not None and bool(
            re.search(r"v?\d+\.\d+", version_output)
        )

        if script.endswith(".sh"):
            try:
                text = path.read_text()
                checks[f"{base}_error_handling"] = "set -e" in text
            except OSError:
                checks[f"{base}_error_handling"] = False
        else:
            checks[f"{base}_error_handling"] = True

        r = _run(cmd_bad)
        checks[f"{base}_bad_args"] = r is not None and r.returncode != 0

    return _build_result("tooling_completeness", checks, 0.25, pass_threshold=0.6)


def eval_documentation_coverage() -> EvalResult:
    docs_checks: dict[str, _DocRequirements] = {
        "docs/setup.md": {
            "sections": ["Prerequisites"],
            "min_headings": 3,
            "min_chars": 200,
        },
        "docs/modding-notes.md": {
            "sections": ["File Naming"],
            "min_headings": 3,
            "min_chars": 200,
        },
        "docs/controller-testing.md": {
            "sections": [],
            "min_headings": 3,
            "min_chars": 200,
        },
        "docs/legal-boundaries.md": {
            "sections": [],
            "min_headings": 3,
            "min_chars": 200,
        },
        "ROADMAP.md": {
            "sections": [],
            "min_headings": 3,
            "min_chars": 200,
        },
        "CLAUDE.md": {
            "sections": [],
            "min_headings": 3,
            "min_chars": 200,
        },
    }

    checks = {}
    for doc_path, requirements in docs_checks.items():
        path = ROOT / doc_path
        base = Path(doc_path).name

        if not path.exists():
            checks[f"{base}_sections"] = False
            checks[f"{base}_headings"] = False
            checks[f"{base}_length"] = False
            continue

        try:
            text = path.read_text(errors="replace")
        except OSError:
            checks[f"{base}_sections"] = False
            checks[f"{base}_headings"] = False
            checks[f"{base}_length"] = False
            continue

        if requirements["sections"]:
            all_found = all(
                re.search(re.escape(s), text, re.IGNORECASE)
                for s in requirements["sections"]
            )
            checks[f"{base}_sections"] = all_found
        else:
            checks[f"{base}_sections"] = True

        heading_count = len(re.findall(r"^#{1,6}\s", text, re.MULTILINE))
        checks[f"{base}_headings"] = heading_count >= requirements["min_headings"]

        checks[f"{base}_length"] = len(text) >= requirements["min_chars"]

    return _build_result("documentation_coverage", checks, 0.25, pass_threshold=0.7)


def eval_asset_pipeline_readiness() -> EvalResult:
    render_script = ROOT / "tools" / "render-character-sprites.py"
    checks = {}

    if not render_script.exists():
        checks["dry_run_flag"] = False
        checks["json_flag"] = False
        checks["character_dir_readmes"] = False
        checks["accepts_dalmatian"] = False
        checks["accepts_yellow_lab"] = False
        checks["accepts_black_cat"] = False
        checks["accepts_orange_cat"] = False
        return _build_result("asset_pipeline_readiness", checks, 0.25, pass_threshold=0.6)

    r = _run([sys.executable, str(render_script), "--help"])
    help_text = (r.stdout + r.stderr) if r else ""

    checks["dry_run_flag"] = "--dry-run" in help_text
    checks["json_flag"] = "--json" in help_text

    animals = ["dalmatian", "yellow-lab", "black-cat", "orange-cat"]
    chars_dir = ROOT / "assets" / "characters"
    all_readmes = all((chars_dir / a / "README.md").is_file() for a in animals)
    checks["character_dir_readmes"] = all_readmes

    for animal in animals:
        r = _run([
            sys.executable, str(render_script),
            "--character", animal,
            "--blend-file", "nonexistent.blend",
            "--dry-run",
        ])
        key = f"accepts_{animal.replace('-', '_')}"
        if r is None:
            checks[key] = False
        else:
            output = r.stdout + r.stderr
            checks[key] = "unknown character" not in output.lower() and "invalid character" not in output.lower()

    return _build_result("asset_pipeline_readiness", checks, 0.25, pass_threshold=0.6)


def eval_mod_packaging() -> EvalResult:
    pack_script = ROOT / "tools" / "pack-character-mod.sh"
    validate_script = ROOT / "tools" / "validate-mod.sh"
    mods_toml = ROOT / "mods" / "animal-pack" / "mods.toml"

    checks = {}

    if pack_script.exists():
        r = _run(["bash", str(pack_script)])
        checks["pack_validates_args"] = r is not None and r.returncode != 0
    else:
        checks["pack_validates_args"] = False

    if validate_script.exists():
        with tempfile.NamedTemporaryFile(suffix=".o2r", delete=False) as tmp:
            tmp.write(b"this is not a zip file")
            tmp_path = tmp.name
        try:
            r = _run(["bash", str(validate_script), tmp_path])
            checks["validate_catches_bad_input"] = r is not None and r.returncode != 0
        finally:
            os.unlink(tmp_path)
    else:
        checks["validate_catches_bad_input"] = False

    required_toml_fields = ["name", "version", "description", "author"]
    if mods_toml.exists():
        try:
            text = mods_toml.read_text()
            found = sum(1 for f in required_toml_fields if re.search(rf"{f}\s*=", text, re.IGNORECASE))
            checks["mods_toml_fields"] = found >= len(required_toml_fields)
        except OSError:
            checks["mods_toml_fields"] = False
    else:
        checks["mods_toml_fields"] = False

    return _build_result("mod_packaging", checks, 0.25, pass_threshold=0.6)


EVALS: list[Callable[[], EvalResult]] = [
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
