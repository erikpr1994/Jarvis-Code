#!/usr/bin/env bash
# Hook: block-direct-submit
# Event: PreToolUse
# Tools: Bash
# Purpose: Block direct PR submission commands and pushes to feature branches - require submit-pr skill
# Blocks: gh pr create, hub pull-request, git push to feature branches

set -euo pipefail

# Get script directory and source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Initialize hook
init_hook "block-direct-submit"

# ============================================================================
# COMMAND DETECTION (early, needed for bypass checks)
# ============================================================================

# Read input from stdin
INPUT=$(cat)

# Parse command from Bash tool input
COMMAND=$(parse_command "$INPUT")

# ============================================================================
# BYPASS CONDITIONS
# ============================================================================

# Check if submit-pr skill is active (sets this env var)
if bypass_enabled "CLAUDE_SUBMIT_PR_SKILL"; then
    log_info "Bypass enabled: CLAUDE_SUBMIT_PR_SKILL=1 (submit-pr skill active)"
    finalize_hook 0
    exit 0
fi

# Check for explicit bypass via environment variable
if bypass_enabled "CLAUDE_ALLOW_DIRECT_SUBMIT"; then
    log_info "Bypass enabled: CLAUDE_ALLOW_DIRECT_SUBMIT=1"
    finalize_hook 0
    exit 0
fi

# Check for inline bypass variables in the command string itself
# This handles cases like: CLAUDE_SUBMIT_PR_SKILL=1 gh pr create ...
# (inline vars don't set env for the hook process, only for the command)
if echo "$COMMAND" | grep -qE '^CLAUDE_SUBMIT_PR_SKILL=1\s'; then
    log_info "Bypass enabled: CLAUDE_SUBMIT_PR_SKILL=1 (inline in command)"
    finalize_hook 0
    exit 0
fi

if echo "$COMMAND" | grep -qE '^CLAUDE_ALLOW_DIRECT_SUBMIT=1\s'; then
    log_info "Bypass enabled: CLAUDE_ALLOW_DIRECT_SUBMIT=1 (inline in command)"
    finalize_hook 0
    exit 0
fi

log_debug "Checking command: $COMMAND"

# ============================================================================
# BLOCKED COMMANDS
# ============================================================================

# Pattern matching for PR submission commands
# Matches: gh pr create and variations

# Check for GitHub CLI PR creation
if echo "$COMMAND" | grep -qE '\bgh\s+pr\s+create\b'; then
    log_warn "Blocked direct gh pr create command"
    cat << EOF
{
  "decision": "block",
  "reason": "DIRECT PR CREATION BLOCKED: Use the 'submit-pr' skill instead.\n\nTO FIX: Use the Skill tool with skill: \"submit-pr\" to load the PR submission workflow.\n\nThe submit-pr skill provides:\n- Pre-submission checklist (tests, lint, typecheck)\n- PR description template\n- CodeRabbit integration\n- Review request process\n\nDO NOT just add the bypass variable - actually invoke the skill to follow the proper process."
}
EOF
    finalize_hook 1
    exit 0
fi

# Check for hub command (legacy GitHub CLI)
if echo "$COMMAND" | grep -qE '\bhub\s+pull-request\b'; then
    log_warn "Blocked direct hub pull-request command"
    cat << EOF
{
  "decision": "block",
  "reason": "DIRECT PR CREATION BLOCKED: Use the 'submit-pr' skill instead.\n\nTO FIX: Use the Skill tool with skill: \"submit-pr\" to load the PR submission workflow.\n\nThe submit-pr skill provides:\n- Pre-submission checklist (tests, lint, typecheck)\n- PR description template\n- CodeRabbit integration\n- Review request process\n\nDO NOT just add the bypass variable - actually invoke the skill to follow the proper process."
}
EOF
    finalize_hook 1
    exit 0
fi

# Check for git push to feature branches
# Matches: git push, git push -u origin <branch>, git push origin <branch>, etc.
# Allows: pushes to main, master, develop (merge pushes)
# Uses POSIX-safe patterns (no \b word boundary which fails on BSD/macOS)
if printf '%s\n' "$COMMAND" | grep -qE '(^|[[:space:]])git[[:space:]]+push([[:space:]]|$)'; then
    # Extract branch name from command if present
    PUSH_BRANCH=""

    # Priority 1: Check for HEAD:branch refspec pattern (git push origin HEAD:branch)
    if printf '%s\n' "$COMMAND" | grep -qE 'HEAD:[[:alnum:]._/-]+'; then
        PUSH_BRANCH=$(printf '%s\n' "$COMMAND" | sed -E 's/.*HEAD:([[:alnum:]._/-]+).*/\1/')
    # Priority 2: Check for "origin <branch>" pattern (allows arbitrary flags before origin)
    elif printf '%s\n' "$COMMAND" | grep -qE 'origin[[:space:]]+[[:alnum:]._/-]+'; then
        # Extract the branch name (first argument after origin that looks like a branch)
        PUSH_BRANCH=$(printf '%s\n' "$COMMAND" | sed -E 's/.*origin[[:space:]]+([[:alnum:]._/-]+).*/\1/')
    else
        # Priority 3: Implicit push (no explicit branch) - detect current branch
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            PUSH_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
            # If in detached HEAD state, branch will be "HEAD" - treat as unknown
            [[ "$PUSH_BRANCH" == "HEAD" ]] && PUSH_BRANCH=""
        fi
    fi

    log_debug "Detected push to branch: ${PUSH_BRANCH:-<unknown>}"

    # If we detected a branch name, check if it's a protected branch
    if [[ -n "$PUSH_BRANCH" ]]; then
        # Allow pushes to protected branches (main, master, develop)
        if printf '%s\n' "$PUSH_BRANCH" | grep -qE '^(main|master|develop)$'; then
            log_debug "Allowed: push to protected branch $PUSH_BRANCH"
        else
            # Block push to feature branches
            log_warn "Blocked direct git push to feature branch: $PUSH_BRANCH"
            cat << EOF
{
  "decision": "block",
  "reason": "DIRECT PUSH BLOCKED: Use the 'submit-pr' skill instead.\n\nDetected push to feature branch: $PUSH_BRANCH\n\nTO FIX: Use the Skill tool with skill: \"submit-pr\" to load the PR submission workflow.\n\nThe submit-pr skill ensures:\n- Pre-submission checklist (tests, lint, typecheck)\n- Proper PR description\n- CodeRabbit integration\n- Review request process\n\nDO NOT just add the bypass variable - actually invoke the skill to follow the proper process."
}
EOF
            finalize_hook 1
            exit 0
        fi
    else
        # Branch cannot be determined - block to prevent bypass
        log_warn "Blocked git push: unable to determine target branch"
        cat << EOF
{
  "decision": "block",
  "reason": "DIRECT PUSH BLOCKED: Cannot determine target branch.\n\nTO FIX: Either:\n1. Specify an explicit protected branch: git push origin main\n2. Use the Skill tool with skill: \"submit-pr\" for feature branches\n\nImplicit pushes to unknown branches are blocked to prevent bypassing the PR workflow."
}
EOF
        finalize_hook 1
        exit 0
    fi
fi

# ============================================================================
# ALLOW COMMAND
# ============================================================================

log_debug "Command allowed - no PR submission detected"
finalize_hook 0
