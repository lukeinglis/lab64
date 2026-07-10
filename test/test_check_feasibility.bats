#!/usr/bin/env bats

load "libs/bats-support/load"
load "libs/bats-assert/load"

SCRIPT="$BATS_TEST_DIRNAME/../tools/check-feasibility.sh"

@test "check-feasibility: script exists and is executable" {
    assert [ -x "$SCRIPT" ]
}

@test "check-feasibility: prints header on launch" {
    # Feed all 'skip' answers so the interactive script terminates
    local input
    input=$(printf 's\n%.0s' $(seq 1 11))
    local fake_root
    fake_root=$(mktemp -d)
    mkdir -p "$fake_root/docs" "$fake_root/tools"
    cp "$SCRIPT" "$fake_root/tools/"

    run bash -c "echo '$input' | '$fake_root/tools/check-feasibility.sh'"
    assert_success
    assert_output --partial "Lab 64 Feasibility Test"

    rm -rf "$fake_root"
}

@test "check-feasibility: handles all-skip input without error" {
    local input
    input=$(printf 's\n%.0s' $(seq 1 11))
    local fake_root
    fake_root=$(mktemp -d)
    mkdir -p "$fake_root/docs" "$fake_root/tools"
    cp "$SCRIPT" "$fake_root/tools/"

    run bash -c "echo '$input' | '$fake_root/tools/check-feasibility.sh'"
    assert_success
    assert_output --partial "SKIP: 11"
    assert_output --partial "VERDICT: INCOMPLETE"

    rm -rf "$fake_root"
}

@test "check-feasibility: reports pass verdict when all pass" {
    local input
    input=$(printf 'p\n%.0s' $(seq 1 11))
    local fake_root
    fake_root=$(mktemp -d)
    mkdir -p "$fake_root/docs" "$fake_root/tools"
    cp "$SCRIPT" "$fake_root/tools/"

    run bash -c "echo '$input' | '$fake_root/tools/check-feasibility.sh'"
    assert_success
    assert_output --partial "PASS: 11"
    assert_output --partial "VERDICT: PASS"

    rm -rf "$fake_root"
}
