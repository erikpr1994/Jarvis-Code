#!/usr/bin/env bash
# Hook: block-direct-submit
# Event: PreToolUse
# Tools: Bash
# Purpose: Block direct `gt submit` or `gh pr create` commands - require submit-pr skill

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
# Matches: gt submit, gh pr create, and variations

# Check for Graphite submit command
if echo "$COMMAND" | grep -qE '\bgt\s+submit\b'; then
    log_warn "Blocked direct gt submit command"
    cat << EOF
{
  "decision": "block",
  "reason": "DIRECT SUBMIT BLOCKED: Use the 'submit-pr' skill instead.\n\nTO FIX: Use the Skill tool with skill: \"submit-pr\" to load the PR submission workflow.\n\nThe submit-pr skill provides:\n- Pre-submission checklist (tests, lint, typecheck)\n- PR description template\n- CodeRabbit integration\n- Review request process\n\nDO NOT just add the bypass variable - actually invoke the skill to follow the proper process."
}
EOF
    finalize_hook 1
    exit 0
fi

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

# ============================================================================
# ALLOW COMMAND
# ============================================================================

log_debug "Command allowed - no PR submission detected"
finalize_hook 0
