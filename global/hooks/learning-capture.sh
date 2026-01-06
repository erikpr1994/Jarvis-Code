#!/usr/bin/env bash
# Jarvis Learning Capture Hook
# Type: PostToolUse (runs in background)
# Purpose: Captures patterns from successful operations for learning system
#
# This hook runs after successful tool executions to:
# - Detect repeated patterns that could become skills
# - Capture successful operations for future reference
# - Detect repeated manual guidance that suggests skill gaps
# - Log learnings to inbox for review

set -euo pipefail

# Load common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Initialize hook
init_hook "learning-capture"

# Configuration
JARVIS_ROOT="${JARVIS_ROOT:-$HOME/.jarvis}"
LEARNING_INBOX="${JARVIS_ROOT}/learnings/inbox"
LEARNING_LOG="${JARVIS_ROOT}/logs/learning-capture.log"
SESSION_PATTERNS_FILE="${JARVIS_ROOT}/learnings/.session-patterns.json"

# Memory tier thresholds
HOT_MEMORY_MAX_ITEMS=20
WARM_PROMOTION_THRESHOLD=3  # Occurrences needed to promote from hot to warm
COLD_DEMOTION_DAYS=30       # Days of inactivity before demotion

# Ensure directories exist
mkdir -p "$LEARNING_INBOX" "${JARVIS_ROOT}/logs" "$(dirname "$SESSION_PATTERNS_FILE")"

# ============================================================================
# PATTERN DETECTION
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

# Detect code patterns from Edit/Write tool usage
detect_code_patterns() {
    local tool_name="$1"
    local tool_input="$2"

    # Only analyze Edit and Write tools
    if [[ "$tool_name" != "Edit" && "$tool_name" != "Write" ]]; then
        return
    fi

    # Extract file path and content
    local file_path
    file_path=$(echo "$tool_input" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//' || echo "")

    if [[ -z "$file_path" ]]; then
        return
    fi

    # Track file type patterns
    local extension="${file_path##*.}"
    local pattern_type=""

    case "$extension" in
        ts|tsx)
            pattern_type="typescript"
            detect_typescript_patterns "$tool_input"
            ;;
        js|jsx)
            pattern_type="javascript"
            detect_javascript_patterns "$tool_input"
            ;;
        py)
            pattern_type="python"
            detect_python_patterns "$tool_input"
            ;;
        sh|bash)
            pattern_type="shell"
            detect_shell_patterns "$tool_input"
            ;;
    esac

    # Log file type usage
    if [[ -n "$pattern_type" ]]; then
        increment_pattern_count "file_type:$pattern_type"
    fi
}

# Detect TypeScript-specific patterns
detect_typescript_patterns() {
    local input="$1"

    # Check for common patterns
    if echo "$input" | grep -q "try.*catch"; then
        increment_pattern_count "ts:error_handling:try_catch"
    fi

    if echo "$input" | grep -q "async.*await"; then
        increment_pattern_count "ts:async_pattern"
    fi

    if echo "$input" | grep -q "interface\|type.*="; then
        increment_pattern_count "ts:type_definition"
    fi

    if echo "$input" | grep -q "export.*function\|export.*const"; then
        increment_pattern_count "ts:module_export"
    fi

    if echo "$input" | grep -q "zod\|z\\."; then
        increment_pattern_count "ts:zod_validation"
    fi

    if echo "$input" | grep -q "useEffect\|useState\|useCallback"; then
        increment_pattern_count "ts:react_hooks"
    fi
}

# Detect JavaScript-specific patterns
detect_javascript_patterns() {
    local input="$1"

    if echo "$input" | grep -q "try.*catch"; then
        increment_pattern_count "js:error_handling:try_catch"
    fi

    if echo "$input" | grep -q "async.*await\|Promise"; then
        increment_pattern_count "js:async_pattern"
    fi

    if echo "$input" | grep -q "module\\.exports\|export"; then
        increment_pattern_count "js:module_export"
    fi
}

# Detect Python-specific patterns
detect_python_patterns() {
    local input="$1"

    if echo "$input" | grep -q "try:.*except"; then
        increment_pattern_count "py:error_handling:try_except"
    fi

    if echo "$input" | grep -q "async def\|await"; then
        increment_pattern_count "py:async_pattern"
    fi

    if echo "$input" | grep -q "def.*->"; then
        increment_pattern_count "py:type_hints"
    fi

    if echo "$input" | grep -q "from.*import\|import"; then
        increment_pattern_count "py:module_import"
    fi
}

# Detect Shell-specific patterns
detect_shell_patterns() {
    local input="$1"

    if echo "$input" | grep -q "set -[euo]"; then
        increment_pattern_count "sh:strict_mode"
    fi

    if echo "$input" | grep -q 'if \[\[.*\]\]'; then
        increment_pattern_count "sh:conditional"
    fi

    if echo "$input" | grep -q "function\|().*{"; then
        increment_pattern_count "sh:function_definition"
    fi
}

# ============================================================================
# PATTERN TRACKING
# ============================================================================

# Increment pattern count in session file
increment_pattern_count() {
    local pattern_key="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')
    local today
    today=$(date '+%Y-%m-%d')

    # Initialize session patterns file if needed
    if [[ ! -f "$SESSION_PATTERNS_FILE" ]]; then
        echo '{"patterns":{}}' > "$SESSION_PATTERNS_FILE"
    fi

    # Check if jq is available for proper JSON handling
    if command -v jq &>/dev/null; then
        local current_count
        current_count=$(jq -r --arg key "$pattern_key" '.patterns[$key].count // 0' "$SESSION_PATTERNS_FILE" 2>/dev/null || echo "0")
        current_count=$((current_count + 1))

        # Update pattern count
        local updated
        updated=$(jq --arg key "$pattern_key" \
                    --arg ts "$timestamp" \
                    --argjson count "$current_count" \
                    '.patterns[$key] = {
                        "count": $count,
                        "last_seen": $ts,
                        "first_seen": (.patterns[$key].first_seen // $ts)
                    }' "$SESSION_PATTERNS_FILE" 2>/dev/null)

        if [[ -n "$updated" ]]; then
            echo "$updated" > "$SESSION_PATTERNS_FILE"
        fi

        # Check if pattern should be promoted to learning
        if [[ "$current_count" -ge "$WARM_PROMOTION_THRESHOLD" ]]; then
            promote_to_learning "$pattern_key" "$current_count"
        fi
    else
        # Fallback: simple append to log file
        echo "$timestamp|$pattern_key|1" >> "${JARVIS_ROOT}/logs/patterns.log"
    fi

    log_debug "Pattern detected: $pattern_key"
}

# Promote high-frequency pattern to learning inbox
promote_to_learning() {
    local pattern_key="$1"
    local frequency="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')
    local learning_id
    learning_id="pat_$(date '+%Y%m%d%H%M%S')_$$"

    # Create learning entry
    local learning_file="${LEARNING_INBOX}/${learning_id}.json"

    cat > "$learning_file" << EOF
{
    "id": "${learning_id}",
    "type": "code_pattern",
    "pattern_key": "${pattern_key}",
    "description": "Detected pattern: ${pattern_key}",
    "frequency": ${frequency},
    "status": "pending",
    "tier": "hot",
    "context": {
        "detected_by": "learning-capture-hook",
        "session": "${SESSION_ID:-unknown}"
    },
    "created_at": "${timestamp}",
    "last_updated": "${timestamp}"
}
EOF

    log_info "Pattern promoted to learning inbox: $learning_id ($pattern_key)"
}

# ============================================================================
# MANUAL GUIDANCE DETECTION
# ============================================================================

# Detect repeated manual guidance from user prompts
detect_manual_guidance() {
    local tool_name="$1"

    # Track when user provides guidance after tool use
    # This is detected when Edit/Write is followed by similar Edit/Write
    # suggesting the AI needed correction

    local guidance_file="${JARVIS_ROOT}/learnings/.guidance-tracking.json"

    if [[ ! -f "$guidance_file" ]]; then
        echo '{"guidance_patterns":[]}' > "$guidance_file"
    fi

    # This will be called from the UserPromptSubmit hook
    # Here we just track tool sequences that might indicate guidance needed
}

# ============================================================================
# SUCCESS LOGGING
# ============================================================================

# Log successful operations for future reference
log_successful_operation() {
    local tool_name="$1"
    local tool_input="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')

    # Only log significant operations
    case "$tool_name" in
        Edit|Write|Bash)
            local log_entry
            log_entry=$(cat << EOF
{"timestamp":"${timestamp}","tool":"${tool_name}","success":true,"session":"${SESSION_ID:-unknown}"}
EOF
)
            echo "$log_entry" >> "$LEARNING_LOG"
            ;;
    esac
}

# ============================================================================
# MEMORY TIER MANAGEMENT
# ============================================================================

# Check and update memory tiers based on age and access
update_memory_tiers() {
    local learnings_file="${JARVIS_ROOT}/learnings/global.json"

    if [[ ! -f "$learnings_file" ]]; then
        return
    fi

    if ! command -v jq &>/dev/null; then
        return
    fi

    local current_date
    current_date=$(date '+%Y-%m-%d')
    local cutoff_date
    cutoff_date=$(date -v-${COLD_DEMOTION_DAYS}d '+%Y-%m-%d' 2>/dev/null || date -d "${COLD_DEMOTION_DAYS} days ago" '+%Y-%m-%d' 2>/dev/null || echo "")

    if [[ -z "$cutoff_date" ]]; then
        return
    fi

    # This would be more complex in production - for now just log
    log_debug "Memory tier check: cutoff date = $cutoff_date"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    # Read input from stdin (PostToolUse provides tool execution details)
    local input
    input=$(read_input)

    if [[ -z "$input" ]]; then
        log_warn "No input received"
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

    log_debug "Processing tool: $TOOL_NAME"

    # Detect patterns based on tool type
    detect_code_patterns "$TOOL_NAME" "$TOOL_INPUT"

    # Log successful operation
    log_successful_operation "$TOOL_NAME" "$TOOL_INPUT"

    # Periodic memory tier update (every 10th call)
    if [[ $((RANDOM % 10)) -eq 0 ]]; then
        update_memory_tiers
    fi

    finalize_hook 0
}

# Run in background-safe mode
main "$@"
