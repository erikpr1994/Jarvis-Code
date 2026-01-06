#!/usr/bin/env bash
# Jarvis Pre-Compact Preserve Hook
# Type: PreCompact
# Purpose: Saves session state before context compaction
#
# This hook runs before Claude's context compaction to:
# - Preserve current task state
# - Save progress and decisions made
# - Capture hot memory learnings
# - Ensure continuity after compaction

set -euo pipefail

# Load common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Initialize hook
init_hook "pre-compact-preserve"

# Configuration
JARVIS_ROOT="${JARVIS_ROOT:-$HOME/.jarvis}"
TASKS_DIR=".claude/tasks"
SESSION_STATE_FILE="${TASKS_DIR}/session-state.json"
HOT_MEMORY_FILE="${JARVIS_ROOT}/learnings/.hot-memory.json"
COMPACT_ARCHIVE_DIR="${JARVIS_ROOT}/archive/compactions"

# Ensure directories exist
mkdir -p "$TASKS_DIR" "$COMPACT_ARCHIVE_DIR" "$(dirname "$HOT_MEMORY_FILE")"

# ============================================================================
# STATE EXTRACTION
# ============================================================================

# Read JSON input from stdin
read_input() {
    local input=""
    while IFS= read -r line; do
        input+="$line"
    done
    echo "$input"
}

# Extract current conversation state
extract_conversation_state() {
    local input="$1"

    # Extract relevant fields from PreCompact event
    SESSION_ID=$(echo "$input" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//' || echo "session-$(date +%Y%m%d%H%M%S)")
    TOKENS_USED=$(echo "$input" | grep -o '"tokens_used"[[:space:]]*:[[:space:]]*[0-9]*' | sed 's/.*: *//' || echo "0")
    COMPACT_REASON=$(echo "$input" | grep -o '"reason"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//' || echo "context_limit")
}

# Find and read current task file
find_current_task() {
    local task_file=""

    # Look for most recent task file
    if [[ -d "$TASKS_DIR" ]]; then
        task_file=$(find "$TASKS_DIR" -name "*.md" -type f -mmin -60 2>/dev/null | head -1 || echo "")
    fi

    if [[ -n "$task_file" && -f "$task_file" ]]; then
        cat "$task_file"
    else
        echo ""
    fi
}

# Extract task progress from task file
extract_task_progress() {
    local task_content="$1"

    if [[ -z "$task_content" ]]; then
        echo '{"current_task": null, "progress": [], "decisions": []}'
        return
    fi

    # Parse task content for status indicators
    local completed_count=0
    local pending_count=0
    local in_progress_count=0

    completed_count=$(echo "$task_content" | grep -c '\[x\]\|:white_check_mark:\|DONE\|COMPLETED' 2>/dev/null || echo "0")
    pending_count=$(echo "$task_content" | grep -c '\[ \]\|:hourglass:\|TODO\|PENDING' 2>/dev/null || echo "0")
    in_progress_count=$(echo "$task_content" | grep -c '\[-\]\|:construction:\|IN.PROGRESS\|WIP' 2>/dev/null || echo "0")

    # Extract task title (first heading)
    local task_title
    task_title=$(echo "$task_content" | grep -m1 '^#' | sed 's/^#* *//' || echo "Unknown Task")

    # Extract decisions (lines with "Decision:" or similar markers)
    local decisions=""
    decisions=$(echo "$task_content" | grep -i 'decision:\|decided:\|chose:\|using:' | head -5 || echo "")

    cat << EOF
{
    "current_task": "$(escape_for_json "$task_title")",
    "progress": {
        "completed": $completed_count,
        "in_progress": $in_progress_count,
        "pending": $pending_count
    },
    "decisions": "$(escape_for_json "$decisions")"
}
EOF
}

# ============================================================================
# HOT MEMORY PRESERVATION
# ============================================================================

# Save hot memory learnings before compaction
preserve_hot_memory() {
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')
    local session_patterns_file="${JARVIS_ROOT}/learnings/.session-patterns.json"

    # Read current session patterns
    local session_patterns='{}'
    if [[ -f "$session_patterns_file" ]]; then
        session_patterns=$(cat "$session_patterns_file" 2>/dev/null || echo '{}')
    fi

    # Read existing hot memory
    local hot_memory='{}'
    if [[ -f "$HOT_MEMORY_FILE" ]]; then
        hot_memory=$(cat "$HOT_MEMORY_FILE" 2>/dev/null || echo '{}')
    fi

    # Merge session patterns into hot memory
    if command -v jq &>/dev/null; then
        local merged
        merged=$(jq -s '
            .[0] as $hot |
            .[1] as $session |
            $hot * {
                "last_compact": "'"$timestamp"'",
                "session_patterns": $session.patterns,
                "preserved_at": "'"$timestamp"'"
            }
        ' <(echo "$hot_memory") <(echo "$session_patterns") 2>/dev/null || echo "$hot_memory")

        echo "$merged" > "$HOT_MEMORY_FILE"
    else
        # Fallback without jq
        cat > "$HOT_MEMORY_FILE" << EOF
{
    "last_compact": "${timestamp}",
    "preserved_at": "${timestamp}",
    "note": "Preserved before compaction"
}
EOF
    fi

    log_info "Hot memory preserved at $timestamp"
}

# ============================================================================
# SESSION STATE SAVING
# ============================================================================

# Save complete session state
save_session_state() {
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')
    local date_str
    date_str=$(date '+%Y-%m-%d')

    # Get task progress
    local task_content
    task_content=$(find_current_task)
    local task_progress
    task_progress=$(extract_task_progress "$task_content")

    # Get git context if available
    local git_branch=""
    local git_status=""
    if git rev-parse --git-dir &>/dev/null; then
        git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
        git_status=$(git status --porcelain 2>/dev/null | head -10 | tr '\n' ';' || echo "")
    fi

    # Get recent files modified
    local recent_files=""
    recent_files=$(find . -type f -mmin -30 -not -path "./.git/*" -not -path "./node_modules/*" 2>/dev/null | head -10 | tr '\n' ',' || echo "")

    # Create session state
    cat > "$SESSION_STATE_FILE" << EOF
{
    "session_id": "${SESSION_ID:-unknown}",
    "timestamp": "${timestamp}",
    "compact_reason": "${COMPACT_REASON:-context_limit}",
    "tokens_used": ${TOKENS_USED:-0},
    "task": ${task_progress},
    "context": {
        "git_branch": "$(escape_for_json "$git_branch")",
        "uncommitted_changes": "$(escape_for_json "$git_status")",
        "recent_files": "$(escape_for_json "$recent_files")",
        "working_directory": "$(pwd)"
    },
    "hot_memory": {
        "preserved": true,
        "file": "${HOT_MEMORY_FILE}"
    },
    "recovery_hints": {
        "task_file": "${TASKS_DIR}",
        "continue_from": "Check session-state.json for context"
    }
}
EOF

    log_info "Session state saved to $SESSION_STATE_FILE"

    # Also archive this state
    archive_session_state "$timestamp"
}

# Archive session state for historical reference
archive_session_state() {
    local timestamp="$1"
    local archive_file="${COMPACT_ARCHIVE_DIR}/compact-$(date '+%Y%m%d-%H%M%S').json"

    if [[ -f "$SESSION_STATE_FILE" ]]; then
        cp "$SESSION_STATE_FILE" "$archive_file"
        log_debug "Session state archived to $archive_file"
    fi
}

# ============================================================================
# WARM MEMORY PROMOTION
# ============================================================================

# Promote important hot memory items to warm tier before compaction
promote_to_warm_memory() {
    local session_patterns_file="${JARVIS_ROOT}/learnings/.session-patterns.json"
    local warm_memory_file="${JARVIS_ROOT}/learnings/warm-memory.json"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')

    if [[ ! -f "$session_patterns_file" ]]; then
        return
    fi

    # Initialize warm memory if needed
    if [[ ! -f "$warm_memory_file" ]]; then
        echo '{"warm_memory":{"preferences":[],"patterns":[],"context":{}}}' > "$warm_memory_file"
    fi

    if ! command -v jq &>/dev/null; then
        log_warn "jq not available, skipping warm memory promotion"
        return
    fi

    # Get high-frequency patterns from session (count >= 3)
    local high_freq_patterns
    high_freq_patterns=$(jq -r '
        .patterns | to_entries[] |
        select(.value.count >= 3) |
        {
            id: .key,
            description: .key,
            confidence: ((.value.count / 10) | if . > 1 then 1 else . end),
            last_accessed: .value.last_seen,
            access_count: .value.count,
            source: "session_patterns"
        }
    ' "$session_patterns_file" 2>/dev/null || echo "")

    if [[ -z "$high_freq_patterns" ]]; then
        log_debug "No patterns to promote to warm memory"
        return
    fi

    # Merge into warm memory
    local updated
    updated=$(jq --argjson patterns "[$high_freq_patterns]" \
                 --arg ts "$timestamp" '
        .warm_memory.patterns = (
            (.warm_memory.patterns // []) + $patterns | unique_by(.id)
        ) |
        .warm_memory.last_updated = $ts
    ' "$warm_memory_file" 2>/dev/null)

    if [[ -n "$updated" ]]; then
        echo "$updated" > "$warm_memory_file"
        log_info "Promoted patterns to warm memory"
    fi
}

# ============================================================================
# OUTPUT
# ============================================================================

# Output preserved context for Claude to use after compaction
output_preserved_context() {
    local session_state=""
    if [[ -f "$SESSION_STATE_FILE" ]]; then
        session_state=$(cat "$SESSION_STATE_FILE" 2>/dev/null || echo "{}")
    fi

    # Extract key information for the compact context
    local task_info=""
    local git_info=""
    local hint=""

    if command -v jq &>/dev/null && [[ -n "$session_state" ]]; then
        task_info=$(echo "$session_state" | jq -r '.task.current_task // "No active task"' 2>/dev/null || echo "")
        git_info=$(echo "$session_state" | jq -r '.context.git_branch // ""' 2>/dev/null || echo "")
    fi

    # Create context message
    local context_message="[Session State Preserved]
- Task: ${task_info:-Unknown}
- Branch: ${git_info:-N/A}
- State saved to: $SESSION_STATE_FILE
- Hot memory preserved for continuity"

    output_context "$context_message"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log_info "Pre-compact preservation starting"

    # Read input from stdin
    local input
    input=$(read_input)

    # Extract conversation state
    extract_conversation_state "$input"

    log_info "Preserving session state (reason: ${COMPACT_REASON:-unknown})"

    # Preserve hot memory first
    preserve_hot_memory

    # Promote important items to warm memory
    promote_to_warm_memory

    # Save complete session state
    save_session_state

    # Output context for post-compaction
    output_preserved_context

    log_info "Pre-compact preservation complete"
    finalize_hook 0
}

main "$@"
