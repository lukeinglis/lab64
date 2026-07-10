#!/usr/bin/env bats

load "libs/bats-support/load"
load "libs/bats-assert/load"

LAB64="$BATS_TEST_DIRNAME/../tools/lab64"

@test "lab64: script exists and is executable" {
    assert [ -x "$LAB64" ]
}

@test "lab64: --help shows all subcommands" {
    run "$LAB64" --help
    assert_output --partial "render"
    assert_output --partial "pack"
    assert_output --partial "validate"
    assert_output --partial "sync"
    assert_output --partial "check"
    assert_output --partial "version"
    assert_output --partial "doctor"
}

@test "lab64: --help exits with code 2" {
    run "$LAB64" --help
    assert [ "$status" -eq 2 ]
}

@test "lab64: --version outputs version string" {
    run "$LAB64" --version
    assert_success
    assert_output --partial "lab64"
    [ -n "$output" ]
}

@test "lab64: version subcommand shows component versions" {
    run "$LAB64" version
    assert_success
    assert_output --partial "lab64"
    assert_output --partial "python3"
}

@test "lab64: doctor reports dependency status" {
    run "$LAB64" doctor
    assert_output --partial "python3:"
    assert_output --partial "zip:"
    assert_output --partial "unzip:"
    assert_output --partial "Pass:"
}

@test "lab64: no arguments shows usage error and exits 2" {
    run "$LAB64"
    assert [ "$status" -eq 2 ]
    assert_output --partial "Usage"
}

@test "lab64: unknown subcommand shows usage error and exits 2" {
    run "$LAB64" frobnicate
    assert [ "$status" -eq 2 ]
    assert_output --partial "Unknown command"
}

@test "lab64: unknown option shows usage error and exits 2" {
    run "$LAB64" --bogus
    assert [ "$status" -eq 2 ]
    assert_output --partial "Unknown option"
}

@test "lab64: render dispatches to render-character-sprites.py" {
    run "$LAB64" render --help
    assert_output --partial "character"
}

@test "lab64: pack dispatches to pack-character-mod.sh" {
    run "$LAB64" pack --help
    assert_output --partial "sprite"
}

@test "lab64: validate dispatches to validate-mod.sh" {
    run "$LAB64" validate --help
    assert_output --partial "Validate"
}

@test "lab64: sync dispatches to sync-to-windows.sh" {
    run "$LAB64" sync --help
    assert_output --partial "Transfer"
}

@test "lab64: check dispatches to check-feasibility.sh" {
    run "$LAB64" check --help
    assert_output --partial "feasibility"
}
