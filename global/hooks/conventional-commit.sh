#!/usr/bin/env bash
# Hook: conventional-commit
# Event: PreToolUse
# Tools: Bash
# Purpose: Validate commit messages follow conventional commit format
#
# Format: <type>(<scope>): <description>
#
# No project-level tools required - this hook does the validation directly.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

init_hook "conventional-commit"

# ============================================================================
# INPUT PARSING
# ============================================================================

INPUT=$(cat)
COMMAND=$(parse_command "$INPUT")

# Only check git commit commands with -m flag
if ! echo "$COMMAND" | grep -qE 'git\s+commit.*-m'; then
    finalize_hook 0
    exit 0
fi

# ============================================================================
# BYPASS CONDITIONS
# ============================================================================

if bypass_enabled "CLAUDE_SKIP_COMMIT_FORMAT"; then
    log_info "Bypass enabled: CLAUDE_SKIP_COMMIT_FORMAT=1"
    finalize_hook 0
    exit 0
fi

# Check if hook is enabled in preferences (default: enabled)
if ! is_hook_enabled "conventionalCommit" "true"; then
    log_info "Hook disabled in preferences"
    finalize_hook 0
    exit 0
fi

# ============================================================================
# EXTRACT COMMIT MESSAGE
# ============================================================================

# Extract message from: git commit -m "message" or git commit -m 'message'
# Handle various quoting styles
COMMIT_MSG=""

# Try double quotes
if echo "$COMMAND" | grep -qE '\-m\s+"[^"]+'; then
    COMMIT_MSG=$(echo "$COMMAND" | grep -oE '\-m\s+"[^"]+"' | sed 's/-m\s*"//' | sed 's/"$//')
fi

# Try single quotes
if [[ -z "$COMMIT_MSG" ]] && echo "$COMMAND" | grep -qE "\-m\s+'[^']+"; then
    COMMIT_MSG=$(echo "$COMMAND" | grep -oE "\-m\s+'[^']+'" | sed "s/-m\s*'//" | sed "s/'$//")
fi

# If we couldn't extract, allow (might be interactive commit)
if [[ -z "$COMMIT_MSG" ]]; then
    log_debug "Could not extract commit message, allowing"
    finalize_hook 0
    exit 0
fi

log_debug "Checking commit message: $COMMIT_MSG"

# ============================================================================
# VALIDATE FORMAT
# ============================================================================

# Conventional commit pattern:
# type(scope): description  OR  type: description
# type must be: feat|fix|docs|style|refactor|perf|test|chore|ci|build|revert
PATTERN='^(feat|fix|docs|style|refactor|perf|test|chore|ci|build|revert)(\([a-z0-9\-]+\))?!?: .+'

if echo "$COMMIT_MSG" | grep -qE "$PATTERN"; then
    log_info "✓ Commit message follows conventional format"
    finalize_hook 0
    exit 0
fi

# ============================================================================
# BLOCK INVALID FORMAT
# ============================================================================

log_warn "Invalid commit message format"
cat <<EOF
{
  "decision": "block",
  "reason": "COMMIT MESSAGE FORMAT INVALID

Your message: \"$COMMIT_MSG\"

Required format: <type>(<scope>): <description>

Valid types:
  feat     - New feature
  fix      - Bug fix
  docs     - Documentation only
  style    - Formatting (no code change)
  refactor - Code change, no feature/fix
  perf     - Performance improvement
  test     - Adding/fixing tests
  chore    - Maintenance, dependencies
  ci       - CI/CD changes
  build    - Build system changes
  revert   - Revert previous commit

Examples:
  feat(auth): add OAuth2 login flow
  fix(api): handle null user in profile endpoint
  chore(deps): update react to v19
  docs: update README installation steps

To bypass: CLAUDE_SKIP_COMMIT_FORMAT=1 git commit ..."
}
EOF
finalize_hook 1
