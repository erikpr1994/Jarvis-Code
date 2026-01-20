#!/usr/bin/env bash
# Hook: gh-cli-suggest
# Event: PreToolUse
# Tools: Bash
# Purpose: Soft suggestion to load gh-cli skill when using GitHub CLI commands
# Non-blocking - provides helpful context without preventing execution

set -euo pipefail

# Get script directory and source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Initialize hook (optional category - doesn't block under load)
init_hook "gh-cli-suggest" "optional"

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

# Check if gh-cli skill is already loaded
if bypass_enabled "GH_CLI_SKILL_LOADED"; then
    log_debug "Bypass: GH_CLI_SKILL_LOADED=1 (skill already active)"
    finalize_hook 0
    exit 0
fi

# Check for global hook skip
if bypass_enabled "JARVIS_SKIP_HOOKS"; then
    log_debug "Bypass: JARVIS_SKIP_HOOKS=1"
    finalize_hook 0
    exit 0
fi

# ============================================================================
# DETECTION PATTERNS
# ============================================================================

# Detect gh api commands (REST and GraphQL)
if echo "$COMMAND" | grep -qE '\bgh\s+api\b'; then
    log_info "Detected gh api command - suggesting gh-cli skill"

    # Provide soft suggestion as additional context
    output_context "💡 TIP: Load the gh-cli skill for GitHub API patterns.

The gh-cli skill covers:
- Correct REST endpoints for PR comments/replies
- GraphQL variable escaping (common bash issue)
- Thread resolution patterns

To load: Use the Skill tool with skill: \"gh-cli\"

This is a suggestion only - your command will still execute."

    finalize_hook 0
    exit 0
fi

# Detect gh pr commands (but not gh pr create - that's handled by block-direct-submit)
if echo "$COMMAND" | grep -qE '\bgh\s+pr\s+(view|list|checks|comment|review|merge|close|reopen|edit)\b'; then
    log_info "Detected gh pr command - suggesting gh-cli skill"

    output_context "💡 TIP: The gh-cli skill has patterns for PR operations.

Covers: comment threads, review replies, status checks.

To load: Use the Skill tool with skill: \"gh-cli\""

    finalize_hook 0
    exit 0
fi

# Detect GraphQL queries (common source of escaping issues)
if echo "$COMMAND" | grep -qE '\bgh\s+api\s+graphql\b'; then
    log_info "Detected gh api graphql command - suggesting gh-cli skill"

    output_context "💡 TIP: GraphQL with gh cli has escaping gotchas.

Common issue: \$ in queries gets interpreted by bash.

Solutions in gh-cli skill:
- Hardcode values in query
- Use -F flag for variables
- Escape \$ as \\\$

To load: Use the Skill tool with skill: \"gh-cli\""

    finalize_hook 0
    exit 0
fi

# ============================================================================
# NO MATCH - ALLOW SILENTLY
# ============================================================================

log_debug "No gh cli pattern detected - passing through"
finalize_hook 0
