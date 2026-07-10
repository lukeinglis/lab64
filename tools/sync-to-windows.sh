#!/usr/bin/env bash
set -euo pipefail

# Transfer .o2r mod files to a Windows machine running SpaghettiKart.
#
# Usage:
#   tools/sync-to-windows.sh [mod-file.o2r ...]
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
    echo "Usage: $0 [--target <path>] [mod-file.o2r ...]"
    echo ""
    echo "Transfer .o2r mod files to a Windows machine running SpaghettiKart."
    echo ""
    echo "Options:"
    echo "  --target <path>  Destination path (local mount or user@host:/path)"
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
        *)
            MOD_FILES+=("$1")
            shift
            ;;
    esac
done

# Default to all .o2r files in mods/ if none specified
if [ ${#MOD_FILES[@]} -eq 0 ]; then
    while IFS= read -r -d '' f; do
        MOD_FILES+=("$f")
    done < <(find "$PROJECT_ROOT/mods" -name "*.o2r" -print0 2>/dev/null)
fi

if [ ${#MOD_FILES[@]} -eq 0 ]; then
    echo "No .o2r files found to sync."
    echo "Build mods first with: tools/pack-character-mod.sh"
    exit 0
fi

echo "Mod files to sync:"
for f in "${MOD_FILES[@]}"; do
    echo "  $(basename "$f") ($(du -h "$f" | awk '{print $1}'))"
done

# If no target configured, print manual instructions
if [ -z "$TARGET" ]; then
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

echo ""
echo "Target: $TARGET"

# Determine transfer method
if [[ "$TARGET" == *:* ]]; then
    # SSH/rsync path (contains colon, e.g. user@host:/path)
    echo "Transfer method: rsync over SSH"
    echo ""

    for f in "${MOD_FILES[@]}"; do
        echo "Syncing $(basename "$f")..."
        rsync -avz --progress "$f" "$TARGET/"
    done
else
    # Local path (mounted drive, shared folder)
    echo "Transfer method: local copy"

    if [ ! -d "$TARGET" ]; then
        echo "ERROR: Target directory does not exist: $TARGET"
        echo "Make sure the drive is mounted or the path is correct."
        exit 1
    fi

    for f in "${MOD_FILES[@]}"; do
        echo "Copying $(basename "$f")..."
        cp -v "$f" "$TARGET/"
    done
fi

echo ""
echo "Done. Launch SpaghettiKart to load the mods."
