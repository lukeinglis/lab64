#!/usr/bin/env bash
set -euo pipefail

# Transfer .o2r mod files to a Windows machine running SpaghettiKart.
#
# Usage:
#   tools/sync-to-windows.sh [options] [mod-file.o2r ...]
#
# Transfer methods (checked in order):
#   1. LAB64_WINDOWS_MODS_PATH env var (rsync over SSH or local path)
#   2. --target argument
#   3. Manual instructions printed to stdout
#
# Examples:
#   # Rsync to Windows machine over SSH
#   LAB64_WINDOWS_MODS_PATH="user@windows-pc:/c/Games/SpaghettiKart/mods" \
#     tools/sync-to-windows.sh mods/animal-pack/dalmatian.o2r
#
#   # Copy to mounted USB drive
#   tools/sync-to-windows.sh --target /Volumes/USB/SpaghettiKart/mods mods/animal-pack/*.o2r
#
#   # Print manual instructions
#   tools/sync-to-windows.sh mods/animal-pack/dalmatian.o2r

LAB64_TOOLS_VERSION="lab64 tools v0.1.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source shared logging library
. "$SCRIPT_DIR/lib/logging.sh"

QUIET=0
VERBOSE=0
DRY_RUN=0
FORCE=0

usage() {
    echo "Usage: $0 [options] [mod-file.o2r ...]"
    echo ""
    echo "Transfer .o2r mod files to a Windows machine running SpaghettiKart."
    echo ""
    echo "Options:"
    echo "  --help        Show this help message"
    echo "  --version     Print version and exit"
    echo "  --quiet       Suppress progress messages (errors still shown)"
    echo "  --verbose     Show detailed execution trace"
    echo "  --target <path>  Destination path (local mount or user@host:/path)"
    echo "  --dry-run     Show what would be copied without transferring"
    echo "  --force       Skip confirmation prompts"
    echo ""
    echo "Environment:"
    echo "  LAB64_WINDOWS_MODS_PATH  Default target path if --target not specified"
    echo ""
    echo "If no mod files are specified, all .o2r files in mods/ are synced."
    echo ""
    echo "Examples:"
    echo "  $0 mods/animal-pack/dalmatian.o2r"
    echo "  $0 --target /Volumes/USB/SpaghettiKart/mods mods/animal-pack/*.o2r"
    echo "  LAB64_WINDOWS_MODS_PATH=user@pc:/c/Games/SK/mods $0"
    exit 1
}

TARGET="${LAB64_WINDOWS_MODS_PATH:-}"
MOD_FILES=()

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --target)
            if [ $# -lt 2 ]; then
                echo "ERROR: --target requires a path argument"
                exit 1
            fi
            TARGET="$2"
            shift 2
            ;;
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
        --force)
            FORCE=1
            shift
            ;;
        -*)
            echo "ERROR: Unknown option: $1" >&2
            exit 1
            ;;
        *)
            MOD_FILES+=("$1")
            shift
            ;;
    esac
done

# Initialize logging after flag parsing
logging_init

log_debug "Target: ${TARGET:-<not set>}"
log_debug "Dry run: $DRY_RUN"
log_debug "Force: $FORCE"

# Default to all .o2r files in mods/ if none specified
if [ ${#MOD_FILES[@]} -eq 0 ]; then
    log_debug "No mod files specified, scanning mods/ directory..."
    while IFS= read -r -d '' f; do
        MOD_FILES+=("$f")
    done < <(find "$PROJECT_ROOT/mods" -name "*.o2r" -print0 2>/dev/null)
fi

if [ ${#MOD_FILES[@]} -eq 0 ]; then
    log_info "No .o2r files found to sync"
    echo "No .o2r files found to sync."
    echo "Build mods first with: tools/pack-character-mod.sh"
    exit 0
fi

log_info_ctx "Files to sync" "{\"count\":${#MOD_FILES[@]}}"
echo "Mod files to sync:"
for f in "${MOD_FILES[@]}"; do
    local_size=$(du -h "$f" | awk '{print $1}')
    log_info_ctx "Sync file" "{\"file\":\"$(basename "$f")\",\"size\":\"$local_size\"}"
    echo "  $(basename "$f") ($local_size)"
done

# If no target configured, print manual instructions
if [ -z "$TARGET" ]; then
    log_info "No target configured, printing manual instructions"
    echo ""
    echo "No target configured. To transfer mods to Windows:"
    echo ""
    echo "Option 1: Set LAB64_WINDOWS_MODS_PATH"
    echo "  export LAB64_WINDOWS_MODS_PATH=\"user@windows-pc:/c/Games/SpaghettiKart/mods\""
    echo "  $0"
    echo ""
    echo "Option 2: Use --target with a mounted drive"
    echo "  $0 --target /Volumes/USB/SpaghettiKart/mods"
    echo ""
    echo "Option 3: Copy manually"
    echo "  Copy these files to your SpaghettiKart mods/ folder on Windows:"
    for f in "${MOD_FILES[@]}"; do
        echo "    $(realpath "$f")"
    done
    echo ""
    echo "  Typical Windows location: C:\\Games\\SpaghettiKart\\mods\\"
    exit 0
fi

log_info_ctx "Target configured" "{\"target\":\"$TARGET\"}"
echo ""
echo "Target: $TARGET"

# Dry-run: show what would happen and exit
if [ "$DRY_RUN" -eq 1 ]; then
    log_info "Dry run mode — no files will be transferred"
    echo ""
    echo "DRY RUN: Would transfer the following files to $TARGET:"
    for f in "${MOD_FILES[@]}"; do
        echo "  $(basename "$f") ($(du -h "$f" | awk '{print $1}'))"
    done
    if [[ "$TARGET" == *:* ]]; then
        echo "  Transfer method: rsync over SSH"
    else
        echo "  Transfer method: local copy"
    fi
    exit 0
fi

# Determine transfer method
if [[ "$TARGET" == *:* ]]; then
    # SSH/rsync path (contains colon, e.g. user@host:/path)
    log_info "Transfer method: rsync over SSH"
    echo "Transfer method: rsync over SSH"
    echo ""

    for f in "${MOD_FILES[@]}"; do
        log_debug "Syncing $(basename "$f") via rsync..."
        echo "Syncing $(basename "$f")..."
        rsync -avz --progress "$f" "$TARGET/"
    done
else
    # Local path (mounted drive, shared folder)
    log_info "Transfer method: local copy"
    echo "Transfer method: local copy"

    if [ ! -d "$TARGET" ]; then
        log_error "Target directory does not exist: $TARGET"
        echo "ERROR: Target directory does not exist: $TARGET"
        echo "Make sure the drive is mounted or the path is correct."
        exit 1
    fi

    for f in "${MOD_FILES[@]}"; do
        log_info_ctx "Copying file" "{\"file\":\"$(basename "$f")\",\"target\":\"$TARGET\"}"
        echo "Copying $(basename "$f")..."
        cp -v "$f" "$TARGET/"
    done
fi

log_info "Sync complete"
echo ""
echo "Done. Launch SpaghettiKart to load the mods."
