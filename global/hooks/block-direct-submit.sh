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

# ============================================================================
# COMMAND DETECTION
# ============================================================================

# Read input from stdin
INPUT=$(cat)

# Parse command from Bash tool input
COMMAND=$(parse_command "$INPUT")

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
  "reason": "DIRECT SUBMIT BLOCKED: Use the 'submit-pr' skill instead of running 'gt submit' directly.\n\nThe submit-pr skill provides:\n- Automated code review with CodeRabbit\n- Pre-submission validation checks\n- Consistent PR formatting and templates\n- Integration with your team's workflow\n\nTo submit your PR properly:\n1. Invoke the submit-pr skill\n2. Follow the guided submission process\n\nOr set CLAUDE_ALLOW_DIRECT_SUBMIT=1 to bypass this check."
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
  "reason": "DIRECT PR CREATION BLOCKED: Use the 'submit-pr' skill instead of running 'gh pr create' directly.\n\nThe submit-pr skill provides:\n- Automated code review with CodeRabbit\n- Pre-submission validation checks\n- Consistent PR formatting and templates\n- Integration with your team's workflow\n\nTo submit your PR properly:\n1. Invoke the submit-pr skill\n2. Follow the guided submission process\n\nOr set CLAUDE_ALLOW_DIRECT_SUBMIT=1 to bypass this check."
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
  "reason": "DIRECT PR CREATION BLOCKED: Use the 'submit-pr' skill instead of running 'hub pull-request' directly.\n\nThe submit-pr skill provides:\n- Automated code review with CodeRabbit\n- Pre-submission validation checks\n- Consistent PR formatting and templates\n- Integration with your team's workflow\n\nTo submit your PR properly:\n1. Invoke the submit-pr skill\n2. Follow the guided submission process\n\nOr set CLAUDE_ALLOW_DIRECT_SUBMIT=1 to bypass this check."
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
