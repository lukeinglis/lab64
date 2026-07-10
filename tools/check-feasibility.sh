#!/usr/bin/env bash
set -euo pipefail

# Interactive feasibility checklist for Lab 64 Gate 1.
#
# Walks through each item from spec.md section 9 and records pass/fail
# with timestamps. Outputs results to docs/feasibility-results.md.
#
# Usage:
#   tools/check-feasibility.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_FILE="$PROJECT_ROOT/docs/feasibility-results.md"

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
RESULTS=()

echo "============================================"
echo "  Lab 64 Feasibility Test - Gate 1"
echo "============================================"
echo ""
echo "This checklist validates that SpaghettiKart can support"
echo "the Lab 64 private team setup."
echo ""
echo "For each item, enter:"
echo "  p = PASS"
echo "  f = FAIL"
echo "  s = SKIP (not testable right now)"
echo ""
echo "Results will be saved to: docs/feasibility-results.md"
echo ""
echo "--------------------------------------------"
echo ""

check_item() {
    local item_num="$1"
    local description="$2"
    local troubleshoot="$3"

    echo "[$item_num] $description"
    echo ""

    while true; do
        printf "  Result (p/f/s): "
        read -r result
        case "$result" in
            p|P)
                RESULTS+=("| $item_num | $description | PASS | $(date '+%Y-%m-%d %H:%M') |")
                PASS_COUNT=$((PASS_COUNT + 1))
                echo "  -> PASS"
                echo ""
                return 0
                ;;
            f|F)
                RESULTS+=("| $item_num | $description | FAIL | $(date '+%Y-%m-%d %H:%M') |")
                FAIL_COUNT=$((FAIL_COUNT + 1))
                echo "  -> FAIL"
                echo ""
                echo "  Troubleshooting: $troubleshoot"
                echo ""
                return 1
                ;;
            s|S)
                RESULTS+=("| $item_num | $description | SKIP | $(date '+%Y-%m-%d %H:%M') |")
                SKIP_COUNT=$((SKIP_COUNT + 1))
                echo "  -> SKIP"
                echo ""
                return 0
                ;;
            *)
                echo "  Please enter p, f, or s"
                ;;
        esac
    done
}

# Run through each feasibility item
check_item 1 \
    "SpaghettiKart launches on Windows machine" \
    "Check ROM format (.z64 required), SHA-1 hash, antivirus blocking. See docs/setup.md" \
    || true

check_item 2 \
    "Owner's ROM works with the setup" \
    "Verify SHA-1: 579C48E211AE952530FFC8738709F078D5DD215E. Convert from .n64 if needed. See docs/setup.md" \
    || true

check_item 3 \
    "Game runs smoothly (no major frame drops)" \
    "Try Turbo mode on ROG Ally. Close other apps. Check SpaghettiKart graphics settings." \
    || true

check_item 4 \
    "One 8BitDo controller works" \
    "Check dongle connection, try different USB-A port. See docs/controller-testing.md" \
    || true

check_item 5 \
    "Two 8BitDo controllers work simultaneously" \
    "Use separate dongles in separate USB-A ports. Check for input crosstalk. See docs/controller-testing.md" \
    || true

check_item 6 \
    "Four-player local multiplayer works (or appears achievable)" \
    "Requires 4 dongles + 4 USB-A ports on dock. Test with 2-player first. See docs/controller-testing.md" \
    || true

check_item 7 \
    "ROG Ally can output to shared display via USB-C dock" \
    "Try different HDMI cable or dock. Check Windows display settings. See docs/setup.md" \
    || true

check_item 8 \
    "Controller mapping is stable for repeated use" \
    "Disconnect and reconnect dongles in consistent order. Use 8BitDo Ultimate Software for profiles." \
    || true

check_item 9 \
    "A simple existing mod loads successfully" \
    "Download a texture pack from GameBanana. Place .o2r in mods/ folder. See docs/modding-notes.md" \
    || true

check_item 10 \
    "A small visual replacement can be tested" \
    "Try replacing a single texture. Use tools/validate-mod.sh to check. See docs/modding-notes.md" \
    || true

check_item 11 \
    "Asset pipeline scripts run without errors" \
    "Run tools/validate-mod.sh on a test archive. Check bash and python are installed." \
    || true

# Generate results file
echo ""
echo "============================================"
echo "  Results Summary"
echo "============================================"
echo ""
echo "  PASS: $PASS_COUNT"
echo "  FAIL: $FAIL_COUNT"
echo "  SKIP: $SKIP_COUNT"
echo "  Total: $((PASS_COUNT + FAIL_COUNT + SKIP_COUNT))"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "  VERDICT: BLOCKED - Fix failed items before proceeding to Gate 2"
elif [ "$SKIP_COUNT" -gt 0 ]; then
    echo "  VERDICT: INCOMPLETE - Return to test skipped items"
else
    echo "  VERDICT: PASS - Proceed to Gate 2 (Animal Pack MVP)"
fi

# Write results to file
cat > "$RESULTS_FILE" << HEADER
# Feasibility Test Results

**Date:** $(date '+%Y-%m-%d')
**Verdict:** $([ "$FAIL_COUNT" -gt 0 ] && echo "BLOCKED" || ([ "$SKIP_COUNT" -gt 0 ] && echo "INCOMPLETE" || echo "PASS"))

## Summary

| Metric | Count |
|---|---|
| Pass | $PASS_COUNT |
| Fail | $FAIL_COUNT |
| Skip | $SKIP_COUNT |
| Total | $((PASS_COUNT + FAIL_COUNT + SKIP_COUNT)) |

## Detailed Results

| # | Item | Result | Timestamp |
|---|---|---|---|
HEADER

for r in "${RESULTS[@]}"; do
    echo "$r" >> "$RESULTS_FILE"
done

cat >> "$RESULTS_FILE" << FOOTER

## Next Steps

$([ "$FAIL_COUNT" -gt 0 ] && echo "Fix the failed items above. Consult the troubleshooting sections in docs/setup.md and docs/controller-testing.md." || echo "Feasibility validated. Proceed to Gate 2: Animal Pack MVP. See ROADMAP.md for the full checklist.")

---

*Generated by tools/check-feasibility.sh*
FOOTER

echo ""
echo "Results saved to: $RESULTS_FILE"
