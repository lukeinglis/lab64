#!/usr/bin/env bats

load "libs/bats-support/load"
load "libs/bats-assert/load"

SCRIPT="$BATS_TEST_DIRNAME/../tools/pack-character-mod.sh"

@test "pack-character-mod: shows usage with no arguments" {
    run "$SCRIPT"
    assert_failure
    assert_output --partial "Usage:"
}

@test "pack-character-mod: shows usage with one argument" {
    run "$SCRIPT" dalmatian
    assert_failure
    assert_output --partial "Usage:"
}

@test "pack-character-mod: fails on nonexistent sprite directory" {
    run "$SCRIPT" dalmatian /nonexistent/path
    assert_failure
    assert_output --partial "Sprite directory not found"
}

@test "pack-character-mod: fails when kart frames directory is missing" {
    local tmpdir
    tmpdir=$(mktemp -d)
    # Create a sprite dir with no kart subdirectory
    run "$SCRIPT" testchar "$tmpdir"
    assert_failure
    assert_output --partial "Kart frames directory not found"
    rm -rf "$tmpdir"
}

@test "pack-character-mod: succeeds with valid fixtures" {
    local fixtures="$BATS_TEST_DIRNAME/fixtures/sprites"
    local output_dir
    output_dir=$(mktemp -d)

    # pack-character-mod.sh writes to PROJECT_ROOT/mods/animal-pack/
    # We need to run it from a temp project root so it doesn't pollute the real tree
    local fake_root
    fake_root=$(mktemp -d)
    mkdir -p "$fake_root/tools" "$fake_root/mods/animal-pack"
    cp "$SCRIPT" "$fake_root/tools/"

    run "$fake_root/tools/pack-character-mod.sh" testchar "$fixtures"
    assert_success
    assert_output --partial "SUCCESS"
    assert [ -f "$fake_root/mods/animal-pack/testchar.o2r" ]

    rm -rf "$fake_root"
}

@test "pack-character-mod: generated o2r contains mods.toml" {
    local fixtures="$BATS_TEST_DIRNAME/fixtures/sprites"
    local fake_root
    fake_root=$(mktemp -d)
    mkdir -p "$fake_root/tools" "$fake_root/mods/animal-pack"
    cp "$SCRIPT" "$fake_root/tools/"

    run "$fake_root/tools/pack-character-mod.sh" testchar "$fixtures"
    assert_success

    # Verify the archive contains mods.toml
    run unzip -l "$fake_root/mods/animal-pack/testchar.o2r"
    assert_output --partial "mods.toml"

    rm -rf "$fake_root"
}
