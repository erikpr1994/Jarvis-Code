#!/usr/bin/env bash
# Jarvis Metrics Capture Hook
# Type: PostToolUse (runs in background)
# Purpose: Captures metrics from tool usage for productivity tracking
#
# This hook runs after tool executions to:
# - Track skill invocations
# - Increment relevant counters
# - Monitor context usage
# - Log tool execution patterns

set -euo pipefail

# Load common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Initialize hook
init_hook "metrics-capture"

# Configuration
JARVIS_ROOT="${JARVIS_ROOT:-$HOME/.jarvis}"
METRICS_DIR="${JARVIS_ROOT}/global/metrics"
DAILY_DIR="${METRICS_DIR}/daily"
METRICS_LOG="${JARVIS_ROOT}/logs/metrics-capture.log"
SKILLS_LOG="${JARVIS_ROOT}/global/learning/skills-log.json"
CONTEXT_LOG="${JARVIS_ROOT}/global/learning/context-usage.log"
PATTERNS_LOG="${JARVIS_ROOT}/global/patterns/matches.log"

TODAY=$(date +%Y-%m-%d)
DAILY_FILE="${DAILY_DIR}/${TODAY}.json"

# Ensure directories exist
mkdir -p "$DAILY_DIR" "${JARVIS_ROOT}/logs" "$(dirname "$SKILLS_LOG")" "$(dirname "$CONTEXT_LOG")" "$(dirname "$PATTERNS_LOG")" 2>/dev/null || true

# ============================================================================
# METRICS FILE MANAGEMENT
# ============================================================================

# Initialize daily metrics file if it doesn't exist
init_daily_metrics() {
    if [[ ! -f "$DAILY_FILE" ]]; then
        cat > "$DAILY_FILE" << EOF
{
  "date": "${TODAY}",
  "productivity": {
    "features_completed": 0,
    "commits": 0,
    "prs_merged": 0
  },
  "quality": {
    "test_coverage": 0,
    "review_score_avg": 0,
    "bugs_found": 0
  },
  "learning": {
    "skills_invoked": [],
    "patterns_matched": 0
  },
  "context": {
    "tokens_used": 0,
    "compactions": 0
  }
}
EOF
        log_info "Created daily metrics file: $DAILY_FILE"
    fi
}

# Increment a numeric field in the daily metrics
increment_metric() {
    local category="$1"
    local field="$2"
    local amount="${3:-1}"

    if ! command -v jq &>/dev/null; then
        log_warn "jq not available, skipping metric update"
        return
    fi

    if [[ ! -f "$DAILY_FILE" ]]; then
        init_daily_metrics
    fi

    local updated
    updated=$(jq --arg cat "$category" \
                 --arg field "$field" \
                 --argjson amount "$amount" \
                 '.[$cat][$field] = ((.[$cat][$field] // 0) + $amount)' \
                 "$DAILY_FILE" 2>/dev/null)

    if [[ -n "$updated" ]]; then
        echo "$updated" > "$DAILY_FILE"
        log_debug "Incremented $category.$field by $amount"
    fi
}

# Add a skill to the skills_invoked array
add_skill_invoked() {
    local skill_name="$1"

    if ! command -v jq &>/dev/null; then
        log_warn "jq not available, skipping skill tracking"
        return
    fi

    if [[ ! -f "$DAILY_FILE" ]]; then
        init_daily_metrics
    fi

    local updated
    updated=$(jq --arg skill "$skill_name" \
                 'if (.learning.skills_invoked | index($skill)) == null then
                    .learning.skills_invoked += [$skill]
                  else . end' \
                 "$DAILY_FILE" 2>/dev/null)

    if [[ -n "$updated" ]]; then
        echo "$updated" > "$DAILY_FILE"
        log_debug "Added skill to invoked list: $skill_name"
    fi

    # Also log to skills log file
    log_skill_invocation "$skill_name"
}

# ============================================================================
# LOGGING HELPERS
# ============================================================================

# Log skill invocation to skills log
log_skill_invocation() {
    local skill_name="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')

    # Append to skills log
    echo "{\"date\": \"${TODAY}\", \"timestamp\": \"${timestamp}\", \"skill\": \"${skill_name}\"}" >> "$SKILLS_LOG"
}

# Log context usage
log_context_usage() {
    local tokens="$1"
    local event_type="${2:-usage}"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')

    echo "${timestamp},${tokens},${event_type}" >> "$CONTEXT_LOG"
}

# Log pattern match
log_pattern_match() {
    local pattern_name="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')

    echo "${TODAY},${timestamp},${pattern_name}" >> "$PATTERNS_LOG"
    increment_metric "learning" "patterns_matched"
}

# ============================================================================
# INPUT PARSING
# ============================================================================

# Read JSON input from stdin
read_input() {
    local input=""
    while IFS= read -r line; do
        input+="$line"
    done
    echo "$input"
}

# Extract tool information from hook input
extract_tool_info() {
    local input="$1"

    TOOL_NAME=$(echo "$input" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//' || echo "unknown")
    TOOL_INPUT=$(echo "$input" | grep -o '"tool_input"[[:space:]]*:[[:space:]]*{[^}]*}' || echo "{}")
    TOOL_OUTPUT=$(echo "$input" | grep -o '"tool_output"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//' || echo "")
    SUCCESS=$(echo "$input" | grep -o '"success"[[:space:]]*:[[:space:]]*[a-z]*' | sed 's/.*: *//' || echo "true")
}

# ============================================================================
# METRIC CAPTURE LOGIC
# ============================================================================

# Capture metrics based on tool type
capture_tool_metrics() {
    local tool_name="$1"
    local tool_input="$2"

    case "$tool_name" in
        Skill)
            # Track skill invocations
            local skill_name
            skill_name=$(echo "$tool_input" | grep -o '"skill"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//' || echo "")
            if [[ -n "$skill_name" ]]; then
                add_skill_invoked "$skill_name"
            fi
            ;;

        Edit|Write|NotebookEdit)
            # Track file operations (could indicate feature work)
            log_debug "File operation detected: $tool_name"
            ;;

        Bash)
            # Check for git operations
            local command
            command=$(echo "$tool_input" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//' || echo "")

            if echo "$command" | grep -qE "^git commit"; then
                increment_metric "productivity" "commits"
                log_info "Commit detected, incremented commits counter"
            fi

            if echo "$command" | grep -qE "gh pr (create|merge)"; then
                increment_metric "productivity" "prs_merged"
                log_info "PR operation detected, incremented prs_merged counter"
            fi

            # Check for test runs
            if echo "$command" | grep -qE "(npm test|jest|pytest|cargo test|go test)"; then
                log_debug "Test run detected"
            fi
            ;;

        Grep|Glob|Read)
            # Track context/search operations
            log_debug "Search/read operation: $tool_name"
            ;;

        WebSearch|WebFetch)
            # Track web lookups
            log_debug "Web operation: $tool_name"
            ;;

        TodoWrite)
            # Potential feature completion indicator
            log_debug "Todo update detected"
            ;;
    esac
}

# Detect if a pattern was matched based on tool usage
detect_pattern_usage() {
    local tool_name="$1"
    local tool_input="$2"

    # Check for common patterns based on tool sequences
    # This is a simplified detection - in production, you'd track sequences

    if [[ "$tool_name" == "Edit" ]]; then
        local file_path
        file_path=$(echo "$tool_input" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//' || echo "")

        # Detect test file patterns
        if echo "$file_path" | grep -qE "\.(test|spec)\.(ts|js|tsx|jsx)$"; then
            log_pattern_match "test_file_modification"
        fi

        # Detect component patterns
        if echo "$file_path" | grep -qE "components/.*\.(tsx|jsx)$"; then
            log_pattern_match "component_modification"
        fi

        # Detect hook patterns
        if echo "$file_path" | grep -qE "hooks/.*\.(ts|js)$"; then
            log_pattern_match "hook_modification"
        fi
    fi
}

# Estimate token usage (simplified)
estimate_tokens() {
    local tool_input="$1"
    local tool_output="$2"

    # Very rough estimation: ~4 characters per token
    local input_len=${#tool_input}
    local output_len=${#tool_output}
    local total_chars=$((input_len + output_len))
    local estimated_tokens=$((total_chars / 4))

    if [[ $estimated_tokens -gt 100 ]]; then
        increment_metric "context" "tokens_used" "$estimated_tokens"
        log_context_usage "$estimated_tokens" "tool_execution"
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    # Skip if disabled
    if [[ "${JARVIS_SKIP_METRICS:-0}" == "1" ]]; then
        log_debug "Metrics capture skipped (JARVIS_SKIP_METRICS=1)"
        finalize_hook 0
        exit 0
    fi

    # Initialize daily metrics file
    init_daily_metrics

    # Read input from stdin (PostToolUse provides tool execution details)
    local input
    input=$(read_input)

    if [[ -z "$input" ]]; then
        log_debug "No input received"
        finalize_hook 0
        exit 0
    fi

    # Extract tool information
    extract_tool_info "$input"

    # Only process successful operations
    if [[ "$SUCCESS" != "true" ]]; then
        log_debug "Skipping failed tool execution"
        finalize_hook 0
        exit 0
    fi

    log_debug "Processing tool for metrics: $TOOL_NAME"

    # Capture metrics based on tool type
    capture_tool_metrics "$TOOL_NAME" "$TOOL_INPUT"

    # Detect pattern usage
    detect_pattern_usage "$TOOL_NAME" "$TOOL_INPUT"

    # Estimate token usage
    estimate_tokens "$TOOL_INPUT" "$TOOL_OUTPUT"

    finalize_hook 0
}

# Run main function
main "$@"
