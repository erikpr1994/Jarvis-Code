#!/usr/bin/env bash
# Hook: compress-output
# Event: PostToolUse
# Tools: Bash
# Purpose: Compress verbose bash command outputs to reduce token usage
#
# This hook intercepts bash command outputs and routes them through
# appropriate wrapper scripts for context-efficient compression.
#
# Wrapper scripts are located in: global/lib/context/wrappers/
#   - test-wrapper.sh   - vitest, jest, pytest, go test, etc.
#   - lint-wrapper.sh   - eslint, biome, prettier, etc.
#   - build-wrapper.sh  - vite, webpack, turbo, cargo build, etc.
#   - git-wrapper.sh    - git commands with large output
#   - gh-wrapper.sh     - GitHub CLI commands
#
# Fallback: summarize-output.sh for generic compression
#
# Environment:
#   VERBOSE_OUTPUT=1          Bypass compression (show full output)
#   JARVIS_DISABLE_COMPRESS=1 Disable this hook entirely
#
# Expected token savings:
#   - All tests pass (300 tests): ~5000 -> ~20 tokens (99.6% reduction)
#   - Build success: ~3000 -> ~20 tokens (99.3% reduction)
#   - Lint clean: ~300 -> ~10 tokens (96.7% reduction)

set -euo pipefail

# Get script directory and source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Initialize hook
init_hook "compress-output"

# Path to wrapper scripts
WRAPPERS_DIR="${SCRIPT_DIR}/../lib/context/wrappers"
SUMMARIZE_SCRIPT="${SCRIPT_DIR}/../lib/context/summarize-output.sh"

# ============================================================================
# BYPASS CONDITIONS
# ============================================================================

# Check for verbose output mode
if bypass_enabled "VERBOSE_OUTPUT" || bypass_enabled "JARVIS_DISABLE_COMPRESS"; then
    log_info "Bypass enabled: compression disabled"
    finalize_hook 0
    exit 0
fi

# ============================================================================
# INPUT PARSING
# ============================================================================

# Read input from stdin
INPUT=$(cat)

# Parse tool name
TOOL_NAME=$(parse_tool_name "$INPUT")

# Only process Bash tool output
if [[ "$TOOL_NAME" != "Bash" ]]; then
    log_debug "Skipping non-Bash tool: $TOOL_NAME"
    finalize_hook 0
    exit 0
fi

# Parse command from Bash tool input
COMMAND=$(parse_command "$INPUT")

log_debug "Processing command: $COMMAND"

# ============================================================================
# COMMAND TYPE DETECTION
# ============================================================================

detect_command_type() {
    local cmd="$1"

    # Test commands
    if echo "$cmd" | grep -qiE '\b(vitest|jest|pytest|py\.test|go\s+test|cargo\s+test|mocha|ava|phpunit|rspec|npm\s+(run\s+)?test|yarn\s+test|pnpm\s+test)\b'; then
        echo "test"
        return
    fi

    # Lint commands
    if echo "$cmd" | grep -qiE '\b(eslint|biome|prettier|stylelint|pylint|flake8|ruff|rubocop|golint|golangci-lint|clippy|tsc\s+--noEmit|mypy|pyright|npm\s+(run\s+)?lint|pnpm\s+lint)\b'; then
        echo "lint"
        return
    fi

    # Build commands
    if echo "$cmd" | grep -qiE '\b(vite\s+build|webpack|turbo\s+build|next\s+build|esbuild|rollup|parcel|cargo\s+build|go\s+build|docker\s+build|gradle|mvn|npm\s+(run\s+)?build|pnpm\s+build|make(\s|$))\b'; then
        echo "build"
        return
    fi

    # Git commands
    if echo "$cmd" | grep -qE '^git\s+'; then
        echo "git"
        return
    fi

    # GitHub CLI
    if echo "$cmd" | grep -qE '^gh\s+'; then
        echo "gh"
        return
    fi

    # Package install (often verbose)
    if echo "$cmd" | grep -qiE '\b(npm\s+install|yarn(\s+install)?|pnpm\s+install|pip\s+install|cargo\s+update|go\s+mod)\b'; then
        echo "install"
        return
    fi

    echo "unknown"
}

CMD_TYPE=$(detect_command_type "$COMMAND")
log_debug "Detected command type: $CMD_TYPE"

# ============================================================================
# GENERATE COMPRESSION CONTEXT
# ============================================================================

# Based on command type, provide context for output handling
COMPRESSION_CONTEXT=""

case "$CMD_TYPE" in
    test)
        COMPRESSION_CONTEXT="TEST OUTPUT COMPRESSION ACTIVE:\n\
Use wrapper: ${WRAPPERS_DIR}/test-wrapper.sh --stdin\n\
Summary format:\n\
- Success: 'All tests passed: N passed (time)'\n\
- Failure: 'Test failures: N failed, M passed' + first 5 errors\n\
- Truncate stack traces to 10 lines max"
        ;;

    lint)
        COMPRESSION_CONTEXT="LINT OUTPUT COMPRESSION ACTIVE:\n\
Use wrapper: ${WRAPPERS_DIR}/lint-wrapper.sh --stdin\n\
Summary format:\n\
- Success: 'Lint: No issues found'\n\
- Failure: 'Lint: N errors, M warnings' + grouped by file (max 10 files)\n\
- Show fixable vs manual distinction"
        ;;

    build)
        COMPRESSION_CONTEXT="BUILD OUTPUT COMPRESSION ACTIVE:\n\
Use wrapper: ${WRAPPERS_DIR}/build-wrapper.sh --stdin\n\
Summary format:\n\
- Success: 'Build succeeded (time)' + bundle stats\n\
- Failure: 'Build failed' + first 5 errors\n\
- Truncate verbose compilation output"
        ;;

    git)
        COMPRESSION_CONTEXT="GIT OUTPUT COMPRESSION ACTIVE:\n\
Use wrapper: ${WRAPPERS_DIR}/git-wrapper.sh --stdin [subcommand]\n\
Summary format:\n\
- diff: 'N files, +X/-Y lines' + file list (max 20)\n\
- log: 'N commits' + summary\n\
- status: 'N modified, M new, K untracked'"
        ;;

    gh)
        COMPRESSION_CONTEXT="GITHUB CLI OUTPUT COMPRESSION ACTIVE:\n\
Use wrapper: ${WRAPPERS_DIR}/gh-wrapper.sh\n\
Summary format:\n\
- pr list: 'Pull Requests (N)' + first 20\n\
- issue list: 'Issues (N)' + first 20\n\
- Truncate API responses to 50 lines"
        ;;

    install)
        COMPRESSION_CONTEXT="PACKAGE INSTALL OUTPUT COMPRESSION:\n\
Summarize to:\n\
- Number of packages installed/updated\n\
- Final status\n\
- Notable warnings only\n\
- Skip download progress"
        ;;

    *)
        # For unknown commands, check if output would benefit from compression
        # This is handled by the calling context, no special context needed
        ;;
esac

# ============================================================================
# OUTPUT
# ============================================================================

if [[ -n "$COMPRESSION_CONTEXT" ]]; then
    log_info "Providing compression context for $CMD_TYPE command"
    escaped_context=$(escape_for_json "$COMPRESSION_CONTEXT")
    cat << EOF
{
  "hookSpecificOutput": {
    "additionalContext": "${escaped_context}",
    "compressionType": "${CMD_TYPE}",
    "wrapperPath": "${WRAPPERS_DIR}/${CMD_TYPE}-wrapper.sh"
  }
}
EOF
fi

finalize_hook 0
