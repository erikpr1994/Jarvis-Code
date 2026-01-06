#!/usr/bin/env bash
# Hook: require-isolation
# Event: PreToolUse
# Tools: Edit, Write, NotebookEdit
# Purpose: Enforce worktree/Conductor isolation - block modifications on main/master branch

set -euo pipefail

# Get script directory and source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Initialize hook
init_hook "require-isolation"

# ============================================================================
# BYPASS CONDITIONS
# ============================================================================

# Check for explicit bypass via environment variable
if bypass_enabled "CLAUDE_ALLOW_MAIN_MODIFICATIONS"; then
    log_info "Bypass enabled: CLAUDE_ALLOW_MAIN_MODIFICATIONS=1"
    finalize_hook 0
    exit 0
fi

# Check if running in Conductor session (has its own isolation)
if is_conductor_session; then
    log_info "Bypass enabled: Running in Conductor session"
    finalize_hook 0
    exit 0
fi

# Check if we're in a git worktree (isolation already active)
if is_worktree; then
    log_info "Bypass enabled: Inside git worktree (isolation active)"
    finalize_hook 0
    exit 0
fi

# ============================================================================
# ISOLATION ENFORCEMENT
# ============================================================================

# Read input from stdin
INPUT=$(cat)

# Parse tool information
TOOL_NAME=$(parse_tool_name "$INPUT")
FILE_PATH=$(parse_file_path "$INPUT")

log_debug "Tool: $TOOL_NAME, File: $FILE_PATH"

# Only check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_info "Not in a git repository, allowing modification"
    finalize_hook 0
    exit 0
fi

# Check if we're on main/master branch
if is_main_branch; then
    local_branch=$(get_current_branch)

    log_warn "Blocked modification on $local_branch branch: $FILE_PATH"

    # Output block decision with helpful message
    cat << EOF
{
  "decision": "block",
  "reason": "ISOLATION REQUIRED: You are on the '$local_branch' branch. Direct modifications to main/master are not allowed.\n\nTo proceed, either:\n1. Create a git worktree: git worktree add ../feature-branch -b feature-name\n2. Create a new branch: git checkout -b feature-name\n3. Use Conductor for isolated sessions\n4. Set CLAUDE_ALLOW_MAIN_MODIFICATIONS=1 for emergency fixes\n\nThis policy helps prevent accidental changes to the main branch."
}
EOF
    finalize_hook 1
    exit 0
fi

# Not on main branch, allow modification
log_info "Allowing modification on branch: $(get_current_branch)"
finalize_hook 0
