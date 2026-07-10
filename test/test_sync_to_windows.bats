#!/usr/bin/env bats

load "libs/bats-support/load"
load "libs/bats-assert/load"

SCRIPT="$BATS_TEST_DIRNAME/../tools/sync-to-windows.sh"

@test "sync-to-windows: shows usage with --help" {
    run "$SCRIPT" --help
    assert_failure
    assert_output --partial "Usage:"
}

@test "sync-to-windows: shows usage with -h" {
    run "$SCRIPT" -h
    assert_failure
    assert_output --partial "Usage:"
}

@test "sync-to-windows: prints manual instructions when no target configured" {
    # Ensure env var is unset and give it a file that exists
    local tmpfile
    tmpfile=$(mktemp /tmp/test-mod-XXXXXX.o2r)

    run env -u LAB64_WINDOWS_MODS_PATH "$SCRIPT" "$tmpfile"
    assert_success
    assert_output --partial "No target configured"
    assert_output --partial "Option 1: Set LAB64_WINDOWS_MODS_PATH"

    rm -f "$tmpfile"
}

@test "sync-to-windows: fails when --target has no path" {
    run "$SCRIPT" --target
    assert_failure
    assert_output --partial "--target requires a path"
}

@test "sync-to-windows: fails when target directory does not exist" {
    local tmpfile
    tmpfile=$(mktemp /tmp/test-mod-XXXXXX.o2r)

    run env -u LAB64_WINDOWS_MODS_PATH "$SCRIPT" --target /nonexistent/path "$tmpfile"
    assert_failure
    assert_output --partial "Target directory does not exist"

    rm -f "$tmpfile"
}

@test "sync-to-windows: copies file to local target directory" {
    local tmpfile
    tmpfile=$(mktemp /tmp/test-mod-XXXXXX.o2r)
    echo "test" > "$tmpfile"
    local target_dir
    target_dir=$(mktemp -d)

    run env -u LAB64_WINDOWS_MODS_PATH "$SCRIPT" --target "$target_dir" "$tmpfile"
    assert_success
    assert_output --partial "Copying"
    assert [ -f "$target_dir/$(basename "$tmpfile")" ]

    rm -f "$tmpfile"
    rm -rf "$target_dir"
}
