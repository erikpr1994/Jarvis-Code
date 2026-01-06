#!/usr/bin/env bash
# Hook: session-start
# Event: SessionStart
# Purpose: Initialize session with skills, detect continuation, set context, load preferences

set -euo pipefail

# Get script directory and source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Initialize hook
init_hook "session-start"

# ============================================================================
# CONFIGURATION
# ============================================================================

JARVIS_ROOT=$(get_jarvis_root)
SKILLS_DIR=$(get_skills_dir)
PREFERENCES_FILE="${HOME}/.jarvis/preferences.json"
SESSION_TIMEOUT_MINUTES=240  # 4 hours for session continuation

# ============================================================================
# FUNCTIONS
# ============================================================================

# Load using-skills content
load_using_skills() {
    local skills_file="${SKILLS_DIR}/using-skills/SKILL.md"

    # Try project-local skills first, then global
    if [[ -f ".claude/skills/using-skills/SKILL.md" ]]; then
        skills_file=".claude/skills/using-skills/SKILL.md"
        log_info "Loading project-local using-skills"
    elif [[ -f "${skills_file}" ]]; then
        log_info "Loading global using-skills"
    else
        log_warn "using-skills SKILL.md not found"
        echo ""
        return
    fi

    cat "$skills_file" 2>/dev/null || echo ""
}

# Detect session continuation
detect_session() {
    local session_file
    session_file=$(find_recent_session "$SESSION_TIMEOUT_MINUTES")

    if [[ -n "$session_file" ]]; then
        log_info "Found active session: $session_file"
        echo "continue:$session_file"
    else
        log_info "No active session found, starting fresh"
        echo "fresh:"
    fi
}

# Load warm memory
load_warm_memory() {
    local warm_memory_global="${HOME}/.jarvis/learnings/warm-memory.json"
    local warm_memory_local=".claude/learnings/warm-memory.json"
    local output=""

    # Load global warm memory
    if [[ -f "$warm_memory_global" ]]; then
        local global_content
        global_content=$(cat "$warm_memory_global" 2>/dev/null || echo "")
        if [[ -n "$global_content" ]]; then
            output+="Global Learnings:\n$global_content\n"
        fi
    fi

    # Load local warm memory
    if [[ -f "$warm_memory_local" ]]; then
        local local_content
        local_content=$(cat "$warm_memory_local" 2>/dev/null || echo "")
        if [[ -n "$local_content" ]]; then
            output+="Project Learnings:\n$local_content\n"
        fi
    fi

    echo "$output"
}

# Load user preferences
load_preferences() {
    if [[ -f "$PREFERENCES_FILE" ]]; then
        log_info "Loading user preferences from $PREFERENCES_FILE"
        cat "$PREFERENCES_FILE" 2>/dev/null || echo "{}"
    else
        log_debug "No preferences file found"
        echo "{}"
    fi
}

# Get project context
get_project_context() {
    local context=""

    # Check for project CLAUDE.md
    if [[ -f "CLAUDE.md" ]]; then
        context+="Project has CLAUDE.md configuration. "
        log_info "Project CLAUDE.md detected"
    fi

    # Check for .claude directory
    if [[ -d ".claude" ]]; then
        context+="Project has .claude/ directory. "

        # Count local skills
        if [[ -d ".claude/skills" ]]; then
            local skill_count
            skill_count=$(find .claude/skills -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
            if [[ "$skill_count" -gt 0 ]]; then
                context+="Found $skill_count project-specific skills. "
            fi
        fi
    fi

    # Check git status
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local branch
        branch=$(get_current_branch)
        context+="Git branch: $branch. "

        if is_worktree; then
            context+="Running in git worktree (isolation active). "
        fi

        if has_uncommitted_changes; then
            context+="Has uncommitted changes. "
        fi
    fi

    echo "$context"
}

# Build legacy migration warning (from superpowers)
check_legacy_locations() {
    local warning=""

    # Check for legacy superpowers location
    local legacy_superpowers="${HOME}/.config/superpowers/skills"
    if [[ -d "$legacy_superpowers" ]]; then
        warning+="\n\n**WARNING:** Legacy skills found at ~/.config/superpowers/skills. "
        warning+="Move custom skills to ~/.claude/skills or ~/.jarvis/skills instead."
        log_warn "Legacy superpowers skills directory detected"
    fi

    # Check for legacy codefast location
    local legacy_codefast="${HOME}/.config/codefast/skills"
    if [[ -d "$legacy_codefast" ]]; then
        warning+="\n\n**WARNING:** Legacy skills found at ~/.config/codefast/skills. "
        warning+="Move custom skills to ~/.claude/skills or ~/.jarvis/skills instead."
        log_warn "Legacy codefast skills directory detected"
    fi

    echo "$warning"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log_info "Starting session initialization"

    # 1. Load using-skills content
    local skills_content
    skills_content=$(load_using_skills)

    # 2. Detect session continuation
    local session_status
    session_status=$(detect_session)
    local session_mode="${session_status%%:*}"
    local session_file="${session_status#*:}"

    # 3. Get project context
    local project_context
    project_context=$(get_project_context)

    # 4. Load warm memory
    local warm_memory
    warm_memory=$(load_warm_memory)

    # 5. Check for legacy locations
    local legacy_warning
    legacy_warning=$(check_legacy_locations)

    # 6. Build session context message
    local session_message=""
    if [[ "$session_mode" == "continue" ]]; then
        session_message="**Session Continuation Detected**\n"
        session_message+="Active session file: $session_file\n"

        # Load session content
        if [[ -f "$session_file" ]]; then
            local session_content
            session_content=$(cat "$session_file" | head -n 50)  # Limit to first 50 lines to avoid bloat
            session_message+="\n--- SESSION FILE PREVIEW ---\n"
            session_message+="${session_content}\n"
            session_message+="--- END PREVIEW ---\n"
            session_message+="To read full session: read $session_file\n"
        fi
    else
        session_message="**Fresh Session Started**\n"
        session_message+="No active session found within the last ${SESSION_TIMEOUT_MINUTES} minutes.\n"
        session_message+="To start tracking: /session new\n"
    fi

    # 6. Build final context
    local final_context=""

    # Add Jarvis header
    final_context+="<JARVIS_SESSION_CONTEXT>\n"
    final_context+="You have Jarvis superpowers activated.\n\n"

    # Add using-skills content if available
    if [[ -n "$skills_content" ]]; then
        final_context+="## Using Skills\n"
        final_context+="${skills_content}\n\n"
    fi

    # Add session status
    final_context+="## Session Status\n"
    final_context+="${session_message}\n"

    # Add project context if available
    if [[ -n "$project_context" ]]; then
        final_context+="## Project Context\n"
        final_context+="${project_context}\n\n"
    fi

    # Add warm memory if available
    if [[ -n "$warm_memory" ]]; then
        final_context+="## Active Learnings (Warm Memory)\n"
        final_context+="${warm_memory}\n\n"
    fi

    # Add legacy warnings if any
    if [[ -n "$legacy_warning" ]]; then
        final_context+="${legacy_warning}\n"
    fi

    final_context+="</JARVIS_SESSION_CONTEXT>"

    # 7. Output JSON response
    local escaped_context
    escaped_context=$(escape_for_json "$final_context")

    cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "${escaped_context}"
  }
}
EOF

    finalize_hook 0
}

# Run main function
main
