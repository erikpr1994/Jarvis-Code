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
JARVIS_LOG_DIR="${JARVIS_LOG_DIR:-${HOME}/.jarvis/logs}"
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
    local git_dir
    git_dir=$(git rev-parse --git-dir 2>/dev/null || echo "")
    [[ -f "$git_dir" ]]  # Worktrees have a file, not directory
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
# INITIALIZATION
# ============================================================================

# Initialize hook (call at beginning of each hook script)
init_hook() {
    local hook_name="$1"
    export HOOK_NAME="$hook_name"
    log_info "Hook started"
}

# Finalize hook (call at end of each hook script)
finalize_hook() {
    local exit_code="${1:-0}"
    log_info "Hook completed with exit code: $exit_code"
}
