#!/usr/bin/env bash
set -euo pipefail

# Validate a SpaghettiKart .o2r mod archive.
#
# Usage:
#   tools/validate-mod.sh <mod-file.o2r>
#
# Checks:
#   - mods.toml exists and has required fields
#   - All image files are valid PNG/JPG/BMP
#   - Texture dimensions are power-of-2
#   - No ROM files or extracted assets accidentally included
#   - Reports file count, total size, and warnings

usage() {
    echo "Usage: $0 <mod-file.o2r>"
    echo ""
    echo "Validate a SpaghettiKart .o2r mod archive."
    echo ""
    echo "Example:"
    echo "  $0 mods/animal-pack/dalmatian.o2r"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

MOD_FILE="$1"
WARNINGS=0
ERRORS=0

echo "Validating mod: $MOD_FILE"
echo "================================"

# Check file exists
if [ ! -f "$MOD_FILE" ]; then
    echo "ERROR: File not found: $MOD_FILE"
    exit 1
fi

# Check file extension
if [[ "$MOD_FILE" != *.o2r ]]; then
    echo "WARNING: File does not have .o2r extension"
    WARNINGS=$((WARNINGS + 1))
fi

# Check it's a valid zip
if ! unzip -t "$MOD_FILE" &>/dev/null; then
    echo "ERROR: Not a valid zip/o2r archive"
    exit 1
fi

# Extract to temp directory for inspection
STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT
unzip -q "$MOD_FILE" -d "$STAGING"

echo ""
echo "Archive contents:"

# Check mods.toml
if [ -f "$STAGING/mods.toml" ]; then
    echo "  [OK] mods.toml found"

    # Check required fields
    if grep -q '^\[mod\]' "$STAGING/mods.toml" 2>/dev/null; then
        echo "  [OK] [mod] section present"
    else
        echo "  [ERROR] Missing [mod] section in mods.toml"
        ERRORS=$((ERRORS + 1))
    fi

    if grep -q '^name' "$STAGING/mods.toml" 2>/dev/null; then
        NAME=$(grep '^name' "$STAGING/mods.toml" | head -1 | sed 's/name *= *"\(.*\)"/\1/')
        echo "  [OK] name = $NAME"
    else
        echo "  [ERROR] Missing 'name' field in mods.toml"
        ERRORS=$((ERRORS + 1))
    fi

    if grep -q '^version' "$STAGING/mods.toml" 2>/dev/null; then
        VERSION=$(grep '^version' "$STAGING/mods.toml" | head -1 | sed 's/version *= *"\(.*\)"/\1/')
        echo "  [OK] version = $VERSION"
    else
        echo "  [ERROR] Missing 'version' field in mods.toml"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "  [ERROR] mods.toml not found (required by SpaghettiKart)"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "Image validation:"

# Find all image files
IMAGE_COUNT=0
while IFS= read -r -d '' img; do
    IMAGE_COUNT=$((IMAGE_COUNT + 1))
    ext="${img##*.}"
    ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    # Check format
    if [[ "$ext_lower" != "png" && "$ext_lower" != "jpg" && "$ext_lower" != "jpeg" && "$ext_lower" != "bmp" ]]; then
        echo "  [WARNING] Unsupported image format: $img"
        WARNINGS=$((WARNINGS + 1))
        continue
    fi

    # Check dimensions are power-of-2 (width only, nameplate height 12 is an exception)
    if command -v sips &>/dev/null; then
        w=$(sips -g pixelWidth "$img" 2>/dev/null | tail -1 | awk '{print $2}')
        h=$(sips -g pixelHeight "$img" 2>/dev/null | tail -1 | awk '{print $2}')

        if [ -n "$w" ] && [ -n "$h" ]; then
            is_power_of_2() {
                local n="$1"
                [ "$n" -gt 0 ] && [ $((n & (n - 1))) -eq 0 ]
            }

            if ! is_power_of_2 "$w"; then
                echo "  [WARNING] Width $w not power-of-2: $(basename "$img")"
                WARNINGS=$((WARNINGS + 1))
            fi

            # Height 12 is valid for nameplates
            if [ "$h" -ne 12 ] && ! is_power_of_2 "$h"; then
                echo "  [WARNING] Height $h not power-of-2: $(basename "$img")"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    elif command -v identify &>/dev/null; then
        dims=$(identify -format "%wx%h" "$img" 2>/dev/null || true)
        if [ -n "$dims" ]; then
            w="${dims%x*}"
            h="${dims#*x}"

            is_power_of_2() {
                local n="$1"
                [ "$n" -gt 0 ] && [ $((n & (n - 1))) -eq 0 ]
            }

            if ! is_power_of_2 "$w"; then
                echo "  [WARNING] Width $w not power-of-2: $(basename "$img")"
                WARNINGS=$((WARNINGS + 1))
            fi

            if [ "$h" -ne 12 ] && ! is_power_of_2 "$h"; then
                echo "  [WARNING] Height $h not power-of-2: $(basename "$img")"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    else
        echo "  [INFO] No image inspection tool available (sips or ImageMagick). Skipping dimension checks."
        break
    fi
done < <(find "$STAGING" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.bmp" \) -print0)

echo "  Found $IMAGE_COUNT image file(s)"

# Check for accidentally included ROM files
echo ""
echo "Safety checks:"

ROM_COUNT=0
while IFS= read -r -d '' rom; do
    echo "  [ERROR] ROM file found in archive: $(basename "$rom")"
    ROM_COUNT=$((ROM_COUNT + 1))
    ERRORS=$((ERRORS + 1))
done < <(find "$STAGING" -type f \( -iname "*.z64" -o -iname "*.n64" -o -iname "*.rom" -o -iname "*.v64" \) -print0)

if [ "$ROM_COUNT" -eq 0 ]; then
    echo "  [OK] No ROM files found"
fi

# Check for extracted asset directories
if [ -d "$STAGING/extracted-assets" ]; then
    echo "  [ERROR] extracted-assets/ directory found in archive"
    ERRORS=$((ERRORS + 1))
else
    echo "  [OK] No extracted asset directories"
fi

# File count and size report
echo ""
echo "Summary:"
FILE_COUNT=$(find "$STAGING" -type f | wc -l | tr -d ' ')
TOTAL_SIZE=$(du -sh "$MOD_FILE" | awk '{print $1}')
echo "  Files: $FILE_COUNT"
echo "  Archive size: $TOTAL_SIZE"
echo "  Warnings: $WARNINGS"
echo "  Errors: $ERRORS"

if [ "$ERRORS" -gt 0 ]; then
    echo ""
    echo "VALIDATION FAILED: $ERRORS error(s) found."
    exit 1
fi

if [ "$WARNINGS" -gt 0 ]; then
    echo ""
    echo "VALIDATION PASSED with $WARNINGS warning(s)."
    exit 0
fi

echo ""
echo "VALIDATION PASSED."
exit 0
