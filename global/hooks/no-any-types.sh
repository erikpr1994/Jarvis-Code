#!/usr/bin/env bash
# Hook: no-any-types
# Event: PreToolUse
# Tools: Edit, Write
# Purpose: Warn or block when adding 'any' type to TypeScript files
#
# Lightweight check - doesn't require ESLint in the project.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

init_hook "no-any-types"

# ============================================================================
# INPUT PARSING
# ============================================================================

INPUT=$(cat)
TOOL_NAME=$(parse_tool_name "$INPUT")
FILE_PATH=$(parse_file_path "$INPUT")

# Only check Edit and Write tools on TypeScript files
if [[ "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "Write" ]]; then
    finalize_hook 0
    exit 0
fi

if [[ ! "$FILE_PATH" =~ \.(ts|tsx)$ ]]; then
    finalize_hook 0
    exit 0
fi

# ============================================================================
# BYPASS CONDITIONS
# ============================================================================

if bypass_enabled "CLAUDE_ALLOW_ANY"; then
    log_info "Bypass enabled: CLAUDE_ALLOW_ANY=1"
    finalize_hook 0
    exit 0
fi

# Check if hook is enabled (default: warning only)
SEVERITY=$(get_preference "hooks.noAnyTypes.severity" "warn")
if ! is_hook_enabled "noAnyTypes" "true"; then
    log_info "Hook disabled in preferences"
    finalize_hook 0
    exit 0
fi

# ============================================================================
# CHECK FOR 'any' TYPE
# ============================================================================

# Get the content being written/edited
CONTENT=""
if [[ "$TOOL_NAME" == "Write" ]]; then
    CONTENT=$(echo "$INPUT" | jq -r '.content // empty' 2>/dev/null || echo "")
elif [[ "$TOOL_NAME" == "Edit" ]]; then
    CONTENT=$(echo "$INPUT" | jq -r '.new_str // .newText // empty' 2>/dev/null || echo "")
fi

if [[ -z "$CONTENT" ]]; then
    finalize_hook 0
    exit 0
fi

# Check for explicit 'any' type usage
# Pattern matches: : any, <any>, as any, : any[], etc.
# But NOT: company, many, any word containing 'any'
ANY_MATCHES=$(echo "$CONTENT" | grep -nE ':\s*any\b|<any>|<any,|,\s*any>|as\s+any\b|\bany\[\]' || true)

if [[ -n "$ANY_MATCHES" ]]; then
    log_warn "Found 'any' type in TypeScript code"
    
    if [[ "$SEVERITY" == "error" ]]; then
        cat <<EOF
{
  "decision": "block",
  "reason": "ANY TYPE DETECTED in $FILE_PATH

Found:
$ANY_MATCHES

Use specific types instead:
  - unknown    - For truly unknown types (requires type narrowing)
  - never      - For impossible cases
  - Record<string, T> - For object with string keys
  - T | null   - For nullable values
  
If 'any' is truly needed, add bypass: CLAUDE_ALLOW_ANY=1"
}
EOF
        finalize_hook 1
        exit 0
    else
        # Warning only - add context but don't block
        output_context "⚠️ WARNING: 'any' type detected in $FILE_PATH. Consider using specific types instead."
    fi
fi

finalize_hook 0
