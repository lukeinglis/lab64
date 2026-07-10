#!/usr/bin/env bash
set -euo pipefail

# Pack a character's sprites into a SpaghettiKart .o2r mod archive.
#
# Usage:
#   tools/pack-character-mod.sh [options] <character-name> <sprite-directory>
#
# Example:
#   tools/pack-character-mod.sh dalmatian assets/characters/dalmatian/sprites

LAB64_TOOLS_VERSION="lab64 tools v0.1.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source shared logging library
. "$SCRIPT_DIR/lib/logging.sh"

QUIET=0
VERBOSE=0
DRY_RUN=0
JSON_OUTPUT=0
CUSTOM_OUTPUT_DIR=""

usage() {
    echo "Usage: $0 [options] <character-name> <sprite-directory>"
    echo ""
    echo "Pack character sprites into a SpaghettiKart .o2r mod archive."
    echo ""
    echo "Arguments:"
    echo "  character-name    Name of the character (e.g. dalmatian, yellow_lab)"
    echo "  sprite-directory  Directory containing rendered sprites"
    echo ""
    echo "Options:"
    echo "  --help        Show this help message"
    echo "  --version     Print version and exit"
    echo "  --quiet       Suppress progress messages (errors still shown)"
    echo "  --verbose     Show detailed execution trace"
    echo "  --dry-run     Show what would be packaged without creating .o2r"
    echo "  --json        Output structured JSON result"
    echo "  --output-dir DIR  Override default output location"
    echo ""
    echo "Example:"
    echo "  $0 dalmatian assets/characters/dalmatian/sprites"
    exit 1
}

json_result() {
    local status="$1"
    local message="$2"
    local details="$3"
    local timestamp
    timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    printf '{"status":"%s","message":"%s","details":%s,"timestamp":"%s"}\n' \
        "$status" "$message" "$details" "$timestamp"
}

# Parse options before positional args
POSITIONAL=()
while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h)
            usage
            ;;
        --version)
            echo "$LAB64_TOOLS_VERSION"
            exit 0
            ;;
        --quiet)
            QUIET=1
            shift
            ;;
        --verbose)
            VERBOSE=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --json)
            JSON_OUTPUT=1
            QUIET=1
            shift
            ;;
        --output-dir)
            if [ $# -lt 2 ]; then
                echo "ERROR: --output-dir requires a directory argument" >&2
                exit 1
            fi
            CUSTOM_OUTPUT_DIR="$2"
            shift 2
            ;;
        -*)
            echo "ERROR: Unknown option: $1" >&2
            exit 1
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

if [ ${#POSITIONAL[@]} -lt 2 ]; then
    usage
fi

CHARACTER="${POSITIONAL[0]}"
SPRITE_DIR="${POSITIONAL[1]}"

# Initialize logging after flag parsing
logging_init

if [ -n "$CUSTOM_OUTPUT_DIR" ]; then
    OUTPUT_DIR="$CUSTOM_OUTPUT_DIR"
else
    OUTPUT_DIR="$PROJECT_ROOT/mods/animal-pack"
fi

CAPITALIZED=$(echo "$CHARACTER" | awk -F'_' '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) substr($i,2)}}1' OFS='')

log_debug "Character: $CHARACTER"
log_debug "Sprite directory: $SPRITE_DIR"
log_debug "Output directory: $OUTPUT_DIR"
log_debug "Capitalized name: $CAPITALIZED"

log_info "Packing character mod: $CHARACTER"
log_info "Sprite directory: $SPRITE_DIR"
log_info "Output: $OUTPUT_DIR/$CHARACTER.o2r"

# Validate sprite directory exists
if [ ! -d "$SPRITE_DIR" ]; then
    log_error "Sprite directory not found: $SPRITE_DIR"
    if [ "$JSON_OUTPUT" -eq 1 ]; then
        json_result "error" "Sprite directory not found: $SPRITE_DIR" "{}"
    else
        echo "ERROR: Sprite directory not found: $SPRITE_DIR"
    fi
    exit 1
fi

# Validate required files
ERRORS=0
DETAILS_KART_FRAMES=0
DETAILS_FACE_FRAMES=0

log_debug "Checking kart frames directory..."

# Check kart frames
KART_DIR="$SPRITE_DIR/${CHARACTER}_kart"
if [ ! -d "$KART_DIR" ]; then
    log_error "Kart frames directory not found: $KART_DIR"
    echo "ERROR: Kart frames directory not found: $KART_DIR"
    ERRORS=$((ERRORS + 1))
else
    FRAME_COUNT=$(find "$KART_DIR" -name "${CHARACTER}_kart_frame*.png" | wc -l | tr -d ' ')
    if [ "$FRAME_COUNT" -eq 0 ]; then
        log_error "No kart frames found in $KART_DIR"
        echo "ERROR: No kart frames found in $KART_DIR"
        ERRORS=$((ERRORS + 1))
    else
        DETAILS_KART_FRAMES=$FRAME_COUNT
        log_info_ctx "Found kart frames" "{\"count\":$FRAME_COUNT}"
        if [ "$QUIET" -eq 0 ]; then
            echo "  Found $FRAME_COUNT kart frames"
        fi
    fi
fi

log_debug "Checking portrait..."

# Check portrait
PORTRAIT="$SPRITE_DIR/common_texture_portrait_${CHARACTER}.png"
if [ ! -f "$PORTRAIT" ]; then
    log_error "Portrait not found: $PORTRAIT"
    echo "ERROR: Portrait not found: $PORTRAIT"
    ERRORS=$((ERRORS + 1))
else
    log_info "Found portrait"
    if [ "$QUIET" -eq 0 ]; then
        echo "  Found portrait"
    fi
fi

log_debug "Checking face frames..."

# Check face frames
FACE_COUNT=$(find "$SPRITE_DIR" -name "${CHARACTER}_face_*.png" | wc -l | tr -d ' ')
if [ "$FACE_COUNT" -lt 17 ]; then
    log_error "Expected 17 face frames, found $FACE_COUNT"
    echo "ERROR: Expected 17 face frames, found $FACE_COUNT"
    ERRORS=$((ERRORS + 1))
else
    DETAILS_FACE_FRAMES=$FACE_COUNT
    log_info_ctx "Found face frames" "{\"count\":$FACE_COUNT}"
    if [ "$QUIET" -eq 0 ]; then
        echo "  Found $FACE_COUNT face frames"
    fi
fi

log_debug "Checking nameplate..."

# Check nameplate
NAMEPLATE="$SPRITE_DIR/gTexture${CAPITALIZED}.png"
if [ ! -f "$NAMEPLATE" ]; then
    log_error "Nameplate not found: $NAMEPLATE"
    echo "ERROR: Nameplate not found: $NAMEPLATE"
    ERRORS=$((ERRORS + 1))
else
    log_info "Found nameplate"
    if [ "$QUIET" -eq 0 ]; then
        echo "  Found nameplate"
    fi
fi

if [ "$ERRORS" -gt 0 ]; then
    log_error_ctx "Pack failed: required files missing" "{\"errors\":$ERRORS}"
    if [ "$JSON_OUTPUT" -eq 1 ]; then
        json_result "error" "$ERRORS required file(s) missing" "{\"errors\":$ERRORS}"
    else
        echo ""
        echo "FAILED: $ERRORS required file(s) missing. Cannot package mod."
    fi
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
            log_warn_ctx "Dimension mismatch" "{\"file\":\"$(basename "$file")\",\"actual\":\"${w}x${h}\",\"expected\":\"${expected_w}x${expected_h}\"}"
            if [ "$QUIET" -eq 0 ]; then
                echo "WARNING: $file is ${w}x${h}, expected ${expected_w}x${expected_h}"
            fi
        fi
    elif command -v identify &>/dev/null; then
        local dims
        dims=$(identify -format "%wx%h" "$file" 2>/dev/null)
        if [ "$dims" != "${expected_w}x${expected_h}" ]; then
            log_warn_ctx "Dimension mismatch" "{\"file\":\"$(basename "$file")\",\"actual\":\"$dims\",\"expected\":\"${expected_w}x${expected_h}\"}"
            if [ "$QUIET" -eq 0 ]; then
                echo "WARNING: $file is $dims, expected ${expected_w}x${expected_h}"
            fi
        fi
    fi
}

log_info "Validating dimensions..."
validate_dimensions "$PORTRAIT" 32 32
validate_dimensions "$NAMEPLATE" 64 12

for face in "$SPRITE_DIR"/${CHARACTER}_face_*.png; do
    validate_dimensions "$face" 64 64
done

# Dry-run: report what would be packaged and exit
if [ "$DRY_RUN" -eq 1 ]; then
    log_info_ctx "Dry run complete" "{\"character\":\"$CHARACTER\",\"kart_frames\":$DETAILS_KART_FRAMES,\"face_frames\":$DETAILS_FACE_FRAMES}"
    if [ "$QUIET" -eq 0 ]; then
        echo ""
        echo "DRY RUN: Would package the following into $OUTPUT_DIR/$CHARACTER.o2r:"
        echo "  Kart frames: $DETAILS_KART_FRAMES files from $KART_DIR/"
        echo "  Portrait: $(basename "$PORTRAIT")"
        echo "  Face frames: $DETAILS_FACE_FRAMES files"
        echo "  Nameplate: $(basename "$NAMEPLATE")"
        echo "  mods.toml: auto-generated"
    fi

    if [ "$JSON_OUTPUT" -eq 1 ]; then
        json_result "success" "Dry run complete" \
            "{\"character\":\"$CHARACTER\",\"kart_frames\":$DETAILS_KART_FRAMES,\"face_frames\":$DETAILS_FACE_FRAMES,\"output\":\"$OUTPUT_DIR/$CHARACTER.o2r\",\"dry_run\":true}"
    fi
    exit 0
fi

log_debug "Creating staging directory..."

# Create staging directory
STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT

log_info "Building mod structure..."

log_debug "Copying kart frames to staging..."

# Copy character files into staging
mkdir -p "$STAGING/${CHARACTER}_kart"
cp "$KART_DIR"/${CHARACTER}_kart_frame*.png "$STAGING/${CHARACTER}_kart/"

log_debug "Copying portrait, faces, nameplate to staging..."
cp "$PORTRAIT" "$STAGING/"
cp "$SPRITE_DIR"/${CHARACTER}_face_*.png "$STAGING/"
cp "$NAMEPLATE" "$STAGING/"

log_debug "Generating mods.toml..."

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

log_debug "Removing existing archive if present..."

# Remove existing archive if present
rm -f "$O2R_FILE"

log_debug "Creating zip archive..."

# Create zip and rename to .o2r
(cd "$STAGING" && zip -r "$O2R_FILE" . -x ".*") >/dev/null 2>&1

log_info_ctx "Archive created" "{\"output\":\"$O2R_FILE\",\"character\":\"$CHARACTER\",\"kart_frames\":$DETAILS_KART_FRAMES,\"face_frames\":$DETAILS_FACE_FRAMES}"

if [ "$JSON_OUTPUT" -eq 1 ]; then
    local_size=$(du -sh "$O2R_FILE" 2>/dev/null | awk '{print $1}' || echo "unknown")
    json_result "success" "Created $O2R_FILE" \
        "{\"character\":\"$CHARACTER\",\"output\":\"$O2R_FILE\",\"kart_frames\":$DETAILS_KART_FRAMES,\"face_frames\":$DETAILS_FACE_FRAMES,\"size\":\"$local_size\"}"
else
    echo ""
    echo "SUCCESS: Created $O2R_FILE"
    echo "  Copy to SpaghettiKart mods/ folder to use."
fi
