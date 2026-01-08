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
# INPUT PARSING (early, needed for bypass checks)
# ============================================================================

# Read input from stdin
INPUT=$(cat)

# Parse tool information
TOOL_NAME=$(parse_tool_name "$INPUT")
FILE_PATH=$(parse_file_path "$INPUT")

# ============================================================================
# BYPASS CONDITIONS
# ============================================================================

# Check if this hook is enabled in preferences (default: disabled)
if ! is_hook_enabled "requireIsolation" "false"; then
    log_info "Hook disabled in preferences"
    finalize_hook 0
    exit 0
fi

# Check for explicit bypass via environment variable
if bypass_enabled "CLAUDE_ALLOW_MAIN_MODIFICATIONS"; then
    log_info "Bypass enabled: CLAUDE_ALLOW_MAIN_MODIFICATIONS=1"
    finalize_hook 0
    exit 0
fi

# Check for inline bypass in command (for Bash tool calls)
# Handles: CLAUDE_ALLOW_MAIN_MODIFICATIONS=1 some_command
if [[ "$TOOL_NAME" == "Bash" ]]; then
    COMMAND=$(parse_command "$INPUT")
    if echo "$COMMAND" | grep -qE '^CLAUDE_ALLOW_MAIN_MODIFICATIONS=1\s'; then
        log_info "Bypass enabled: CLAUDE_ALLOW_MAIN_MODIFICATIONS=1 (inline in command)"
        finalize_hook 0
        exit 0
    fi
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

log_debug "Tool: $TOOL_NAME, File: $FILE_PATH"

# Only check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_info "Not in a git repository, allowing modification"
    finalize_hook 0
    exit 0
fi

# STRICT MODE: Always require worktree, regardless of branch
# The main project folder should NEVER be modified directly
local_branch=$(get_current_branch)

log_warn "Blocked modification outside worktree: $FILE_PATH (branch: $local_branch)"

# Output block decision with helpful message
cat << EOF
{
  "decision": "block",
  "reason": "WORKTREE REQUIRED: Direct modifications to the main project folder are not allowed.\n\nYou are currently in: $(pwd)\nBranch: $local_branch\n\nTo proceed:\n1. Create a git worktree:\n   git worktree add .worktrees/feature-name -b feature/feature-name\n   cd .worktrees/feature-name\n\n2. Or use Conductor for isolated sessions\n\n3. For emergency fixes only:\n   CLAUDE_ALLOW_MAIN_MODIFICATIONS=1\n\nThis policy ensures all work happens in isolated workspaces."
}
EOF
finalize_hook 1
exit 0
