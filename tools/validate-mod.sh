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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared logging library
. "$SCRIPT_DIR/lib/logging.sh"

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

# Initialize logging after flag parsing
logging_init

log_debug "Validating file: $MOD_FILE"
log_debug "Strict mode: $STRICT"

echo "Validating mod: $MOD_FILE"
echo "================================"

# Check file exists
if [ ! -f "$MOD_FILE" ]; then
    log_error "File not found: $MOD_FILE"
    if [ "$JSON_OUTPUT" -eq 1 ]; then
        json_result "error" "File not found: $MOD_FILE" "{}"
    else
        echo "ERROR: File not found: $MOD_FILE"
    fi
    exit 1
fi

# Check file extension
if [[ "$MOD_FILE" != *.o2r ]]; then
    log_warn "File does not have .o2r extension"
    echo "WARNING: File does not have .o2r extension"
    WARNINGS=$((WARNINGS + 1))
    CHECKS_WARNED+=("file_extension")
fi

log_debug "Testing zip integrity..."

# Check it's a valid zip
if ! unzip -t "$MOD_FILE" &>/dev/null; then
    log_error "Not a valid zip/o2r archive: $MOD_FILE"
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

log_debug "Extracting archive to temporary directory..."
unzip -q "$MOD_FILE" -d "$STAGING"

echo ""
echo "Archive contents:"

# Check mods.toml
if [ -f "$STAGING/mods.toml" ]; then
    log_info_ctx "Check passed" "{\"check\":\"mods_toml_present\"}"
    echo "  [OK] mods.toml found"
    CHECKS_PASSED+=("mods_toml_present")

    # Check required fields
    if grep -q '^\[mod\]' "$STAGING/mods.toml" 2>/dev/null; then
        log_info_ctx "Check passed" "{\"check\":\"mod_section\"}"
        echo "  [OK] [mod] section present"
        CHECKS_PASSED+=("mod_section")
    else
        log_error_ctx "Check failed" "{\"check\":\"mod_section\"}"
        echo "  [ERROR] Missing [mod] section in mods.toml"
        ERRORS=$((ERRORS + 1))
        CHECKS_FAILED+=("mod_section")
    fi

    if grep -q '^name' "$STAGING/mods.toml" 2>/dev/null; then
        NAME=$(grep '^name' "$STAGING/mods.toml" | head -1 | sed 's/name *= *"\(.*\)"/\1/')
        log_info_ctx "Check passed" "{\"check\":\"name_field\",\"value\":\"$NAME\"}"
        echo "  [OK] name = $NAME"
        CHECKS_PASSED+=("name_field")
    else
        log_error_ctx "Check failed" "{\"check\":\"name_field\"}"
        echo "  [ERROR] Missing 'name' field in mods.toml"
        ERRORS=$((ERRORS + 1))
        CHECKS_FAILED+=("name_field")
    fi

    if grep -q '^version' "$STAGING/mods.toml" 2>/dev/null; then
        VERSION=$(grep '^version' "$STAGING/mods.toml" | head -1 | sed 's/version *= *"\(.*\)"/\1/')
        log_info_ctx "Check passed" "{\"check\":\"version_field\",\"value\":\"$VERSION\"}"
        echo "  [OK] version = $VERSION"
        CHECKS_PASSED+=("version_field")
    else
        log_error_ctx "Check failed" "{\"check\":\"version_field\"}"
        echo "  [ERROR] Missing 'version' field in mods.toml"
        ERRORS=$((ERRORS + 1))
        CHECKS_FAILED+=("version_field")
    fi
else
    log_error_ctx "Check failed" "{\"check\":\"mods_toml_present\"}"
    echo "  [ERROR] mods.toml not found (required by SpaghettiKart)"
    ERRORS=$((ERRORS + 1))
    CHECKS_FAILED+=("mods_toml_present")
fi

echo ""
echo "Image validation:"

log_debug "Scanning for image files..."

# Find all image files
IMAGE_COUNT=0
while IFS= read -r -d '' img; do
    IMAGE_COUNT=$((IMAGE_COUNT + 1))
    ext="${img##*.}"
    ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    # Check format
    if [[ "$ext_lower" != "png" && "$ext_lower" != "jpg" && "$ext_lower" != "jpeg" && "$ext_lower" != "bmp" ]]; then
        log_warn_ctx "Unsupported image format" "{\"file\":\"$(basename "$img")\"}"
        echo "  [WARNING] Unsupported image format: $img"
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
                log_warn_ctx "Dimension not power-of-2" "{\"file\":\"$(basename "$img")\",\"dimension\":\"width\",\"value\":$w}"
                echo "  [WARNING] Width $w not power-of-2: $(basename "$img")"
                WARNINGS=$((WARNINGS + 1))
                CHECKS_WARNED+=("dimension:$(basename "$img")")
            fi

            # Height 12 is valid for nameplates
            if [ "$h" -ne 12 ] && ! is_power_of_2 "$h"; then
                log_warn_ctx "Dimension not power-of-2" "{\"file\":\"$(basename "$img")\",\"dimension\":\"height\",\"value\":$h}"
                echo "  [WARNING] Height $h not power-of-2: $(basename "$img")"
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
                log_warn_ctx "Dimension not power-of-2" "{\"file\":\"$(basename "$img")\",\"dimension\":\"width\",\"value\":$w}"
                echo "  [WARNING] Width $w not power-of-2: $(basename "$img")"
                WARNINGS=$((WARNINGS + 1))
                CHECKS_WARNED+=("dimension:$(basename "$img")")
            fi

            if [ "$h" -ne 12 ] && ! is_power_of_2 "$h"; then
                log_warn_ctx "Dimension not power-of-2" "{\"file\":\"$(basename "$img")\",\"dimension\":\"height\",\"value\":$h}"
                echo "  [WARNING] Height $h not power-of-2: $(basename "$img")"
                WARNINGS=$((WARNINGS + 1))
                CHECKS_WARNED+=("dimension:$(basename "$img")")
            fi
        fi
    else
        log_info "No image inspection tool available (sips or ImageMagick). Skipping dimension checks."
        echo "  [INFO] No image inspection tool available (sips or ImageMagick). Skipping dimension checks."
        break
    fi
done < <(find "$STAGING" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.bmp" \) -print0)

log_info_ctx "Image scan complete" "{\"count\":$IMAGE_COUNT}"
echo "  Found $IMAGE_COUNT image file(s)"

# Check for accidentally included ROM files
echo ""
echo "Safety checks:"

log_debug "Scanning for ROM files..."

ROM_COUNT=0
while IFS= read -r -d '' rom; do
    log_error_ctx "ROM file found in archive" "{\"file\":\"$(basename "$rom")\"}"
    echo "  [ERROR] ROM file found in archive: $(basename "$rom")"
    ROM_COUNT=$((ROM_COUNT + 1))
    ERRORS=$((ERRORS + 1))
    CHECKS_FAILED+=("no_roms:$(basename "$rom")")
done < <(find "$STAGING" -type f \( -iname "*.z64" -o -iname "*.n64" -o -iname "*.rom" -o -iname "*.v64" \) -print0)

if [ "$ROM_COUNT" -eq 0 ]; then
    log_info_ctx "Check passed" "{\"check\":\"no_roms\"}"
    echo "  [OK] No ROM files found"
    CHECKS_PASSED+=("no_roms")
fi

# Check for extracted asset directories
if [ -d "$STAGING/extracted-assets" ]; then
    log_error_ctx "Check failed" "{\"check\":\"no_extracted_assets\"}"
    echo "  [ERROR] extracted-assets/ directory found in archive"
    ERRORS=$((ERRORS + 1))
    CHECKS_FAILED+=("no_extracted_assets")
else
    log_info_ctx "Check passed" "{\"check\":\"no_extracted_assets\"}"
    echo "  [OK] No extracted asset directories"
    CHECKS_PASSED+=("no_extracted_assets")
fi

# File count and size report
FILE_COUNT=$(find "$STAGING" -type f | wc -l | tr -d ' ')
TOTAL_SIZE=$(du -sh "$MOD_FILE" | awk '{print $1}')

log_info_ctx "Validation summary" "{\"files\":$FILE_COUNT,\"size\":\"$TOTAL_SIZE\",\"warnings\":$WARNINGS,\"errors\":$ERRORS,\"images\":$IMAGE_COUNT}"

echo ""
echo "Summary:"
echo "  Files: $FILE_COUNT"
echo "  Archive size: $TOTAL_SIZE"
echo "  Warnings: $WARNINGS"
echo "  Errors: $ERRORS"

# In strict mode, treat warnings as errors
if [ "$STRICT" -eq 1 ] && [ "$WARNINGS" -gt 0 ]; then
    ERRORS=$((ERRORS + WARNINGS))
fi

if [ "$ERRORS" -gt 0 ]; then
    log_error "Validation failed with $ERRORS error(s)"
    if [ "$JSON_OUTPUT" -eq 1 ]; then
        json_result "error" "Validation failed with $ERRORS error(s)" \
            "{\"errors\":$ERRORS,\"warnings\":$WARNINGS,\"files\":$FILE_COUNT,\"size\":\"$TOTAL_SIZE\",\"images\":$IMAGE_COUNT}"
    else
        echo ""
        echo "VALIDATION FAILED: $ERRORS error(s) found."
    fi
    exit 1
fi

if [ "$WARNINGS" -gt 0 ]; then
    log_warn "Validation passed with $WARNINGS warning(s)"
    if [ "$JSON_OUTPUT" -eq 1 ]; then
        json_result "success" "Validation passed with $WARNINGS warning(s)" \
            "{\"errors\":0,\"warnings\":$WARNINGS,\"files\":$FILE_COUNT,\"size\":\"$TOTAL_SIZE\",\"images\":$IMAGE_COUNT}"
    else
        echo ""
        echo "VALIDATION PASSED with $WARNINGS warning(s)."
    fi
    exit 0
fi

log_info "Validation passed"
if [ "$JSON_OUTPUT" -eq 1 ]; then
    json_result "success" "Validation passed" \
        "{\"errors\":0,\"warnings\":0,\"files\":$FILE_COUNT,\"size\":\"$TOTAL_SIZE\",\"images\":$IMAGE_COUNT}"
else
    echo ""
    echo "VALIDATION PASSED."
fi
exit 0
