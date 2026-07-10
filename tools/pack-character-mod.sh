#!/usr/bin/env bash
set -euo pipefail

# Pack a character's sprites into a SpaghettiKart .o2r mod archive.
#
# Usage:
#   tools/pack-character-mod.sh <character-name> <sprite-directory>
#
# Example:
#   tools/pack-character-mod.sh dalmatian assets/characters/dalmatian/sprites
#
# Output:
#   mods/animal-pack/<character-name>.o2r

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
    echo "Usage: $0 <character-name> <sprite-directory>"
    echo ""
    echo "Pack character sprites into a SpaghettiKart .o2r mod archive."
    echo ""
    echo "Arguments:"
    echo "  character-name    Name of the character (e.g. dalmatian, yellow_lab)"
    echo "  sprite-directory  Directory containing rendered sprites"
    echo ""
    echo "Example:"
    echo "  $0 dalmatian assets/characters/dalmatian/sprites"
    exit 1
}

if [ $# -lt 2 ]; then
    usage
fi

CHARACTER="$1"
SPRITE_DIR="$2"
OUTPUT_DIR="$PROJECT_ROOT/mods/animal-pack"
CAPITALIZED=$(echo "$CHARACTER" | sed 's/_//g' | sed 's/\b\(.\)/\u\1/g' | sed 's/ //g')

echo "Packing character mod: $CHARACTER"
echo "  Sprite directory: $SPRITE_DIR"
echo "  Output: $OUTPUT_DIR/$CHARACTER.o2r"

# Validate sprite directory exists
if [ ! -d "$SPRITE_DIR" ]; then
    echo "ERROR: Sprite directory not found: $SPRITE_DIR"
    exit 1
fi

# Validate required files
ERRORS=0

# Check kart frames
KART_DIR="$SPRITE_DIR/${CHARACTER}_kart"
if [ ! -d "$KART_DIR" ]; then
    echo "ERROR: Kart frames directory not found: $KART_DIR"
    ERRORS=$((ERRORS + 1))
else
    FRAME_COUNT=$(find "$KART_DIR" -name "${CHARACTER}_kart_frame*.png" | wc -l | tr -d ' ')
    if [ "$FRAME_COUNT" -eq 0 ]; then
        echo "ERROR: No kart frames found in $KART_DIR"
        ERRORS=$((ERRORS + 1))
    else
        echo "  Found $FRAME_COUNT kart frames"
    fi
fi

# Check portrait
PORTRAIT="$SPRITE_DIR/common_texture_portrait_${CHARACTER}.png"
if [ ! -f "$PORTRAIT" ]; then
    echo "ERROR: Portrait not found: $PORTRAIT"
    ERRORS=$((ERRORS + 1))
else
    echo "  Found portrait"
fi

# Check face frames
FACE_COUNT=$(find "$SPRITE_DIR" -name "${CHARACTER}_face_*.png" | wc -l | tr -d ' ')
if [ "$FACE_COUNT" -lt 17 ]; then
    echo "ERROR: Expected 17 face frames, found $FACE_COUNT"
    ERRORS=$((ERRORS + 1))
else
    echo "  Found $FACE_COUNT face frames"
fi

# Check nameplate
NAMEPLATE="$SPRITE_DIR/gTexture${CAPITALIZED}.png"
if [ ! -f "$NAMEPLATE" ]; then
    echo "ERROR: Nameplate not found: $NAMEPLATE"
    ERRORS=$((ERRORS + 1))
else
    echo "  Found nameplate"
fi

if [ "$ERRORS" -gt 0 ]; then
    echo ""
    echo "FAILED: $ERRORS required file(s) missing. Cannot package mod."
    exit 1
fi

# Validate image dimensions using sips (macOS) or identify (ImageMagick)
validate_dimensions() {
    local file="$1"
    local expected_w="$2"
    local expected_h="$3"

    if command -v sips &>/dev/null; then
        local w h
        w=$(sips -g pixelWidth "$file" 2>/dev/null | tail -1 | awk '{print $2}')
        h=$(sips -g pixelHeight "$file" 2>/dev/null | tail -1 | awk '{print $2}')
        if [ "$w" != "$expected_w" ] || [ "$h" != "$expected_h" ]; then
            echo "WARNING: $file is ${w}x${h}, expected ${expected_w}x${expected_h}"
        fi
    elif command -v identify &>/dev/null; then
        local dims
        dims=$(identify -format "%wx%h" "$file" 2>/dev/null)
        if [ "$dims" != "${expected_w}x${expected_h}" ]; then
            echo "WARNING: $file is $dims, expected ${expected_w}x${expected_h}"
        fi
    fi
}

echo ""
echo "Validating dimensions..."
validate_dimensions "$PORTRAIT" 32 32
validate_dimensions "$NAMEPLATE" 64 12

for face in "$SPRITE_DIR"/${CHARACTER}_face_*.png; do
    validate_dimensions "$face" 64 64
done

# Create staging directory
STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT

echo ""
echo "Building mod structure..."

# Copy character files into staging
mkdir -p "$STAGING/${CHARACTER}_kart"
cp "$KART_DIR"/${CHARACTER}_kart_frame*.png "$STAGING/${CHARACTER}_kart/"
cp "$PORTRAIT" "$STAGING/"
cp "$SPRITE_DIR"/${CHARACTER}_face_*.png "$STAGING/"
cp "$NAMEPLATE" "$STAGING/"

# Generate mods.toml for this character
cat > "$STAGING/mods.toml" << TOML
[mod]
name = "Lab 64: $CAPITALIZED"
version = "0.1.0"
description = "Custom $CHARACTER character replacement for Lab 64 team play."

[mod.authors]
names = ["Lab 64 Team"]
TOML

# Create .o2r archive
mkdir -p "$OUTPUT_DIR"
O2R_FILE="$OUTPUT_DIR/$CHARACTER.o2r"

# Remove existing archive if present
rm -f "$O2R_FILE"

# Create zip and rename to .o2r
(cd "$STAGING" && zip -r "$O2R_FILE" . -x ".*")

echo ""
echo "SUCCESS: Created $O2R_FILE"
echo "  Copy to SpaghettiKart mods/ folder to use."
