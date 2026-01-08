#!/usr/bin/env bash
# Hook: enforce-quality
# Event: PreToolUse
# Tools: Bash
# Purpose: Block commits if project's quality checks fail (uses existing project tools)
#
# This hook runs BEFORE git commit and blocks if:
# - TypeScript has errors (if tsconfig.json exists)
# - Linting fails (if lint script exists)
# - Tests fail (if configured)
#
# It uses the project's existing configs - no changes to user's setup required.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

init_hook "enforce-quality"

# ============================================================================
# INPUT PARSING
# ============================================================================

INPUT=$(cat)
COMMAND=$(parse_command "$INPUT")

# Only check git commit commands
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
    finalize_hook 0
    exit 0
fi

# ============================================================================
# BYPASS CONDITIONS
# ============================================================================

if bypass_enabled "CLAUDE_SKIP_QUALITY_CHECK"; then
    log_info "Bypass enabled: CLAUDE_SKIP_QUALITY_CHECK=1"
    finalize_hook 0
    exit 0
fi

if echo "$COMMAND" | grep -qE '^CLAUDE_SKIP_QUALITY_CHECK=1\s'; then
    log_info "Bypass enabled: CLAUDE_SKIP_QUALITY_CHECK=1 (inline)"
    finalize_hook 0
    exit 0
fi

# Check if hook is enabled in preferences (default: enabled)
if ! is_hook_enabled "enforceQuality" "true"; then
    log_info "Hook disabled in preferences"
    finalize_hook 0
    exit 0
fi

log_info "Running pre-commit quality checks..."

# ============================================================================
# QUALITY CHECKS (uses project's existing tools)
# ============================================================================

ERRORS=""

# --- TypeScript Check ---
if [[ -f "tsconfig.json" ]]; then
    log_debug "Found tsconfig.json, running type check..."
    
    # Try different ways to run type check
    if npm run type-check --silent 2>/dev/null; then
        log_info "✓ TypeScript check passed"
    elif npx tsc --noEmit 2>/dev/null; then
        log_info "✓ TypeScript check passed"
    else
        TYPE_ERRORS=$(npx tsc --noEmit 2>&1 | head -20)
        ERRORS="${ERRORS}\n\n❌ TypeScript errors:\n${TYPE_ERRORS}"
    fi
fi

# --- Lint Check ---
# Check if project has a lint script
if grep -q '"lint"' package.json 2>/dev/null; then
    log_debug "Found lint script, running..."
    
    if npm run lint --silent 2>/dev/null; then
        log_info "✓ Lint check passed"
    else
        LINT_ERRORS=$(npm run lint 2>&1 | tail -20)
        ERRORS="${ERRORS}\n\n❌ Lint errors:\n${LINT_ERRORS}"
    fi
fi

# --- Test Check (optional, disabled by default - can be slow) ---
if [[ "${CLAUDE_PRE_COMMIT_TESTS:-0}" == "1" ]]; then
    if grep -q '"test"' package.json 2>/dev/null; then
        log_debug "Running tests..."
        
        if npm test --silent 2>/dev/null; then
            log_info "✓ Tests passed"
        else
            TEST_ERRORS=$(npm test 2>&1 | tail -20)
            ERRORS="${ERRORS}\n\n❌ Test failures:\n${TEST_ERRORS}"
        fi
    fi
fi

# ============================================================================
# BLOCK OR ALLOW
# ============================================================================

if [[ -n "$ERRORS" ]]; then
    log_warn "Quality checks failed"
    cat <<EOF
{
  "decision": "block",
  "reason": "QUALITY CHECKS FAILED - Fix before committing:${ERRORS}\n\nTo bypass (not recommended): CLAUDE_SKIP_QUALITY_CHECK=1 git commit ..."
}
EOF
    finalize_hook 1
    exit 0
fi

log_info "All quality checks passed"
finalize_hook 0
