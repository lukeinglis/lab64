#!/usr/bin/env bats

load "libs/bats-support/load"
load "libs/bats-assert/load"

SCRIPT="$BATS_TEST_DIRNAME/../tools/validate-mod.sh"
FIXTURES="$BATS_TEST_DIRNAME/fixtures"

setup_file() {
    # Build .o2r test fixtures from checked-in source data.
    # .o2r files are gitignored, so we create them at test time.
    (cd "$FIXTURES/valid-mod" && zip -r "$FIXTURES/valid.o2r" . -x ".*") >/dev/null 2>&1

    echo "this is not a zip file" > "$FIXTURES/invalid.o2r"

    local romdir
    romdir=$(mktemp -d)
    cp "$FIXTURES/valid-mod/mods.toml" "$romdir/"
    touch "$romdir/game.z64"
    (cd "$romdir" && zip -r "$FIXTURES/rom-inside.o2r" . -x ".*") >/dev/null 2>&1
    rm -rf "$romdir"
}

teardown_file() {
    rm -f "$FIXTURES/valid.o2r" "$FIXTURES/invalid.o2r" "$FIXTURES/rom-inside.o2r"
}

@test "validate-mod: shows usage with no arguments" {
    run "$SCRIPT"
    assert_failure
    assert_output --partial "Usage:"
}

@test "validate-mod: fails on nonexistent file" {
    run "$SCRIPT" /nonexistent/file.o2r
    assert_failure
    assert_output --partial "File not found"
}

@test "validate-mod: fails on invalid zip file" {
    run "$SCRIPT" "$FIXTURES/invalid.o2r"
    assert_failure
    assert_output --partial "Not a valid zip"
}

@test "validate-mod: passes on valid o2r with mods.toml" {
    run "$SCRIPT" "$FIXTURES/valid.o2r"
    assert_success
    assert_output --partial "mods.toml found"
    assert_output --partial "VALIDATION PASSED"
}

@test "validate-mod: detects ROM files inside archive" {
    run "$SCRIPT" "$FIXTURES/rom-inside.o2r"
    assert_failure
    assert_output --partial "ROM file found"
}

@test "validate-mod: checks mods.toml required fields" {
    run "$SCRIPT" "$FIXTURES/valid.o2r"
    assert_success
    assert_output --partial "[mod] section present"
    assert_output --partial "name ="
    assert_output --partial "version ="
}

@test "validate-mod: reports file count and size" {
    run "$SCRIPT" "$FIXTURES/valid.o2r"
    assert_success
    assert_output --partial "Files:"
    assert_output --partial "Archive size:"
}
