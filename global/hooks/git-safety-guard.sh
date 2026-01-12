#!/usr/bin/env bash
# Hook: git-safety-guard
# Event: PreToolUse
# Tools: Bash
# Purpose: Block destructive git and filesystem commands
# Based on: https://github.com/Dicklesworthstone/misc_coding_agent_tips_and_scripts

set -euo pipefail

# Get script directory and source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Initialize hook
init_hook "git-safety-guard"

# ============================================================================
# BYPASS CONDITIONS
# ============================================================================

# Check if this hook is enabled in preferences (default: enabled)
if ! is_hook_enabled "gitSafetyGuard" "true"; then
    log_info "Hook disabled in preferences"
    finalize_hook 0
    exit 0
fi

# ============================================================================
# COMMAND DETECTION (early, needed for inline bypass checks)
# ============================================================================

# Read input from stdin
INPUT=$(cat)

# Parse command from Bash tool input
COMMAND=$(parse_command "$INPUT")

if [[ -z "$COMMAND" ]]; then
    log_debug "No command found in input"
    finalize_hook 0
    exit 0
fi

log_debug "Checking command: $COMMAND"

# ============================================================================
# BYPASS FLAGS (set flags instead of early exit - each check uses its own flag)
# ============================================================================

BYPASS_DESTRUCTIVE=0
BYPASS_MAIN_PUSH=0
BYPASS_MAIN_MERGE=0
BYPASS_BASH_WRITE=0

# Check for explicit bypass via environment variable (global - skips all)
if bypass_enabled "CLAUDE_ALLOW_DESTRUCTIVE"; then
    log_info "Bypass enabled: CLAUDE_ALLOW_DESTRUCTIVE=1 (env)"
    BYPASS_DESTRUCTIVE=1
fi

# Check for inline bypass variables - each sets ONLY its specific flag
if echo "$COMMAND" | grep -qE "^CLAUDE_ALLOW_DESTRUCTIVE=1[[:space:]]"; then
    log_info "Bypass enabled: CLAUDE_ALLOW_DESTRUCTIVE=1 (inline)"
    BYPASS_DESTRUCTIVE=1
fi

if echo "$COMMAND" | grep -qE "^JARVIS_ALLOW_MAIN_PUSH=1[[:space:]]"; then
    log_info "Bypass enabled: JARVIS_ALLOW_MAIN_PUSH=1 (inline)"
    BYPASS_MAIN_PUSH=1
fi

if echo "$COMMAND" | grep -qE "^JARVIS_ALLOW_MAIN_MERGE=1[[:space:]]"; then
    log_info "Bypass enabled: JARVIS_ALLOW_MAIN_MERGE=1 (inline)"
    BYPASS_MAIN_MERGE=1
fi

if echo "$COMMAND" | grep -qE "^CLAUDE_ALLOW_BASH_WRITE=1[[:space:]]"; then
    log_info "Bypass enabled: CLAUDE_ALLOW_BASH_WRITE=1 (inline)"
    BYPASS_BASH_WRITE=1
fi

# Check env vars for specific bypasses too
if bypass_enabled "JARVIS_ALLOW_MAIN_PUSH"; then
    BYPASS_MAIN_PUSH=1
fi

if bypass_enabled "JARVIS_ALLOW_MAIN_MERGE"; then
    BYPASS_MAIN_MERGE=1
fi

if bypass_enabled "CLAUDE_ALLOW_BASH_WRITE"; then
    BYPASS_BASH_WRITE=1
fi

# Global bypass (all checks) - only CLAUDE_ALLOW_DESTRUCTIVE via env does this
if [[ "$BYPASS_DESTRUCTIVE" == "1" ]] && bypass_enabled "CLAUDE_ALLOW_DESTRUCTIVE"; then
    log_info "Global bypass: all checks skipped"
    finalize_hook 0
    exit 0
fi

# Normalize absolute paths (e.g., /usr/bin/git -> git)
# Handle both git and rm separately for macOS compatibility
NORMALIZED_CMD="$COMMAND"
NORMALIZED_CMD=$(echo "$NORMALIZED_CMD" | sed -E 's|^/[^ ]*/s?bin/git|git|')
NORMALIZED_CMD=$(echo "$NORMALIZED_CMD" | sed -E 's|^/[^ ]*/s?bin/rm|rm|')

# ============================================================================
# SAFE PATTERNS (checked first - these are allowed)
# ============================================================================

# git checkout -b (creating new branch)
if echo "$NORMALIZED_CMD" | grep -qE 'git\s+checkout\s+-b\s+'; then
    log_debug "Allowed: git checkout -b (creating branch)"
    finalize_hook 0
    exit 0
fi

# git checkout --orphan (creating orphan branch)
if echo "$NORMALIZED_CMD" | grep -qE 'git\s+checkout\s+--orphan\s+'; then
    log_debug "Allowed: git checkout --orphan"
    finalize_hook 0
    exit 0
fi

# git restore --staged (unstaging only - safe)
if echo "$NORMALIZED_CMD" | grep -qE 'git\s+restore\s+(--staged|-S)\s+' && \
   ! echo "$NORMALIZED_CMD" | grep -qE '(--worktree|-W)'; then
    log_debug "Allowed: git restore --staged (unstaging only)"
    finalize_hook 0
    exit 0
fi

# git clean -n/--dry-run (preview mode)
if echo "$NORMALIZED_CMD" | grep -qE 'git\s+clean\s+.*(-n|--dry-run)'; then
    log_debug "Allowed: git clean dry-run"
    finalize_hook 0
    exit 0
fi

# rm -rf on temp directories
if echo "$NORMALIZED_CMD" | grep -qE 'rm\s+.*-[rRfF]+.*\s+(/tmp/|/var/tmp/|\$TMPDIR|\${TMPDIR)'; then
    log_debug "Allowed: rm -rf on temp directory"
    finalize_hook 0
    exit 0
fi

# git push --force-with-lease (safer alternative)
if echo "$NORMALIZED_CMD" | grep -qE 'git\s+push\s+.*--force-with-lease'; then
    log_debug "Allowed: git push --force-with-lease"
    finalize_hook 0
    exit 0
fi

# ============================================================================
# DESTRUCTIVE PATTERNS (block these)
# ============================================================================

block_command() {
    local reason="$1"
    log_warn "Blocked destructive command: $reason"
    cat << EOF
{
  "decision": "block",
  "reason": "DESTRUCTIVE COMMAND BLOCKED\n\nReason: $reason\n\nCommand: $COMMAND\n\nIf this operation is truly needed, ask the user to run it manually or set CLAUDE_ALLOW_DESTRUCTIVE=1"
}
EOF
    finalize_hook 1
    exit 0
}

# git checkout -- <files> (discards uncommitted changes)
if echo "$NORMALIZED_CMD" | grep -qE 'git\s+checkout\s+--\s+'; then
    block_command "git checkout -- discards uncommitted changes permanently. Use 'git stash' first."
fi

# git checkout <ref> -- <path> (overwrites working tree)
if echo "$NORMALIZED_CMD" | grep -qE 'git\s+checkout\s+[^\s]+\s+--\s+'; then
    block_command "git checkout <ref> -- <path> overwrites working tree. Use 'git stash' first."
fi

# git restore <files> (discards uncommitted changes)
if echo "$NORMALIZED_CMD" | grep -qE 'git\s+restore\s+' && \
   ! echo "$NORMALIZED_CMD" | grep -qE 'git\s+restore\s+(--staged|-S)'; then
    block_command "git restore discards uncommitted changes. Use 'git stash' or 'git diff' first."
fi

# git restore --worktree (discards changes)
if echo "$NORMALIZED_CMD" | grep -qE 'git\s+restore\s+.*(--worktree|-W)'; then
    block_command "git restore --worktree discards uncommitted changes permanently."
fi

# git reset --hard (destroys uncommitted work)
if echo "$NORMALIZED_CMD" | grep -qE 'git\s+reset\s+--hard'; then
    block_command "git reset --hard destroys uncommitted changes. Use 'git stash' first."
fi

# git reset --merge (can lose changes)
if echo "$NORMALIZED_CMD" | grep -qE 'git\s+reset\s+--merge'; then
    block_command "git reset --merge can lose uncommitted changes."
fi

# git clean -f (removes untracked files)
if echo "$NORMALIZED_CMD" | grep -qE 'git\s+clean\s+-[a-z]*f' && \
   ! echo "$NORMALIZED_CMD" | grep -qE 'git\s+clean\s+.*-n'; then
    block_command "git clean -f removes untracked files permanently. Review with 'git clean -n' first."
fi


# git push to main/master (direct push to protected branches)
# Bypass: JARVIS_ALLOW_MAIN_PUSH=1
if [[ "$BYPASS_MAIN_PUSH" != "1" ]]; then
    if echo "$NORMALIZED_CMD" | grep -qE "git\s+push\s+.*\s+(main|master)(\s|$)" || \
       echo "$NORMALIZED_CMD" | grep -qE "git\s+push\s+origin\s+(main|master)" || \
       echo "$NORMALIZED_CMD" | grep -qE "git\s+push\s+-u\s+origin\s+(main|master)"; then
        block_command "Direct push to main/master is blocked. Create a PR instead.\n\nTo bypass (emergency only): JARVIS_ALLOW_MAIN_PUSH=1 git push ..."
    fi
fi

# git merge on main/master (direct merge to protected branches)
# Bypass: JARVIS_ALLOW_MAIN_MERGE=1
if [[ "$BYPASS_MAIN_MERGE" != "1" ]]; then
    if echo "$NORMALIZED_CMD" | grep -qE 'git\s+merge\s+'; then
        # Check if we're on main/master branch
        current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
        if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
            block_command "Merging to main/master is blocked. Use /submit-pr instead.\n\nTo bypass (emergency only): JARVIS_ALLOW_MAIN_MERGE=1 git merge ..."
        fi
    fi
fi
# git push --force/-f (destroys remote history)
# Note: Allow --force-with-lease which is safer
if echo "$NORMALIZED_CMD" | grep -qE 'git\s+push\s+.*--force($|\s)' || \
   echo "$NORMALIZED_CMD" | grep -qE 'git\s+push\s+.*\s-f(\s|$)'; then
    if ! echo "$NORMALIZED_CMD" | grep -qE 'git\s+push\s+.*--force-with-lease'; then
        block_command "Force push can destroy remote history. Use --force-with-lease if necessary."
    fi
fi

# git branch -D (force delete without merge check)
if echo "$NORMALIZED_CMD" | grep -qE 'git\s+branch\s+-D\b'; then
    block_command "git branch -D force-deletes without merge check. Use -d for safety."
fi

# git stash drop/clear (permanently deletes stashed changes)
if echo "$NORMALIZED_CMD" | grep -qE 'git\s+stash\s+drop'; then
    block_command "git stash drop permanently deletes stashed changes. List stashes with 'git stash list' first."
fi

if echo "$NORMALIZED_CMD" | grep -qE 'git\s+stash\s+clear'; then
    block_command "git stash clear permanently deletes ALL stashed changes."
fi

# rm -rf on root or home paths (EXTREMELY DANGEROUS)
if echo "$NORMALIZED_CMD" | grep -qE 'rm\s+.*-[rRfF]+.*\s+[/~]' && \
   ! echo "$NORMALIZED_CMD" | grep -qE 'rm\s+.*-[rRfF]+.*\s+(/tmp/|/var/tmp/)'; then
    block_command "rm -rf on root/home paths is EXTREMELY DANGEROUS. Ask the user to run it manually."
fi

# rm -rf generic (requires approval)
if echo "$NORMALIZED_CMD" | grep -qE 'rm\s+.*-[rRfF]+'; then
    block_command "rm -rf is destructive and requires human approval. Explain what you want to delete."
fi

# Bash file write patterns - force use of Write/Edit tools
# Block: >, >>, tee (except to /dev/null and file descriptor redirects)
# Bypass: CLAUDE_ALLOW_BASH_WRITE=1
if [[ "$BYPASS_BASH_WRITE" != "1" ]]; then
    # Check for redirect operators (but allow /dev/null and file descriptor redirects like 2>&1)
    if echo "$NORMALIZED_CMD" | grep -qE ">[^>&0-9]" && \
       ! echo "$NORMALIZED_CMD" | grep -qE ">\s*/dev/null"; then
        block_command "Bash file writes are blocked. Use the Write or Edit tool instead.\n\nDetected: output redirection (>)\n\nTo bypass (if truly needed): CLAUDE_ALLOW_BASH_WRITE=1"
    fi
    # Check for append operator
    if echo "$NORMALIZED_CMD" | grep -qE ">>" && \
       ! echo "$NORMALIZED_CMD" | grep -qE ">>\s*/dev/null"; then
        block_command "Bash file writes are blocked. Use the Write or Edit tool instead.\n\nDetected: append redirection (>>)\n\nTo bypass (if truly needed): CLAUDE_ALLOW_BASH_WRITE=1"
    fi
    # Check for tee command (except to /dev/null)
    if echo "$NORMALIZED_CMD" | grep -qE "\btee\b" && \
       ! echo "$NORMALIZED_CMD" | grep -qE "tee\s+/dev/null"; then
        block_command "Bash file writes are blocked. Use the Write or Edit tool instead.\n\nDetected: tee command\n\nTo bypass (if truly needed): CLAUDE_ALLOW_BASH_WRITE=1"
    fi
fi

# ============================================================================
# ALLOW COMMAND
# ============================================================================

log_debug "Command allowed - no destructive patterns detected"
finalize_hook 0
