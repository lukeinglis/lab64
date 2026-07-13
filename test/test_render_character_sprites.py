"""Tests for tools/render-character-sprites.py argument parsing.

These tests exercise the argparse logic without requiring Blender.
The script splits sys.argv on '--' to extract its own arguments,
so we mock sys.argv to simulate Blender's invocation pattern.
"""

from __future__ import annotations

import importlib.util
import json
import os
import sys
from types import ModuleType
from unittest.mock import patch

import pytest

SCRIPT_PATH = os.path.join(
    os.path.dirname(__file__), "..", "tools", "render-character-sprites.py"
)


def load_render_module() -> ModuleType:
    spec = importlib.util.spec_from_file_location("render_sprites", SCRIPT_PATH)
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


render = load_render_module()


class TestParseArgs:
    def test_missing_character_flag(self):
        with patch.object(
            sys, "argv", ["blender", "--background", "--python", "script.py", "--"]
        ):
            with pytest.raises(SystemExit) as exc_info:
                render.parse_args()
            assert exc_info.value.code != 0

    def test_missing_blend_file_flag(self):
        with patch.object(
            sys,
            "argv",
            [
                "blender",
                "--background",
                "--python",
                "script.py",
                "--",
                "--character",
                "dalmatian",
            ],
        ):
            with pytest.raises(SystemExit) as exc_info:
                render.parse_args()
            assert exc_info.value.code != 0

    def test_valid_minimal_args(self):
        with patch.object(
            sys,
            "argv",
            [
                "blender",
                "--background",
                "--python",
                "script.py",
                "--",
                "--character",
                "dalmatian",
                "--blend-file",
                "/path/to/model.blend",
            ],
        ):
            args = render.parse_args()
            assert args.character == "dalmatian"
            assert args.blend_file == "/path/to/model.blend"
            assert args.rotations == 16
            assert args.resolution == 64
            assert args.output_dir is None

    def test_custom_rotations_and_resolution(self):
        with patch.object(
            sys,
            "argv",
            [
                "blender",
                "--",
                "--character",
                "black_cat",
                "--blend-file",
                "cat.blend",
                "--rotations",
                "32",
                "--resolution",
                "128",
            ],
        ):
            args = render.parse_args()
            assert args.rotations == 32
            assert args.resolution == 128

    def test_custom_output_dir(self):
        with patch.object(
            sys,
            "argv",
            [
                "blender",
                "--",
                "--character",
                "yellow_lab",
                "--blend-file",
                "lab.blend",
                "--output-dir",
                "/tmp/sprites",
            ],
        ):
            args = render.parse_args()
            assert args.output_dir == "/tmp/sprites"

    def test_no_double_dash_yields_empty_args(self):
        with patch.object(sys, "argv", ["blender", "--background"]):
            with pytest.raises(SystemExit):
                render.parse_args()

    def test_all_four_characters_accepted(self):
        for char in ["dalmatian", "yellow_lab", "black_cat", "orange_cat"]:
            with patch.object(
                sys,
                "argv",
                [
                    "blender",
                    "--",
                    "--character",
                    char,
                    "--blend-file",
                    f"{char}.blend",
                ],
            ):
                args = render.parse_args()
                assert args.character == char


class TestValidateConfig:
    def test_validate_config_flag(self) -> None:
        with patch.object(
            sys,
            "argv",
            ["blender", "--", "--validate-config"],
        ):
            with pytest.raises(SystemExit) as exc_info:
                render.parse_args()
            assert exc_info.value.code == 0

    def test_validate_config_json(self, capsys: pytest.CaptureFixture[str]) -> None:
        with patch.object(
            sys,
            "argv",
            ["blender", "--", "--validate-config", "--json"],
        ):
            with pytest.raises(SystemExit) as exc_info:
                render.parse_args()
            assert exc_info.value.code == 0
            captured = capsys.readouterr()
            result = json.loads(captured.out)
            assert result["status"] == "pass"
            assert "checks" in result["details"]
            assert len(result["details"]["checks"]) == 5

    def test_validate_config_bad_resolution(self) -> None:
        with patch.object(
            sys,
            "argv",
            ["blender", "--", "--validate-config", "--resolution", "50"],
        ):
            with pytest.raises(SystemExit) as exc_info:
                render.parse_args()
            assert exc_info.value.code == 1

    def test_validate_config_bad_rotations(self) -> None:
        with patch.object(
            sys,
            "argv",
            ["blender", "--", "--validate-config", "--rotations", "8"],
        ):
            with pytest.raises(SystemExit) as exc_info:
                render.parse_args()
            assert exc_info.value.code == 1


class TestListSlots:
    def test_list_slots_flag(self, capsys: pytest.CaptureFixture[str]) -> None:
        with patch.object(
            sys,
            "argv",
            ["blender", "--", "--list-slots"],
        ):
            with pytest.raises(SystemExit) as exc_info:
                render.parse_args()
            assert exc_info.value.code == 0
            captured = capsys.readouterr()
            assert "dalmatian" in captured.out
            assert "donkey_kong" in captured.out

    def test_list_slots_json(self, capsys: pytest.CaptureFixture[str]) -> None:
        with patch.object(
            sys,
            "argv",
            ["blender", "--", "--list-slots", "--json"],
        ):
            with pytest.raises(SystemExit) as exc_info:
                render.parse_args()
            assert exc_info.value.code == 0
            captured = capsys.readouterr()
            result = json.loads(captured.out)
            assert result["status"] == "success"
            assert "assignments" in result["details"]


class TestMainRequiresBlender:
    def test_main_exits_without_bpy(self):
        with patch.object(
            sys,
            "argv",
            [
                "blender",
                "--",
                "--character",
                "dalmatian",
                "--blend-file",
                "test.blend",
            ],
        ):
            with pytest.raises(SystemExit) as exc_info:
                render.main()
            assert exc_info.value.code == 1
