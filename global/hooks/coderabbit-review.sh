#!/usr/bin/env bash
# Hook: coderabbit-review
# Event: PreToolUse
# Tools: Bash
# Purpose: Add CodeRabbit review context when creating PRs

set -euo pipefail

# Get script directory and source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Initialize hook (optional category - doesn't block workflow if fails)
init_hook "coderabbit-review" "optional"

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

# Check if CodeRabbit is explicitly skipped
if bypass_enabled "SKIP_CODERABBIT"; then
    log_info "Bypass enabled: SKIP_CODERABBIT=1"
    finalize_hook 0
    exit 0
fi

# Check for inline bypass in command
if echo "$COMMAND" | grep -qE '^SKIP_CODERABBIT=1\s'; then
    log_info "Bypass enabled: SKIP_CODERABBIT=1 (inline in command)"
    finalize_hook 0
    exit 0
fi

log_debug "Checking command: $COMMAND"

# ============================================================================
# PR CREATION DETECTION
# ============================================================================

# Check if this is a PR-related command
IS_PR_COMMAND=false

if echo "$COMMAND" | grep -qE '\bgt\s+submit\b'; then
    IS_PR_COMMAND=true
    log_info "Detected gt submit command"
fi

if echo "$COMMAND" | grep -qE '\bgh\s+pr\s+create\b'; then
    IS_PR_COMMAND=true
    log_info "Detected gh pr create command"
fi

# ============================================================================
# ADD CODERABBIT CONTEXT
# ============================================================================

if [[ "$IS_PR_COMMAND" == true ]]; then
    # Check if CodeRabbit config exists in repo
    CODERABBIT_CONFIG=""
    if [[ -f ".coderabbit.yaml" ]]; then
        CODERABBIT_CONFIG="CodeRabbit configuration found at .coderabbit.yaml"
    elif [[ -f ".coderabbit.yml" ]]; then
        CODERABBIT_CONFIG="CodeRabbit configuration found at .coderabbit.yml"
    else
        CODERABBIT_CONFIG="No .coderabbit.yaml found - using default settings"
    fi

    # Provide context about CodeRabbit review
    CONTEXT="## CodeRabbit AI Review

After this PR is created, CodeRabbit will automatically review it.

**What to expect:**
- Automated review within ~2 minutes
- Comments on code quality, bugs, and security
- Suggestions for improvements

**Commands you can use in PR comments:**
- \`@coderabbitai full review\` - Trigger full review
- \`@coderabbitai summary\` - Get summary only
- \`@coderabbitai ignore <path>\` - Ignore specific files

**Addressing feedback:**
1. Fix issues CodeRabbit finds
2. Push additional commits
3. Reply to comments explaining decisions
4. Request human review after addressing AI feedback

$CODERABBIT_CONFIG

**To skip CodeRabbit context:** Set SKIP_CODERABBIT=1"

    output_context "$CONTEXT"
    log_info "Added CodeRabbit review context"
fi

# ============================================================================
# FINALIZE
# ============================================================================

finalize_hook 0
