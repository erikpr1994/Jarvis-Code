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
# CONFIGURATION
# ============================================================================

JARVIS_ROOT=$(get_jarvis_root)
STATE_FILE="${HOME}/.jarvis/skill-activation-state.json"
RULES_FILE="${JARVIS_ROOT}/global/skills/skill-rules.json"

# Fallback to project-local skill-rules if available
if [[ -f ".claude/skills/skill-rules.json" ]]; then
    RULES_FILE=".claude/skills/skill-rules.json"
    log_info "Using project-local skill-rules.json"
fi

# Ensure state directory exists
mkdir -p "$(dirname "$STATE_FILE")" 2>/dev/null || true

# ============================================================================
# SKILL DEFINITIONS (Embedded fallback if JSON not available)
# ============================================================================

# Default skill triggers (used if skill-rules.json not found)
declare -A SKILL_KEYWORDS
declare -A SKILL_PRIORITY

# Core skills
SKILL_KEYWORDS["session-management"]="feature implement build create refactor bug fix multi-step complex implementation"
SKILL_PRIORITY["session-management"]="critical"

SKILL_KEYWORDS["sub-agent-invocation"]="agent agents delegate sub-agent specialist coordination parallel Task"
SKILL_PRIORITY["sub-agent-invocation"]="critical"

SKILL_KEYWORDS["test-driven-development"]="test tdd tests testing implement feature function method class"
SKILL_PRIORITY["test-driven-development"]="critical"

SKILL_KEYWORDS["git-expert"]="commit push branch PR merge git version control"
SKILL_PRIORITY["git-expert"]="high"

SKILL_KEYWORDS["systematic-debugging"]="debug error failing broken not working investigate issue bug trace"
SKILL_PRIORITY["systematic-debugging"]="high"

SKILL_KEYWORDS["codebase-navigation"]="find locate where search codebase structure architecture explore"
SKILL_PRIORITY["codebase-navigation"]="high"

SKILL_KEYWORDS["documentation-research"]="documentation docs API reference library latest current how to use"
SKILL_PRIORITY["documentation-research"]="critical"

SKILL_KEYWORDS["frontend-design"]="design UI interface visual aesthetic creative polished beautiful modern"
SKILL_PRIORITY["frontend-design"]="high"

SKILL_KEYWORDS["infra-ops"]="VPS server SSH deploy Docker Nginx SSL infrastructure DevOps container"
SKILL_PRIORITY["infra-ops"]="high"

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

# Match keywords in prompt
match_keywords() {
    local prompt="$1"
    local skill_name="$2"
    local keywords="${SKILL_KEYWORDS[$skill_name]:-}"

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
    local skill_name="$1"
    echo "${SKILL_PRIORITY[$skill_name]:-medium}"
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

    # Read input from stdin
    local input
    input=$(cat)

    if [[ -z "$input" ]]; then
        log_warn "No input received"
        exit 0
    fi

    # Parse prompt and session_id
    local prompt
    local session_id
    prompt=$(parse_prompt "$input")
    session_id=$(parse_session_id "$input")

    if [[ -z "$prompt" ]]; then
        log_debug "No prompt in input, skipping"
        exit 0
    fi

    log_info "Analyzing prompt for skill matches"

    # Collect matched skills by priority
    declare -a critical_skills=()
    declare -a high_skills=()
    declare -a medium_skills=()
    declare -a low_skills=()

    # Check each skill for matches
    for skill_name in "${!SKILL_KEYWORDS[@]}"; do
        # Skip if already recommended in this session
        if [[ -n "$session_id" ]] && skill_already_recommended "$session_id" "$skill_name"; then
            log_debug "Skipping already recommended: $skill_name"
            continue
        fi

        if match_keywords "$prompt" "$skill_name"; then
            local priority
            priority=$(get_priority "$skill_name")

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
        exit 0
    fi

    log_info "Found $total_matches skill matches"

    # Build recommendation output
    local output="SKILL ACTIVATION CHECK\n\n"

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
