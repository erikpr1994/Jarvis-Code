#!/usr/bin/env bash
# Hook: gh-checks-watch
# Event: PreToolUse
# Tools: Bash
# Purpose: Block inefficient sleep polling for gh pr checks - require --watch flag
# Blocks: sleep X && gh pr checks, polling loops

set -euo pipefail

# Get script directory and source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Initialize hook
init_hook "gh-checks-watch"

# ============================================================================
# COMMAND DETECTION
# ============================================================================

# Read input from stdin
INPUT=$(cat)

# Parse command from Bash tool input
COMMAND=$(parse_command "$INPUT")

# ============================================================================
# BYPASS CONDITIONS
# ============================================================================

# Check for explicit bypass via environment variable
if bypass_enabled "CLAUDE_ALLOW_SLEEP_POLLING"; then
    log_info "Bypass enabled: CLAUDE_ALLOW_SLEEP_POLLING=1"
    finalize_hook 0
    exit 0
fi

# Check for inline bypass in command
if echo "$COMMAND" | grep -qE '^CLAUDE_ALLOW_SLEEP_POLLING=1\s'; then
    log_info "Bypass enabled: CLAUDE_ALLOW_SLEEP_POLLING=1 (inline in command)"
    finalize_hook 0
    exit 0
fi

log_debug "Checking command: $COMMAND"

# ============================================================================
# BLOCKED COMMANDS
# ============================================================================

# Check for sleep + gh pr checks pattern
if echo "$COMMAND" | grep -qE 'sleep\s+[0-9]+\s*(&&|;|\|)\s*gh\s+(pr\s+)?checks'; then
    log_warn "Blocked inefficient sleep polling for gh pr checks"
    cat << 'EOF'
{
  "decision": "block",
  "reason": "INEFFICIENT POLLING BLOCKED: Use --watch instead of sleep polling.\n\nInstead of:\n  sleep 60 && gh pr checks 123\n\nUse:\n  gh pr checks 123 --watch\n\nThe --watch flag automatically polls and exits when checks complete.\nThis is more efficient and reduces token usage.\n\nBypass: CLAUDE_ALLOW_SLEEP_POLLING=1"
}
EOF
    finalize_hook 1
    exit 0
fi

# Check for gh pr checks in a while/until loop with sleep
if echo "$COMMAND" | grep -qE '(while|until).*gh\s+(pr\s+)?checks.*sleep'; then
    log_warn "Blocked inefficient polling loop for gh pr checks"
    cat << 'EOF'
{
  "decision": "block",
  "reason": "INEFFICIENT POLLING BLOCKED: Use --watch instead of manual polling loop.\n\nInstead of:\n  while ! gh pr checks 123; do sleep 30; done\n\nUse:\n  gh pr checks 123 --watch\n\nThe --watch flag handles polling automatically.\n\nBypass: CLAUDE_ALLOW_SLEEP_POLLING=1"
}
EOF
    finalize_hook 1
    exit 0
fi

# Check for sleep followed by gh checks (reverse order check)
if echo "$COMMAND" | grep -qE 'gh\s+(pr\s+)?checks.*sleep\s+[0-9]+'; then
    log_warn "Blocked inefficient polling pattern for gh pr checks"
    cat << 'EOF'
{
  "decision": "block",
  "reason": "INEFFICIENT POLLING BLOCKED: Use --watch instead of sleep polling.\n\nUse:\n  gh pr checks 123 --watch\n\nThe --watch flag automatically polls and exits when checks complete.\n\nBypass: CLAUDE_ALLOW_SLEEP_POLLING=1"
}
EOF
    finalize_hook 1
    exit 0
fi

# ============================================================================
# ALLOW COMMAND
# ============================================================================

log_debug "Command allowed - no inefficient polling detected"
finalize_hook 0
