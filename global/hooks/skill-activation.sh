#!/usr/bin/env bash
# Hook: skill-activation
# Event: UserPromptSubmit
# Purpose: Recommend skills based on keywords/patterns, manage skill loading and summarization

set -euo pipefail

# Get script directory and source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Initialize hook (optional category - may be skipped under load)
init_hook "skill-activation" "optional"

# ============================================================================
# BYPASS CONDITIONS
# ============================================================================

# Check if this hook is enabled in preferences (default: enabled)
if ! is_hook_enabled "skillActivation" "true"; then
    log_info "Hook disabled in preferences"
    finalize_hook 0
    exit 0
fi

# ============================================================================
# CONFIGURATION
# ============================================================================

JARVIS_ROOT=$(get_jarvis_root)
STATE_FILE="${HOME}/.jarvis/skill-activation-state.json"
RULES_FILE="${JARVIS_ROOT}/global/skills/skill-rules.json"
COMPACTION_MARKER_FILE="${HOME}/.claude/state/compaction-pending.json"

# Fallback to project-local skill-rules if available
if [[ -f ".claude/skills/skill-rules.json" ]]; then
    RULES_FILE=".claude/skills/skill-rules.json"
    log_info "Using project-local skill-rules.json"
fi

# Ensure state directory exists
mkdir -p "$(dirname "$STATE_FILE")" 2>/dev/null || true

# ============================================================================
# COMPACTION RECOVERY
# ============================================================================

# Check if we're recovering from a compaction and need to re-inject skills
check_compaction_recovery() {
    if [[ ! -f "$COMPACTION_MARKER_FILE" ]]; then
        return 1
    fi

    log_info "Compaction marker found - recovering skill context"

    local marker_content
    marker_content=$(cat "$COMPACTION_MARKER_FILE" 2>/dev/null || echo "{}")

    # Extract info from marker
    local active_skill=""
    local in_progress_task=""
    local compaction_time=""

    if command -v jq &>/dev/null; then
        active_skill=$(echo "$marker_content" | jq -r '.active_skill // ""' 2>/dev/null || echo "")
        in_progress_task=$(echo "$marker_content" | jq -r '.in_progress_task // ""' 2>/dev/null || echo "")
        compaction_time=$(echo "$marker_content" | jq -r '.compaction_time // ""' 2>/dev/null || echo "")
    else
        # Fallback parsing without jq
        active_skill=$(echo "$marker_content" | grep -o '"active_skill"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//' || echo "")
        in_progress_task=$(echo "$marker_content" | grep -o '"in_progress_task"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//' || echo "")
        compaction_time=$(echo "$marker_content" | grep -o '"compaction_time"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//' || echo "")
    fi

    # Delete the marker file (consumed)
    rm -f "$COMPACTION_MARKER_FILE"
    log_info "Compaction marker consumed and deleted"

    # Build recovery message
    local recovery_message="⚠️ COMPACTION RECOVERY\n\n"
    recovery_message+="Context was compacted at: ${compaction_time:-unknown}\n\n"

    if [[ -n "$active_skill" ]]; then
        recovery_message+="**Previously Active Skill:** ${active_skill}\n"
        recovery_message+="→ Use \`skill: \"${active_skill}\"\` to reload skill instructions\n\n"
    fi

    if [[ -n "$in_progress_task" ]]; then
        recovery_message+="**In-Progress Task:** ${in_progress_task}\n\n"
    fi

    recovery_message+="**IMPORTANT:** Check your todo list for current phase and continue from there.\n"
    recovery_message+="If following a multi-phase skill (e.g., submit-pr), reload the skill NOW.\n"

    # Output recovery context
    COMPACTION_RECOVERY_MESSAGE="$recovery_message"
    return 0
}

# ============================================================================
# SKILL DEFINITIONS (Embedded fallback if JSON not available)
# ============================================================================

# Default skill triggers (used if skill-rules.json not found)
# Bash 3.2 compatible: using indexed arrays instead of associative arrays
SKILL_NAMES=(
    "session"
    "sub-agent-invocation"
    "test-driven-development"
    "git-expert"
    "debug"
    "codebase-navigation"
    "documentation-research"
    "frontend-design"
    "infra-ops"
)

SKILL_KEYWORDS_LIST=(
    "feature implement build create refactor bug fix multi-step complex implementation"
    "agent agents delegate sub-agent specialist coordination parallel Task"
    "test tdd tests testing implement feature function method class"
    "commit push branch PR merge git version control"
    "debug error failing broken not working investigate issue bug trace"
    "find locate where search codebase structure architecture explore"
    "documentation docs API reference library latest current how to use"
    "design UI interface visual aesthetic creative polished beautiful modern"
    "VPS server SSH deploy Docker Nginx SSL infrastructure DevOps container"
)

SKILL_PRIORITY_LIST=(
    "critical"
    "critical"
    "critical"
    "high"
    "high"
    "high"
    "critical"
    "high"
    "high"
)

# ============================================================================
# FUNCTIONS
# ============================================================================

# Load state file
load_state() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE" 2>/dev/null || echo "{}"
    else
        echo "{}"
    fi
}

# Save state file
save_state() {
    local state="$1"
    echo "$state" > "$STATE_FILE" 2>/dev/null || log_warn "Failed to save state"
}

# Get session recommendations (simple text-based tracking)
get_session_recommendations() {
    local session_id="$1"
    local state
    state=$(load_state)

    # Extract recommendations for this session using grep
    echo "$state" | grep -o "\"${session_id}\":[^}]*" | grep -o '\[.*\]' || echo "[]"
}

# Check if skill already recommended in session
skill_already_recommended() {
    local session_id="$1"
    local skill_name="$2"
    local recommended
    recommended=$(get_session_recommendations "$session_id")

    echo "$recommended" | grep -q "\"$skill_name\"" 2>/dev/null
}

# Add skill to session recommendations
add_recommendation() {
    local session_id="$1"
    local skill_name="$2"

    local state
    state=$(load_state)

    # Simple append (not perfect JSON handling but functional)
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    if echo "$state" | grep -q "\"$session_id\""; then
        # Session exists, would need to update array
        # For simplicity, we'll just log
        log_debug "Adding $skill_name to existing session $session_id"
    else
        # Create new session entry
        log_debug "Creating session entry for $session_id"
    fi
}

# Get skill index by name
get_skill_index() {
    local skill_name="$1"
    local i
    for i in "${!SKILL_NAMES[@]}"; do
        if [[ "${SKILL_NAMES[$i]}" == "$skill_name" ]]; then
            echo "$i"
            return 0
        fi
    done
    echo "-1"
    return 1
}

# Match keywords in prompt
match_keywords() {
    local prompt="$1"
    local skill_index="$2"
    local keywords="${SKILL_KEYWORDS_LIST[$skill_index]:-}"

    if [[ -z "$keywords" ]]; then
        return 1
    fi

    local prompt_lower
    prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

    for keyword in $keywords; do
        if echo "$prompt_lower" | grep -qi "\b$keyword\b" 2>/dev/null; then
            return 0
        fi
    done

    return 1
}

# Get skill priority
get_priority() {
    local skill_index="$1"
    echo "${SKILL_PRIORITY_LIST[$skill_index]:-medium}"
}

# Clean old sessions (older than 7 days)
clean_old_sessions() {
    # Would clean sessions from state file
    # Simplified for now
    log_debug "Session cleanup check"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log_info "Skill activation check started"

    # Check for compaction recovery FIRST
    COMPACTION_RECOVERY_MESSAGE=""
    if check_compaction_recovery; then
        log_info "Compaction recovery detected"
    fi

    # Read input from stdin
    local input
    input=$(cat)

    if [[ -z "$input" ]]; then
        log_warn "No input received"
        # Even with no input, output compaction recovery if present
        if [[ -n "$COMPACTION_RECOVERY_MESSAGE" ]]; then
            echo -e "$COMPACTION_RECOVERY_MESSAGE"
        fi
        exit 0
    fi

    # Parse prompt and session_id
    local prompt
    local session_id
    prompt=$(parse_prompt "$input")
    session_id=$(parse_session_id "$input")

    if [[ -z "$prompt" ]]; then
        log_debug "No prompt in input, skipping"
        # Still output compaction recovery if present
        if [[ -n "$COMPACTION_RECOVERY_MESSAGE" ]]; then
            echo -e "$COMPACTION_RECOVERY_MESSAGE"
        fi
        exit 0
    fi

    log_info "Analyzing prompt for skill matches"

    # Collect matched skills by priority (Bash 3.2 compatible)
    critical_skills=()
    high_skills=()
    medium_skills=()
    low_skills=()

    # Check each skill for matches
    local i
    for i in "${!SKILL_NAMES[@]}"; do
        local skill_name="${SKILL_NAMES[$i]}"

        # Skip if already recommended in this session
        if [[ -n "$session_id" ]] && skill_already_recommended "$session_id" "$skill_name"; then
            log_debug "Skipping already recommended: $skill_name"
            continue
        fi

        if match_keywords "$prompt" "$i"; then
            local priority
            priority=$(get_priority "$i")

            case "$priority" in
                critical) critical_skills+=("$skill_name") ;;
                high)     high_skills+=("$skill_name") ;;
                medium)   medium_skills+=("$skill_name") ;;
                low)      low_skills+=("$skill_name") ;;
            esac

            log_info "Matched skill: $skill_name (priority: $priority)"

            # Track recommendation
            if [[ -n "$session_id" ]]; then
                add_recommendation "$session_id" "$skill_name"
            fi
        fi
    done

    # Build output if any matches found
    local total_matches=$((${#critical_skills[@]} + ${#high_skills[@]} + ${#medium_skills[@]} + ${#low_skills[@]}))

    if [[ $total_matches -eq 0 ]]; then
        log_info "No skill matches found"
        # Still output compaction recovery if present
        if [[ -n "$COMPACTION_RECOVERY_MESSAGE" ]]; then
            echo -e "$COMPACTION_RECOVERY_MESSAGE"
            finalize_hook 0
        fi
        exit 0
    fi

    log_info "Found $total_matches skill matches"

    # Build recommendation output - prepend compaction recovery if present
    local output=""
    if [[ -n "$COMPACTION_RECOVERY_MESSAGE" ]]; then
        output+="$COMPACTION_RECOVERY_MESSAGE\n"
        output+="---\n\n"
    fi
    output+="SKILL ACTIVATION CHECK\n\n"

    if [[ ${#critical_skills[@]} -gt 0 ]]; then
        output+="CRITICAL SKILLS (REQUIRED):\n"
        for skill in "${critical_skills[@]}"; do
            output+="  -> $skill\n"
        done
        output+="\n"
    fi

    if [[ ${#high_skills[@]} -gt 0 ]]; then
        output+="RECOMMENDED SKILLS:\n"
        for skill in "${high_skills[@]}"; do
            output+="  -> $skill\n"
        done
        output+="\n"
    fi

    if [[ ${#medium_skills[@]} -gt 0 ]]; then
        output+="SUGGESTED SKILLS:\n"
        for skill in "${medium_skills[@]}"; do
            output+="  -> $skill\n"
        done
        output+="\n"
    fi

    if [[ ${#low_skills[@]} -gt 0 ]]; then
        output+="OPTIONAL SKILLS:\n"
        for skill in "${low_skills[@]}"; do
            output+="  -> $skill\n"
        done
        output+="\n"
    fi

    output+="ACTION: Use Skill tool BEFORE responding to load relevant skills.\n"

    # Print output (Claude Code will capture and display this)
    echo -e "$output"

    finalize_hook 0
}

# Run main function
main
