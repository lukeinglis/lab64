#!/usr/bin/env python3
"""Tests for eval/score.py — validates JSON structure and score invariants."""

import json
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
SCORE_SCRIPT = ROOT / "eval" / "score.py"

EXPECTED_DIMENSIONS = [
    "tooling_completeness",
    "documentation_coverage",
    "asset_pipeline_readiness",
    "mod_packaging",
]


@pytest.fixture(scope="module")
def eval_output():
    result = subprocess.run(
        [sys.executable, str(SCORE_SCRIPT)],
        capture_output=True,
        text=True,
        timeout=60,
        cwd=str(ROOT),
    )
    assert result.returncode == 0, f"score.py failed: {result.stderr}"
    return json.loads(result.stdout)


def test_valid_json_structure(eval_output):
    assert "results" in eval_output
    assert isinstance(eval_output["results"], list)
    assert len(eval_output["results"]) > 0


def test_all_dimensions_present(eval_output):
    names = [r["name"] for r in eval_output["results"]]
    for dim in EXPECTED_DIMENSIONS:
        assert dim in names, f"Missing dimension: {dim}"


def test_scores_in_range(eval_output):
    for r in eval_output["results"]:
        assert 0.0 <= r["score"] <= 1.0, f"{r['name']} score {r['score']} out of range"


def test_weights_sum_to_one(eval_output):
    total = sum(r["weight"] for r in eval_output["results"])
    assert abs(total - 1.0) < 0.01, f"Weights sum to {total}, expected ~1.0"


def test_result_fields(eval_output):
    required_fields = {"name", "score", "weight", "passed", "details"}
    for r in eval_output["results"]:
        missing = required_fields - set(r.keys())
        assert not missing, f"{r['name']} missing fields: {missing}"


def test_passed_is_boolean(eval_output):
    for r in eval_output["results"]:
        assert isinstance(r["passed"], bool), f"{r['name']} passed is not bool"


def test_details_is_descriptive(eval_output):
    for r in eval_output["results"]:
        assert isinstance(r["details"], str)
        assert len(r["details"]) > 10, f"{r['name']} details too short"
