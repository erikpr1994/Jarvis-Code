#!/usr/bin/env bash
# Jarvis Hook Library - Shared Utilities
# Purpose: Common functions for all hook scripts

set -euo pipefail

# ============================================================================
# LOGGING
# ============================================================================

# Log levels
LOG_DEBUG=0
LOG_INFO=1
LOG_WARN=2
LOG_ERROR=3

# Default log level (can be overridden by environment)
JARVIS_LOG_LEVEL="${JARVIS_LOG_LEVEL:-$LOG_INFO}"

# Log directory
JARVIS_LOG_DIR="${JARVIS_LOG_DIR:-${CLAUDE_DIR:-$HOME/.claude}/logs}"
mkdir -p "$JARVIS_LOG_DIR" 2>/dev/null || true

# Get current timestamp
_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Internal logging function
_log() {
    local level="$1"
    local level_name="$2"
    local message="$3"
    local hook_name="${HOOK_NAME:-unknown}"

    if [[ "$level" -ge "$JARVIS_LOG_LEVEL" ]]; then
        echo "[$(_timestamp)] [$level_name] [$hook_name] $message" >> "${JARVIS_LOG_DIR}/hooks.log"
    fi
}

log_debug() { _log $LOG_DEBUG "DEBUG" "$1"; }
log_info()  { _log $LOG_INFO  "INFO"  "$1"; }
log_warn()  { _log $LOG_WARN  "WARN"  "$1"; }
log_error() { _log $LOG_ERROR "ERROR" "$1"; }

# ============================================================================
# JSON UTILITIES (No jq dependency)
# ============================================================================

# Escape string for JSON output
escape_for_json() {
    local input="$1"
    local output=""
    local i char
    for (( i=0; i<${#input}; i++ )); do
        char="${input:$i:1}"
        case "$char" in
            \\) output+='\\';;
            '"') output+='\"';;
            $'\n') output+='\n';;
            $'\r') output+='\r';;
            $'\t') output+='\t';;
            *) output+="$char";;
        esac
    done
    printf '%s' "$output"
}

# Parse tool_name from JSON input (for PreToolUse hooks)
parse_tool_name() {
    echo "$1" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | \
        sed 's/.*: *"//' | sed 's/"$//' || echo ""
}

# Parse file_path from JSON input
parse_file_path() {
    echo "$1" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | \
        sed 's/.*: *"//' | sed 's/"$//' || echo ""
}

# Parse command from JSON input (for Bash tool)
parse_command() {
    echo "$1" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | \
        sed 's/.*: *"//' | sed 's/"$//' || echo ""
}

# Parse prompt from JSON input (for UserPromptSubmit hooks)
parse_prompt() {
    echo "$1" | grep -o '"prompt"[[:space:]]*:[[:space:]]*"[^"]*"' | \
        sed 's/.*: *"//' | sed 's/"$//' || echo ""
}

# Parse session_id from JSON input
parse_session_id() {
    echo "$1" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | \
        sed 's/.*: *"//' | sed 's/"$//' || echo ""
}

# ============================================================================
# OUTPUT HELPERS
# ============================================================================

# Output a block decision (prevents tool execution)
output_block() {
    local reason="$1"
    cat << EOF
{"decision": "block", "reason": "$reason"}
EOF
}

# Output additional context to inject
output_context() {
    local context="$1"
    local escaped_context
    escaped_context=$(escape_for_json "$context")
    cat << EOF
{
  "hookSpecificOutput": {
    "additionalContext": "${escaped_context}"
  }
}
EOF
}

# Output with hook event name
output_session_context() {
    local context="$1"
    local escaped_context
    escaped_context=$(escape_for_json "$context")
    cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "${escaped_context}"
  }
}
EOF
}

# ============================================================================
# PATH UTILITIES
# ============================================================================

# Get Jarvis root directory (relative to this library)
get_jarvis_root() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "$(cd "${script_dir}/../../../" && pwd)"
}

# Get global hooks directory
get_hooks_dir() {
    local jarvis_root
    jarvis_root=$(get_jarvis_root)
    echo "${jarvis_root}/global/hooks"
}

# Get global skills directory
get_skills_dir() {
    local jarvis_root
    jarvis_root=$(get_jarvis_root)
    echo "${jarvis_root}/global/skills"
}

# ============================================================================
# PREFERENCES
# ============================================================================

PREFERENCES_FILE="${HOME}/.claude/config/preferences.json"

# Check if a hook is enabled in preferences
is_hook_enabled() {
    local hook_name="$1"
    local default="${2:-true}"

    if [[ ! -f "$PREFERENCES_FILE" ]]; then
        # No preferences file, use default
        [[ "$default" == "true" ]]
        return
    fi

    local enabled
    enabled=$(jq -r ".hooks.${hook_name}.enabled // ${default}" "$PREFERENCES_FILE" 2>/dev/null || echo "$default")
    [[ "$enabled" == "true" ]]
}

# Check if a hook is bypassable
is_hook_bypassable() {
    local hook_name="$1"
    local default="${2:-true}"

    if [[ ! -f "$PREFERENCES_FILE" ]]; then
        [[ "$default" == "true" ]]
        return
    fi

    local bypassable
    bypassable=$(jq -r ".hooks.${hook_name}.bypassable // ${default}" "$PREFERENCES_FILE" 2>/dev/null || echo "$default")
    [[ "$bypassable" == "true" ]]
}

# Check if a rule is enabled
is_rule_enabled() {
    local rule_name="$1"
    local default="${2:-false}"

    if [[ ! -f "$PREFERENCES_FILE" ]]; then
        [[ "$default" == "true" ]]
        return
    fi

    local enabled
    enabled=$(jq -r ".rules.${rule_name}.enabled // ${default}" "$PREFERENCES_FILE" 2>/dev/null || echo "$default")
    [[ "$enabled" == "true" ]]
}

# Get rule severity (error, warning, info)
get_rule_severity() {
    local rule_name="$1"
    local default="${2:-warning}"

    if [[ ! -f "$PREFERENCES_FILE" ]]; then
        echo "$default"
        return
    fi

    jq -r ".rules.${rule_name}.severity // \"${default}\"" "$PREFERENCES_FILE" 2>/dev/null || echo "$default"
}

# ============================================================================
# GIT UTILITIES
# ============================================================================

# Check if we're on the main/master branch
is_main_branch() {
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    [[ "$branch" == "main" || "$branch" == "master" ]]
}

# Check if we're in a git worktree
is_worktree() {
    # Method 1: Check if .git is a file (worktrees have a .git file, not directory)
    if [[ -f ".git" ]]; then
        return 0
    fi

    # Method 2: Check if git-dir path contains /worktrees/
    local git_dir
    git_dir=$(git rev-parse --git-dir 2>/dev/null || echo "")
    if [[ "$git_dir" == *"/worktrees/"* ]]; then
        return 0
    fi

    return 1
}

# Get current branch name
get_current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null || echo ""
}

# Check if there are uncommitted changes
has_uncommitted_changes() {
    [[ -n "$(git status --porcelain 2>/dev/null)" ]]
}

# ============================================================================
# FILE UTILITIES
# ============================================================================

# Read file contents or return empty string
read_file_safe() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        cat "$file_path" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Check if file exists and is readable
file_readable() {
    [[ -f "$1" && -r "$1" ]]
}

# Find most recent session file (within last N minutes)
find_recent_session() {
    local minutes="${1:-240}"  # Default 4 hours
    local session_dir=".claude/tasks"

    if [[ -d "$session_dir" ]]; then
        find "$session_dir" -name "session-*.md" -mmin "-$minutes" 2>/dev/null | head -1 || echo ""
    else
        echo ""
    fi
}

# ============================================================================
# ENVIRONMENT CHECKS
# ============================================================================

# Check if running in Conductor session
is_conductor_session() {
    [[ -n "${CONDUCTOR_ROOT_PATH:-}" ]]
}

# Check for specific bypass flags
bypass_enabled() {
    local bypass_var="$1"
    [[ "${!bypass_var:-0}" == "1" ]]
}

# ============================================================================
# ERROR RECOVERY INTEGRATION
# ============================================================================

# Source error-handler if available
ERROR_HANDLER_PATH="${HOME}/.claude/lib/error-handler.sh"
ERROR_HANDLER_LOADED=false

if [[ -f "$ERROR_HANDLER_PATH" ]]; then
    # shellcheck source=/dev/null
    source "$ERROR_HANDLER_PATH" 2>/dev/null && ERROR_HANDLER_LOADED=true
fi

# Also check local installation path if not loaded yet
if [[ "$ERROR_HANDLER_LOADED" != true ]]; then
    COMMON_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
    LOCAL_ERROR_HANDLER="${COMMON_LIB_DIR}/../../lib/error-handler.sh"
    if [[ -f "$LOCAL_ERROR_HANDLER" ]]; then
        # shellcheck source=/dev/null
        source "$LOCAL_ERROR_HANDLER" 2>/dev/null && ERROR_HANDLER_LOADED=true
    fi
fi

# Check if error handler is available
has_error_handler() {
    [[ "$ERROR_HANDLER_LOADED" == true ]]
}

# Initialize error recovery system for this hook
init_error_recovery() {
    if has_error_handler; then
        init_error_system 2>/dev/null || true
    fi
}

# Execute with error recovery (L1: retry, then L2: alternatives, then fail gracefully)
execute_with_recovery() {
    local cmd="$1"
    local fallback="${2:-}"
    local max_retries="${3:-2}"

    if has_error_handler; then
        # Try with backoff first
        if retry_with_backoff "$cmd" "$max_retries" 1 5 2 2>/dev/null; then
            return 0
        fi

        # If retry failed and fallback provided, try fallback
        if [[ -n "$fallback" ]]; then
            log_warn "Primary command failed, trying fallback"
            if eval "$fallback" 2>/dev/null; then
                return 0
            fi
        fi

        # Log the failure
        log_error "Command failed after recovery attempts: $cmd"
        return 1
    else
        # No error handler - just run directly
        if eval "$cmd" 2>/dev/null; then
            return 0
        elif [[ -n "$fallback" ]]; then
            eval "$fallback" 2>/dev/null
        else
            return 1
        fi
    fi
}

# Check if hook should run based on degradation level
should_hook_run() {
    local hook_category="${1:-essential}"  # essential, standard, optional

    if ! has_error_handler; then
        return 0  # No handler = always run
    fi

    # Load current degradation level
    load_health_state 2>/dev/null || true

    case "$CURRENT_DEGRADATION_LEVEL" in
        0)  # Full system - all hooks run
            return 0
            ;;
        1)  # Reduced - only essential and standard
            [[ "$hook_category" != "optional" ]]
            ;;
        2)  # Minimal - only essential
            [[ "$hook_category" == "essential" ]]
            ;;
        3)  # Emergency - no hooks
            return 1
            ;;
        *)  # Unknown - run
            return 0
            ;;
    esac
}

# Report hook failure to error system
report_hook_failure() {
    local error_type="${1:-unknown}"
    local details="${2:-}"

    if has_error_handler; then
        log_error "$error_type" "$HOOK_NAME" "$details" "logged"
        $1=$(($1 + 1)) || true
        save_health_state 2>/dev/null || true
        check_degradation_triggers 2>/dev/null || true
    fi
}

# Safe execution wrapper - runs command with timeout and error handling
safe_execute() {
    local cmd="$1"
    local timeout_secs="${2:-5}"
    local description="${3:-command}"

    log_debug "Safe execute: $description (timeout: ${timeout_secs}s)"

    local output
    local exit_code=0

    # Use timeout if available
    if command -v timeout &>/dev/null; then
        output=$(timeout "$timeout_secs" bash -c "$cmd" 2>&1) || exit_code=$?
    elif command -v gtimeout &>/dev/null; then
        output=$(gtimeout "$timeout_secs" bash -c "$cmd" 2>&1) || exit_code=$?
    else
        # No timeout command - run directly
        output=$(bash -c "$cmd" 2>&1) || exit_code=$?
    fi

    if [[ $exit_code -eq 124 ]]; then
        log_warn "Command timed out after ${timeout_secs}s: $description"
        report_hook_failure "timeout" "$description"
        return 1
    elif [[ $exit_code -ne 0 ]]; then
        log_warn "Command failed (exit $exit_code): $description"
        report_hook_failure "execution_failed" "$description: exit $exit_code"
        return 1
    fi

    echo "$output"
    return 0
}

# Graceful degradation wrapper - skip non-essential work if system under stress
run_if_healthy() {
    local cmd="$1"
    local category="${2:-standard}"

    if should_hook_run "$category"; then
        eval "$cmd"
    else
        log_debug "Skipped due to degradation level: $cmd"
        return 0
    fi
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# Initialize hook (call at beginning of each hook script)
init_hook() {
    local hook_name="$1"
    local hook_category="${2:-standard}"  # essential, standard, optional
    export HOOK_NAME="$hook_name"
    export HOOK_CATEGORY="$hook_category"

    log_info "Hook started"

    # Initialize error recovery
    init_error_recovery

    # Check if we should run based on degradation level
    if ! should_hook_run "$hook_category"; then
        log_info "Hook skipped due to degradation level"
        exit 0
    fi
}

# Finalize hook (call at end of each hook script)
finalize_hook() {
    local exit_code="${1:-0}"
    log_info "Hook completed with exit code: $exit_code"

    # Report success to reset failure counters if appropriate
    if [[ $exit_code -eq 0 ]] && has_error_handler; then
        # Could implement success tracking here
        true
    fi
}
