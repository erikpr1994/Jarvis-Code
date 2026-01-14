#!/usr/bin/env bash
# Hook: post-edit-suggest
# Event: PostToolUse
# Tools: Edit, Write
# Purpose: Suggest relevant skills/agents after code modifications
#
# Triggers:
#   - React files (.tsx, .jsx): Suggest react-best-practices skill
#   - Any code files: Suggest code-simplifier agent
#
# Environment:
#   SKIP_POST_EDIT_SUGGEST=1  Bypass this hook entirely

set -euo pipefail

# Get script directory and source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Initialize hook (optional - suggestions should not block)
init_hook "post-edit-suggest" "optional"

# ============================================================================
# INPUT PARSING
# ============================================================================

# Read input from stdin
INPUT=$(cat)

# Parse tool name
TOOL_NAME=$(parse_tool_name "$INPUT")

# Only process Edit and Write tools
if [[ "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "Write" ]]; then
    log_debug "Skipping non-edit tool: $TOOL_NAME"
    finalize_hook 0
    exit 0
fi

# Parse file path from tool input
FILE_PATH=$(parse_file_path "$INPUT")

if [[ -z "$FILE_PATH" ]]; then
    log_debug "No file path in input"
    finalize_hook 0
    exit 0
fi

log_debug "Processing file modification: $FILE_PATH"

# ============================================================================
# BYPASS CONDITIONS
# ============================================================================

# Check for bypass
if bypass_enabled "SKIP_POST_EDIT_SUGGEST"; then
    log_info "Bypass enabled: post-edit suggestions disabled"
    finalize_hook 0
    exit 0
fi

# Skip if running code-simplifier agent (prevent infinite loop)
if bypass_enabled "CODE_SIMPLIFIER_RUNNING"; then
    log_debug "Code simplifier already running, skipping"
    finalize_hook 0
    exit 0
fi

# ============================================================================
# FILE TYPE DETECTION
# ============================================================================

# Get file extension
FILE_EXT="${FILE_PATH##*.}"
FILE_NAME=$(basename "$FILE_PATH")

# Detect if it's a React file
is_react_file() {
    case "$FILE_EXT" in
        tsx|jsx) return 0 ;;
    esac

    # Also check for React imports in .ts/.js files
    if [[ "$FILE_EXT" == "ts" || "$FILE_EXT" == "js" ]]; then
        # Check path patterns
        if echo "$FILE_PATH" | grep -qE '/(components|pages|app|views)/'; then
            return 0
        fi
    fi

    return 1
}

# Detect if it's a code file (not config/docs)
is_code_file() {
    case "$FILE_EXT" in
        ts|tsx|js|jsx|py|rb|go|rs|java|kt|swift|c|cpp|h|hpp|cs|php)
            return 0
            ;;
    esac

    # Exclude common non-code files
    case "$FILE_NAME" in
        *.config.*|*.json|*.yaml|*.yml|*.md|*.txt|*.lock|*.toml)
            return 1
            ;;
    esac

    return 1
}

# ============================================================================
# BUILD SUGGESTIONS
# ============================================================================

SUGGESTIONS=()
REACT_SUGGESTED=false
CODE_SIMPLIFIER_SUGGESTED=false

# Check for React files
if is_react_file; then
    SUGGESTIONS+=("REACT FILE MODIFIED: Consider using react-best-practices skill for optimal patterns")
    REACT_SUGGESTED=true
    log_info "React file detected: $FILE_PATH"
fi

# Check for code files (suggest code-simplifier)
if is_code_file; then
    SUGGESTIONS+=("CODE MODIFIED: Consider dispatching code-simplifier agent to refine for clarity")
    CODE_SIMPLIFIER_SUGGESTED=true
    log_info "Code file detected: $FILE_PATH"
fi

# ============================================================================
# OUTPUT
# ============================================================================

if [[ ${#SUGGESTIONS[@]} -gt 0 ]]; then
    log_info "Generating ${#SUGGESTIONS[@]} suggestion(s)"

    # Build output message
    OUTPUT="POST-EDIT SUGGESTIONS:\n\n"

    for suggestion in "${SUGGESTIONS[@]}"; do
        OUTPUT+="  -> $suggestion\n"
    done

    OUTPUT+="\n"

    if [[ "$REACT_SUGGESTED" == "true" ]]; then
        OUTPUT+="To apply React best practices: Use Skill tool with skill: \"react-best-practices\"\n"
    fi

    if [[ "$CODE_SIMPLIFIER_SUGGESTED" == "true" ]]; then
        OUTPUT+="To simplify code: Use Task tool with subagent_type: \"code-simplifier\"\n"
    fi

    echo -e "$OUTPUT"
fi

finalize_hook 0
