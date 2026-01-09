#!/usr/bin/env bash
# Hook: require-isolation
# Event: PreToolUse
# Tools: Edit, Write, NotebookEdit
# Purpose: Enforce worktree/Conductor isolation - block modifications to project files outside worktree
# Note: Only applies to files INSIDE the current git project. Files outside (e.g., ~/.config) are allowed.

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

# Get the git repository root and resolve symlinks (macOS /tmp -> /private/tmp)
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [[ -z "$GIT_ROOT" ]]; then
    log_info "Could not determine git root, allowing modification"
    finalize_hook 0
    exit 0
fi
# Resolve symlinks in git root (handles macOS /tmp -> /private/tmp)
if command -v realpath &>/dev/null; then
    GIT_ROOT=$(realpath "$GIT_ROOT" 2>/dev/null) || true
elif command -v grealpath &>/dev/null; then
    GIT_ROOT=$(grealpath "$GIT_ROOT" 2>/dev/null) || true
else
    # Fallback: use cd/pwd to resolve symlinks
    GIT_ROOT=$(cd "$GIT_ROOT" 2>/dev/null && pwd -P) || true
fi

# Resolve the file path to absolute path for comparison
# Handle ~ expansion and relative paths
RESOLVED_FILE_PATH="$FILE_PATH"
if [[ "$FILE_PATH" == "~"* ]]; then
    RESOLVED_FILE_PATH="${FILE_PATH/#\~/$HOME}"
fi
# If path is relative, make it absolute from current directory
if [[ "$RESOLVED_FILE_PATH" != /* ]]; then
    RESOLVED_FILE_PATH="$(pwd)/$RESOLVED_FILE_PATH"
fi
# Normalize the path (resolve .. and .) and resolve symlinks
if [[ -e "$(dirname "$RESOLVED_FILE_PATH")" ]]; then
    RESOLVED_FILE_PATH=$(cd "$(dirname "$RESOLVED_FILE_PATH")" 2>/dev/null && pwd -P)/$(basename "$RESOLVED_FILE_PATH") || RESOLVED_FILE_PATH="$FILE_PATH"
else
    # Parent directory doesn't exist yet (new file) - just normalize what we can
    PARENT_DIR=$(dirname "$RESOLVED_FILE_PATH")
    # Try to resolve the deepest existing ancestor
    while [[ ! -e "$PARENT_DIR" ]] && [[ "$PARENT_DIR" != "/" ]]; do
        PARENT_DIR=$(dirname "$PARENT_DIR")
    done
    if [[ -e "$PARENT_DIR" ]]; then
        RESOLVED_PARENT=$(cd "$PARENT_DIR" 2>/dev/null && pwd -P) || RESOLVED_PARENT="$PARENT_DIR"
        # Reconstruct the path with resolved parent
        REMAINING_PATH="${RESOLVED_FILE_PATH#$PARENT_DIR}"
        RESOLVED_FILE_PATH="${RESOLVED_PARENT}${REMAINING_PATH}"
    fi
fi

log_debug "Git root: $GIT_ROOT"
log_debug "Resolved file path: $RESOLVED_FILE_PATH"

# Check if the file is inside the git repository
# If the file is outside the project, allow modification (not subject to project isolation)
if [[ "$RESOLVED_FILE_PATH" != "$GIT_ROOT"* ]]; then
    log_info "File is outside project ($GIT_ROOT), allowing modification: $RESOLVED_FILE_PATH"
    finalize_hook 0
    exit 0
fi

# Check if the file is inside a worktree directory (allows editing from main CWD)
# This handles the case where Claude runs from main project but edits files in .worktrees/
if [[ "$RESOLVED_FILE_PATH" == *"/.worktrees/"* ]]; then
    log_info "File is inside a worktree directory, allowing modification: $RESOLVED_FILE_PATH"
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
