#!/usr/bin/env bash
set -euo pipefail

# Validate a SpaghettiKart .o2r mod archive.
#
# Usage:
#   tools/validate-mod.sh [options] <mod-file.o2r>
#
# Checks:
#   - mods.toml exists and has required fields
#   - All image files are valid PNG/JPG/BMP
#   - Texture dimensions are power-of-2
#   - No ROM files or extracted assets accidentally included
#   - Reports file count, total size, and warnings

LAB64_TOOLS_VERSION="lab64 tools v0.1.0"

QUIET=0
VERBOSE=0
JSON_OUTPUT=0
STRICT=0

usage() {
    echo "Usage: $0 [options] <mod-file.o2r>"
    echo ""
    echo "Validate a SpaghettiKart .o2r mod archive."
    echo ""
    echo "Options:"
    echo "  --help      Show this help message"
    echo "  --version   Print version and exit"
    echo "  --quiet     Suppress progress messages (errors still shown)"
    echo "  --verbose   Show detailed execution trace"
    echo "  --json      Output machine-parseable validation results as JSON"
    echo "  --strict    Treat warnings as errors"
    echo ""
    echo "Example:"
    echo "  $0 mods/animal-pack/dalmatian.o2r"
    exit 1
}

log() {
    if [ "$QUIET" -eq 0 ]; then
        echo "$@"
    fi
}

verbose_log() {
    if [ "$VERBOSE" -eq 1 ]; then
        echo "[VERBOSE] $@"
    fi
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

# Parse options
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
        --json)
            JSON_OUTPUT=1
            QUIET=1
            shift
            ;;
        --strict)
            STRICT=1
            shift
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

if [ ${#POSITIONAL[@]} -lt 1 ]; then
    usage
fi

MOD_FILE="${POSITIONAL[0]}"
WARNINGS=0
ERRORS=0
CHECKS_PASSED=()
CHECKS_FAILED=()
CHECKS_WARNED=()

verbose_log "Validating file: $MOD_FILE"
verbose_log "Strict mode: $STRICT"

log "Validating mod: $MOD_FILE"
log "================================"

# Check file exists
if [ ! -f "$MOD_FILE" ]; then
    if [ "$JSON_OUTPUT" -eq 1 ]; then
        json_result "error" "File not found: $MOD_FILE" "{}"
    else
        echo "ERROR: File not found: $MOD_FILE"
    fi
    exit 1
fi

# Check file extension
if [[ "$MOD_FILE" != *.o2r ]]; then
    log "WARNING: File does not have .o2r extension"
    WARNINGS=$((WARNINGS + 1))
    CHECKS_WARNED+=("file_extension")
fi

verbose_log "Testing zip integrity..."

# Check it's a valid zip
if ! unzip -t "$MOD_FILE" &>/dev/null; then
    if [ "$JSON_OUTPUT" -eq 1 ]; then
        json_result "error" "Not a valid zip/o2r archive" "{\"file\":\"$MOD_FILE\"}"
    else
        echo "ERROR: Not a valid zip/o2r archive"
    fi
    exit 1
fi

# Extract to temp directory for inspection
STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT

verbose_log "Extracting archive to temporary directory..."
unzip -q "$MOD_FILE" -d "$STAGING"

log ""
log "Archive contents:"

# Check mods.toml
if [ -f "$STAGING/mods.toml" ]; then
    log "  [OK] mods.toml found"
    CHECKS_PASSED+=("mods_toml_present")

    # Check required fields
    if grep -q '^\[mod\]' "$STAGING/mods.toml" 2>/dev/null; then
        log "  [OK] [mod] section present"
        CHECKS_PASSED+=("mod_section")
    else
        log "  [ERROR] Missing [mod] section in mods.toml"
        ERRORS=$((ERRORS + 1))
        CHECKS_FAILED+=("mod_section")
    fi

    if grep -q '^name' "$STAGING/mods.toml" 2>/dev/null; then
        NAME=$(grep '^name' "$STAGING/mods.toml" | head -1 | sed 's/name *= *"\(.*\)"/\1/')
        log "  [OK] name = $NAME"
        CHECKS_PASSED+=("name_field")
    else
        log "  [ERROR] Missing 'name' field in mods.toml"
        ERRORS=$((ERRORS + 1))
        CHECKS_FAILED+=("name_field")
    fi

    if grep -q '^version' "$STAGING/mods.toml" 2>/dev/null; then
        VERSION=$(grep '^version' "$STAGING/mods.toml" | head -1 | sed 's/version *= *"\(.*\)"/\1/')
        log "  [OK] version = $VERSION"
        CHECKS_PASSED+=("version_field")
    else
        log "  [ERROR] Missing 'version' field in mods.toml"
        ERRORS=$((ERRORS + 1))
        CHECKS_FAILED+=("version_field")
    fi
else
    log "  [ERROR] mods.toml not found (required by SpaghettiKart)"
    ERRORS=$((ERRORS + 1))
    CHECKS_FAILED+=("mods_toml_present")
fi

log ""
log "Image validation:"

verbose_log "Scanning for image files..."

# Find all image files
IMAGE_COUNT=0
while IFS= read -r -d '' img; do
    IMAGE_COUNT=$((IMAGE_COUNT + 1))
    ext="${img##*.}"
    ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    # Check format
    if [[ "$ext_lower" != "png" && "$ext_lower" != "jpg" && "$ext_lower" != "jpeg" && "$ext_lower" != "bmp" ]]; then
        log "  [WARNING] Unsupported image format: $img"
        WARNINGS=$((WARNINGS + 1))
        CHECKS_WARNED+=("unsupported_format:$(basename "$img")")
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
                log "  [WARNING] Width $w not power-of-2: $(basename "$img")"
                WARNINGS=$((WARNINGS + 1))
                CHECKS_WARNED+=("dimension:$(basename "$img")")
            fi

            # Height 12 is valid for nameplates
            if [ "$h" -ne 12 ] && ! is_power_of_2 "$h"; then
                log "  [WARNING] Height $h not power-of-2: $(basename "$img")"
                WARNINGS=$((WARNINGS + 1))
                CHECKS_WARNED+=("dimension:$(basename "$img")")
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
                log "  [WARNING] Width $w not power-of-2: $(basename "$img")"
                WARNINGS=$((WARNINGS + 1))
                CHECKS_WARNED+=("dimension:$(basename "$img")")
            fi

            if [ "$h" -ne 12 ] && ! is_power_of_2 "$h"; then
                log "  [WARNING] Height $h not power-of-2: $(basename "$img")"
                WARNINGS=$((WARNINGS + 1))
                CHECKS_WARNED+=("dimension:$(basename "$img")")
            fi
        fi
    else
        log "  [INFO] No image inspection tool available (sips or ImageMagick). Skipping dimension checks."
        break
    fi
done < <(find "$STAGING" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.bmp" \) -print0)

log "  Found $IMAGE_COUNT image file(s)"

# Check for accidentally included ROM files
log ""
log "Safety checks:"

verbose_log "Scanning for ROM files..."

ROM_COUNT=0
while IFS= read -r -d '' rom; do
    log "  [ERROR] ROM file found in archive: $(basename "$rom")"
    ROM_COUNT=$((ROM_COUNT + 1))
    ERRORS=$((ERRORS + 1))
    CHECKS_FAILED+=("no_roms:$(basename "$rom")")
done < <(find "$STAGING" -type f \( -iname "*.z64" -o -iname "*.n64" -o -iname "*.rom" -o -iname "*.v64" \) -print0)

if [ "$ROM_COUNT" -eq 0 ]; then
    log "  [OK] No ROM files found"
    CHECKS_PASSED+=("no_roms")
fi

# Check for extracted asset directories
if [ -d "$STAGING/extracted-assets" ]; then
    log "  [ERROR] extracted-assets/ directory found in archive"
    ERRORS=$((ERRORS + 1))
    CHECKS_FAILED+=("no_extracted_assets")
else
    log "  [OK] No extracted asset directories"
    CHECKS_PASSED+=("no_extracted_assets")
fi

# File count and size report
FILE_COUNT=$(find "$STAGING" -type f | wc -l | tr -d ' ')
TOTAL_SIZE=$(du -sh "$MOD_FILE" | awk '{print $1}')

log ""
log "Summary:"
log "  Files: $FILE_COUNT"
log "  Archive size: $TOTAL_SIZE"
log "  Warnings: $WARNINGS"
log "  Errors: $ERRORS"

# In strict mode, treat warnings as errors
if [ "$STRICT" -eq 1 ] && [ "$WARNINGS" -gt 0 ]; then
    ERRORS=$((ERRORS + WARNINGS))
fi

if [ "$ERRORS" -gt 0 ]; then
    if [ "$JSON_OUTPUT" -eq 1 ]; then
        json_result "error" "Validation failed with $ERRORS error(s)" \
            "{\"errors\":$ERRORS,\"warnings\":$WARNINGS,\"files\":$FILE_COUNT,\"size\":\"$TOTAL_SIZE\",\"images\":$IMAGE_COUNT}"
    else
        log ""
        log "VALIDATION FAILED: $ERRORS error(s) found."
    fi
    exit 1
fi

if [ "$WARNINGS" -gt 0 ]; then
    if [ "$JSON_OUTPUT" -eq 1 ]; then
        json_result "success" "Validation passed with $WARNINGS warning(s)" \
            "{\"errors\":0,\"warnings\":$WARNINGS,\"files\":$FILE_COUNT,\"size\":\"$TOTAL_SIZE\",\"images\":$IMAGE_COUNT}"
    else
        log ""
        log "VALIDATION PASSED with $WARNINGS warning(s)."
    fi
    exit 0
fi

if [ "$JSON_OUTPUT" -eq 1 ]; then
    json_result "success" "Validation passed" \
        "{\"errors\":0,\"warnings\":0,\"files\":$FILE_COUNT,\"size\":\"$TOTAL_SIZE\",\"images\":$IMAGE_COUNT}"
else
    log ""
    log "VALIDATION PASSED."
fi
exit 0
