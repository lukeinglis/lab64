#!/usr/bin/env sh
# Shared structured logging library for Lab 64 toolchain.
# Source this file from any script: . "$(dirname "$0")/lib/logging.sh"
#
# Outputs structured JSON or human-readable colored messages to stderr.
# User-facing output (results, summaries) should go to stdout separately.
#
# Environment:
#   LOG_FORMAT   - "json" or "human" (default: "human")
#   LOG_LEVEL    - "DEBUG", "INFO", "WARN", "ERROR" (default: "INFO")
#   RUN_ID       - unique run identifier (auto-generated if unset)
#   SCRIPT_NAME  - calling script name (auto-detected if unset)

# Guard against double-sourcing
if [ "${_LAB64_LOGGING_LOADED:-}" = "1" ]; then
    return 0 2>/dev/null || true
fi
_LAB64_LOGGING_LOADED=1

# Auto-detect script name from caller
SCRIPT_NAME="${SCRIPT_NAME:-$(basename "$0" .sh)}"

# Generate unique run ID: epoch seconds + PID
RUN_ID="${RUN_ID:-$(date +%s)-$$}"

# Default log format and level
LOG_FORMAT="${LOG_FORMAT:-human}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"

# Level numeric values for comparison
_log_level_num() {
    case "$1" in
        DEBUG) echo 0 ;;
        INFO)  echo 1 ;;
        WARN)  echo 2 ;;
        ERROR) echo 3 ;;
        *)     echo 1 ;;
    esac
}

# Check if a message at the given level should be emitted
_log_should_emit() {
    _level_val=$(_log_level_num "$1")
    _threshold_val=$(_log_level_num "$LOG_LEVEL")
    [ "$_level_val" -ge "$_threshold_val" ]
}

# Generate ISO 8601 timestamp (POSIX-compatible)
_log_timestamp() {
    date -u '+%Y-%m-%dT%H:%M:%SZ'
}

# Escape a string for safe JSON embedding (handles quotes and backslashes)
_json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g'
}

# Core logging function — all log_* functions delegate here
_log_emit() {
    _level="$1"
    shift
    _message="$*"

    if ! _log_should_emit "$_level"; then
        return 0
    fi

    if [ "$LOG_FORMAT" = "json" ]; then
        _ts=$(_log_timestamp)
        _escaped_msg=$(_json_escape "$_message")
        _escaped_script=$(_json_escape "$SCRIPT_NAME")
        printf '{"timestamp":"%s","level":"%s","script":"%s","message":"%s","run_id":"%s"}\n' \
            "$_ts" "$_level" "$_escaped_script" "$_escaped_msg" "$RUN_ID" >&2
    else
        case "$_level" in
            DEBUG) _color="\033[36m";  _prefix="[DEBUG]" ;;
            INFO)  _color="\033[32m";  _prefix="[INFO]"  ;;
            WARN)  _color="\033[33m";  _prefix="[WARN]"  ;;
            ERROR) _color="\033[31m";  _prefix="[ERROR]" ;;
            *)     _color="\033[0m";   _prefix="[LOG]"   ;;
        esac
        _reset="\033[0m"

        if [ -t 2 ]; then
            printf '%b%s%b %s\n' "$_color" "$_prefix" "$_reset" "$_message" >&2
        else
            printf '%s %s\n' "$_prefix" "$_message" >&2
        fi
    fi
}

# Core logging function with JSON context field
_log_emit_ctx() {
    _level="$1"
    _message="$2"
    _context="$3"

    if ! _log_should_emit "$_level"; then
        return 0
    fi

    if [ "$LOG_FORMAT" = "json" ]; then
        _ts=$(_log_timestamp)
        _escaped_msg=$(_json_escape "$_message")
        _escaped_script=$(_json_escape "$SCRIPT_NAME")
        printf '{"timestamp":"%s","level":"%s","script":"%s","message":"%s","run_id":"%s","context":%s}\n' \
            "$_ts" "$_level" "$_escaped_script" "$_escaped_msg" "$RUN_ID" "$_context" >&2
    else
        _log_emit "$_level" "$_message"
    fi
}

# Public API
log_debug() { _log_emit "DEBUG" "$@"; }
log_info()  { _log_emit "INFO"  "$@"; }
log_warn()  { _log_emit "WARN"  "$@"; }
log_error() { _log_emit "ERROR" "$@"; }

log_debug_ctx() { _log_emit_ctx "DEBUG" "$1" "$2"; }
log_info_ctx()  { _log_emit_ctx "INFO"  "$1" "$2"; }
log_warn_ctx()  { _log_emit_ctx "WARN"  "$1" "$2"; }
log_error_ctx() { _log_emit_ctx "ERROR" "$1" "$2"; }

# Configure logging from common CLI flags.
# Call after parsing --json, --quiet, --verbose flags.
logging_init() {
    if [ "${JSON_OUTPUT:-0}" -eq 1 ] || [ "$LOG_FORMAT" = "json" ]; then
        LOG_FORMAT="json"
    fi
    if [ "${QUIET:-0}" -eq 1 ]; then
        LOG_LEVEL="WARN"
    fi
    if [ "${VERBOSE:-0}" -eq 1 ]; then
        LOG_LEVEL="DEBUG"
    fi
}
