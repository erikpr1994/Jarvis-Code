#!/usr/bin/env bash
# Project Update Library for Jarvis Update System
# Handles updating a project's .claude folder and CLAUDE.md

set -euo pipefail

# Get script directory (handle being sourced)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Source dependencies
source "${SCRIPT_DIR}/sync.sh"

# ============================================================================
# PROJECT UPDATE
# ============================================================================

# Update a project's .claude folder and CLAUDE.md
# Args: $1=project_dir, $2=jarvis_repo, $3=force, $4=dry_run, $5=no_backup
update_project() {
    local project_dir="${1:-.}"
    local jarvis_repo="${2:-${HOME}/Documents/claude-code-tools}"
    local force="${3:-false}"
    local dry_run="${4:-false}"
    local no_backup="${5:-false}"

    echo "Updating project: $project_dir"
    echo "Source: $jarvis_repo"
    echo ""

    # Verify project has .claude folder
    if [[ ! -d "${project_dir}/.claude" ]]; then
        echo "error: No .claude folder found in $project_dir"
        echo "Run /init first to initialize Jarvis in this project"
        return 1
    fi

    # Verify jarvis repo exists
    if [[ ! -d "$jarvis_repo" ]]; then
        echo "error: Jarvis repo not found at $jarvis_repo"
        return 1
    fi

    # Create backup if requested
    if [[ "$no_backup" != "true" && "$dry_run" != "true" ]]; then
        echo "Creating backup..."
        local backup_path
        backup_path=$(create_backup "${project_dir}/.claude" "${project_dir}")
        echo "Backup created: $backup_path"
        echo ""
    fi

    # Update components
    local updated=0
    local skipped=0

    # 1. Update hooks (if project uses local hooks, not symlinks)
    if [[ -d "${project_dir}/.claude/hooks" && ! -L "${project_dir}/.claude/hooks" ]]; then
        echo "=== Updating hooks ==="
        sync_directory "${jarvis_repo}/global/hooks" "${project_dir}/.claude/hooks" "$force" "$dry_run"
        ((updated++)) || true
    else
        echo "Hooks: Using symlinks, skipping"
        ((skipped++)) || true
    fi

    # 2. Update hook lib
    if [[ -d "${project_dir}/.claude/hooks/lib" && ! -L "${project_dir}/.claude/hooks/lib" ]]; then
        echo ""
        echo "=== Updating hooks/lib ==="
        sync_directory "${jarvis_repo}/global/hooks/lib" "${project_dir}/.claude/hooks/lib" "$force" "$dry_run"
    fi

    # 3. Update commands (if local)
    if [[ -d "${project_dir}/.claude/commands" && ! -L "${project_dir}/.claude/commands" ]]; then
        echo ""
        echo "=== Updating commands ==="
        sync_directory "${jarvis_repo}/global/commands" "${project_dir}/.claude/commands" "$force" "$dry_run"
        ((updated++)) || true
    fi

    # 4. Update CLAUDE.md with preserved customizations
    echo ""
    echo "=== Updating CLAUDE.md ==="
    update_project_claude_md "$project_dir" "$jarvis_repo" "$force" "$dry_run"

    # 5. Update settings.json (merge, don't replace)
    echo ""
    echo "=== Updating settings ==="
    update_project_settings "$project_dir" "$jarvis_repo" "$dry_run"

    echo ""
    echo "Project update complete!"
}

# Update project's CLAUDE.md preserving customizations
update_project_claude_md() {
    local project_dir="$1"
    local jarvis_repo="$2"
    local force="${3:-false}"
    local dry_run="${4:-false}"

    local project_claude="${project_dir}/CLAUDE.md"
    local template="${jarvis_repo}/templates/CLAUDE.md.template"

    if [[ ! -f "$project_claude" ]]; then
        echo "No CLAUDE.md found, skipping"
        return 0
    fi

    if [[ ! -f "$template" ]]; then
        echo "Template not found, skipping CLAUDE.md update"
        return 0
    fi

    # Check for user modifications
    if is_user_modified "$project_claude" && [[ "$force" != "true" ]]; then
        echo "CLAUDE.md has user modifications marker, skipping (use --force to override)"
        return 0
    fi

    # Extract and preserve user customizations
    local user_section
    user_section=$(extract_user_section "$project_claude")

    if [[ "$dry_run" == "true" ]]; then
        if [[ -n "$user_section" ]]; then
            echo "Would update CLAUDE.md (preserving user customizations)"
        else
            echo "Would update CLAUDE.md"
        fi
        return 0
    fi

    # For now, just preserve user section - full template regeneration would need init
    if [[ -n "$user_section" ]]; then
        # Backup current file
        cp "$project_claude" "${project_claude}.pre-update"

        # Ensure user section exists in file
        if ! grep -q "$USER_SECTION_START" "$project_claude"; then
            echo "" >> "$project_claude"
            echo "$USER_SECTION_START" >> "$project_claude"
            echo "$user_section" >> "$project_claude"
            echo "$USER_SECTION_END" >> "$project_claude"
        fi

        echo "CLAUDE.md: Preserved user customizations"
    else
        echo "CLAUDE.md: No user customizations to preserve"
    fi
}

# Update project settings (merge new fields, preserve existing)
update_project_settings() {
    local project_dir="$1"
    local jarvis_repo="$2"
    local dry_run="${3:-false}"

    local project_settings="${project_dir}/.claude/settings.json"
    local global_settings="${jarvis_repo}/global/settings.json"

    if [[ ! -f "$project_settings" ]]; then
        echo "No settings.json found, skipping"
        return 0
    fi

    if [[ ! -f "$global_settings" ]]; then
        echo "Global settings not found, skipping"
        return 0
    fi

    if [[ "$dry_run" == "true" ]]; then
        echo "Would merge new settings fields"
        return 0
    fi

    # Merge: add new keys from global, keep existing project values
    local temp_file
    temp_file=$(mktemp)

    # Use jq to merge (project values take precedence)
    if command -v jq >/dev/null 2>&1; then
        jq -s '.[0] * .[1]' "$global_settings" "$project_settings" > "$temp_file"
        mv "$temp_file" "$project_settings"
        echo "Settings merged (new fields added, existing preserved)"
    else
        echo "jq not available, skipping settings merge"
        rm -f "$temp_file"
    fi
}

# ============================================================================
# CLI INTERFACE
# ============================================================================

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
    case "${1:-}" in
        update)
            update_project "${2:-.}" "${3:-}" "${4:-false}" "${5:-false}" "${6:-false}"
            ;;
        claude-md)
            update_project_claude_md "${2:-.}" "${3:-}" "${4:-false}" "${5:-false}"
            ;;
        settings)
            update_project_settings "${2:-.}" "${3:-}" "${4:-false}"
            ;;
        *)
            echo "Usage: $0 {update|claude-md|settings} [args]"
            echo ""
            echo "Commands:"
            echo "  update [project_dir] [jarvis_repo] [force] [dry_run] [no_backup]"
            echo "  claude-md [project_dir] [jarvis_repo] [force] [dry_run]"
            echo "  settings [project_dir] [jarvis_repo] [dry_run]"
            exit 1
            ;;
    esac
fi
