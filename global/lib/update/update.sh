#!/usr/bin/env bash
# Jarvis Update System - Main Orchestration
# Updates global ~/.claude and optionally current project's .claude folder

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

# Get script directory and repo root
# Script is at: global/lib/update/update.sh
# Repo root is 3 levels up: ../../..
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JARVIS_REPO="${JARVIS_REPO:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"

# Paths
GLOBAL_CLAUDE="${HOME}/.claude"
VERSION_FILE="${GLOBAL_CLAUDE}/.jarvis-version"

# Source dependencies
source "${SCRIPT_DIR}/sync.sh"
source "${SCRIPT_DIR}/project-update.sh"

# ============================================================================
# VERSION CHECKING
# ============================================================================

get_installed_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        cat "$VERSION_FILE"
    else
        echo "0.0.0"
    fi
}

get_repo_version() {
    local version_file="${JARVIS_REPO}/VERSION"
    if [[ -f "$version_file" ]]; then
        cat "$version_file"
    else
        echo "1.0.0"
    fi
}

# Compare versions (returns 0 if $1 >= $2)
version_gte() {
    local v1="$1"
    local v2="$2"

    # Split versions
    local v1_major v1_minor v1_patch
    local v2_major v2_minor v2_patch

    IFS='.' read -r v1_major v1_minor v1_patch <<< "$v1"
    IFS='.' read -r v2_major v2_minor v2_patch <<< "$v2"

    # Compare
    [[ "${v1_major:-0}" -gt "${v2_major:-0}" ]] && return 0
    [[ "${v1_major:-0}" -lt "${v2_major:-0}" ]] && return 1
    [[ "${v1_minor:-0}" -gt "${v2_minor:-0}" ]] && return 0
    [[ "${v1_minor:-0}" -lt "${v2_minor:-0}" ]] && return 1
    [[ "${v1_patch:-0}" -ge "${v2_patch:-0}" ]] && return 0
    return 1
}

# ============================================================================
# GLOBAL UPDATE
# ============================================================================

update_global() {
    local force="${1:-false}"
    local dry_run="${2:-false}"
    local no_backup="${3:-false}"

    echo "=== Updating Global Installation ==="
    echo "Source: $JARVIS_REPO"
    echo "Target: $GLOBAL_CLAUDE"
    echo ""

    local installed_version repo_version
    installed_version=$(get_installed_version)
    repo_version=$(get_repo_version)

    echo "Installed version: $installed_version"
    echo "Available version: $repo_version"
    echo ""

    # Check if update needed
    if version_gte "$installed_version" "$repo_version" && [[ "$force" != "true" ]]; then
        echo "Already up to date! Use --force to reinstall."
        return 0
    fi

    # Create backup
    if [[ "$no_backup" != "true" && "$dry_run" != "true" && -d "$GLOBAL_CLAUDE" ]]; then
        echo "Creating backup..."
        local backup_path
        backup_path=$(create_backup "$GLOBAL_CLAUDE" "${HOME}")
        echo "Backup: $backup_path"
        echo ""
    fi

    # Sync components
    echo "--- Hooks ---"
    sync_directory "${JARVIS_REPO}/global/hooks" "${GLOBAL_CLAUDE}/hooks" "$force" "$dry_run"

    echo ""
    echo "--- Hook Libraries ---"
    sync_directory "${JARVIS_REPO}/global/hooks/lib" "${GLOBAL_CLAUDE}/hooks/lib" "$force" "$dry_run"

    echo ""
    echo "--- Skills ---"
    sync_directory "${JARVIS_REPO}/global/skills" "${GLOBAL_CLAUDE}/skills" "$force" "$dry_run"

    echo ""
    echo "--- Commands ---"
    sync_directory "${JARVIS_REPO}/global/commands" "${GLOBAL_CLAUDE}/commands" "$force" "$dry_run"

    echo ""
    echo "--- Agents ---"
    sync_directory "${JARVIS_REPO}/global/agents" "${GLOBAL_CLAUDE}/agents" "$force" "$dry_run"

    echo ""
    echo "--- Libraries ---"
    sync_directory "${JARVIS_REPO}/global/lib" "${GLOBAL_CLAUDE}/lib" "$force" "$dry_run"

    echo ""
    echo "--- Rules ---"
    if [[ -d "${JARVIS_REPO}/global/rules" ]]; then
        sync_directory "${JARVIS_REPO}/global/rules" "${GLOBAL_CLAUDE}/rules" "$force" "$dry_run"
    fi

    echo ""
    echo "--- Settings ---"
    # Sync Claude Code settings.json (correct schema format)
    # Note: sync_file returns 2 for unchanged files, so we use || true
    if [[ -f "${JARVIS_REPO}/global/settings.json" ]]; then
        sync_file "${JARVIS_REPO}/global/settings.json" "${GLOBAL_CLAUDE}/settings.json" "$force" "$dry_run" || true
    fi

    # Sync Jarvis-specific config to separate file
    if [[ -f "${JARVIS_REPO}/global/jarvis.json" ]]; then
        mkdir -p "${GLOBAL_CLAUDE}/config"
        sync_file "${JARVIS_REPO}/global/jarvis.json" "${GLOBAL_CLAUDE}/config/jarvis.json" "$force" "$dry_run" || true
    fi

    # Update version file
    if [[ "$dry_run" != "true" ]]; then
        echo "$repo_version" > "$VERSION_FILE"
        echo ""
        echo "Version updated to: $repo_version"
    fi

    echo ""
    echo "Global update complete!"
}

# ============================================================================
# SCOPED UPDATES
# ============================================================================

update_skills() {
    local force="${1:-false}"
    local dry_run="${2:-false}"

    echo "=== Updating Skills ==="
    sync_directory "${JARVIS_REPO}/global/skills" "${GLOBAL_CLAUDE}/skills" "$force" "$dry_run"
}

update_hooks() {
    local force="${1:-false}"
    local dry_run="${2:-false}"

    echo "=== Updating Hooks ==="
    sync_directory "${JARVIS_REPO}/global/hooks" "${GLOBAL_CLAUDE}/hooks" "$force" "$dry_run"
    echo ""
    echo "--- Hook Libraries ---"
    sync_directory "${JARVIS_REPO}/global/hooks/lib" "${GLOBAL_CLAUDE}/hooks/lib" "$force" "$dry_run"
}

update_commands() {
    local force="${1:-false}"
    local dry_run="${2:-false}"

    echo "=== Updating Commands ==="
    sync_directory "${JARVIS_REPO}/global/commands" "${GLOBAL_CLAUDE}/commands" "$force" "$dry_run"
}

update_agents() {
    local force="${1:-false}"
    local dry_run="${2:-false}"

    echo "=== Updating Agents ==="
    sync_directory "${JARVIS_REPO}/global/agents" "${GLOBAL_CLAUDE}/agents" "$force" "$dry_run"
}

# ============================================================================
# VALIDATION
# ============================================================================

validate_installation() {
    echo "=== Validating Installation ==="

    local errors=0

    # Check hook syntax
    echo "Checking hook syntax..."
    for hook in "${GLOBAL_CLAUDE}"/hooks/*.sh; do
        if [[ -f "$hook" ]]; then
            if ! bash -n "$hook" 2>/dev/null; then
                echo "  ERROR: Syntax error in $(basename "$hook")"
                ((errors++))
            fi
        fi
    done

    # Check settings.json
    echo "Checking settings.json..."
    if [[ -f "${GLOBAL_CLAUDE}/settings.json" ]]; then
        if ! jq empty "${GLOBAL_CLAUDE}/settings.json" 2>/dev/null; then
            echo "  ERROR: Invalid JSON in settings.json"
            ((errors++))
        fi
    fi

    # Check required directories
    echo "Checking directory structure..."
    for dir in hooks skills commands agents lib; do
        if [[ ! -d "${GLOBAL_CLAUDE}/${dir}" ]]; then
            echo "  WARNING: Missing directory: $dir"
        fi
    done

    echo ""
    if [[ $errors -eq 0 ]]; then
        echo "Validation passed!"
        return 0
    else
        echo "Validation failed with $errors errors"
        return 1
    fi
}

# ============================================================================
# MAIN UPDATE ORCHESTRATION
# ============================================================================

# Main update function
# Args: scope, force, dry_run, no_backup, project_dir
jarvis_update() {
    local scope="${1:-all}"
    local force="${2:-false}"
    local dry_run="${3:-false}"
    local no_backup="${4:-false}"
    local project_dir="${5:-}"

    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Jarvis Update System                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""

    if [[ "$dry_run" == "true" ]]; then
        echo "DRY RUN MODE - No changes will be made"
        echo ""
    fi

    case "$scope" in
        all)
            update_global "$force" "$dry_run" "$no_backup"
            if [[ -n "$project_dir" ]]; then
                echo ""
                echo "════════════════════════════════════════════════════════════════"
                echo ""
                update_project "$project_dir" "$JARVIS_REPO" "$force" "$dry_run" "$no_backup"
            fi
            ;;
        global)
            update_global "$force" "$dry_run" "$no_backup"
            ;;
        project)
            if [[ -z "$project_dir" ]]; then
                project_dir="."
            fi
            update_project "$project_dir" "$JARVIS_REPO" "$force" "$dry_run" "$no_backup"
            ;;
        skills)
            update_skills "$force" "$dry_run"
            ;;
        hooks)
            update_hooks "$force" "$dry_run"
            ;;
        commands)
            update_commands "$force" "$dry_run"
            ;;
        agents)
            update_agents "$force" "$dry_run"
            ;;
        *)
            echo "Unknown scope: $scope"
            echo "Valid scopes: all, global, project, skills, hooks, commands, agents"
            return 1
            ;;
    esac

    # Validate after update (unless dry run)
    if [[ "$dry_run" != "true" && "$scope" != "project" ]]; then
        echo ""
        echo "════════════════════════════════════════════════════════════════"
        echo ""
        validate_installation
    fi
}

# ============================================================================
# CLI INTERFACE
# ============================================================================

show_help() {
    cat << 'EOF'
Jarvis Update System

Usage: update.sh [scope] [options]

Scopes:
  all       Update global ~/.claude and current project (default)
  global    Update only global ~/.claude installation
  project   Update only current project's .claude folder
  skills    Update only skills
  hooks     Update only hooks
  commands  Update only commands
  agents    Update only agents

Options:
  --force       Update even if files are user-modified
  --dry-run     Show what would change without applying
  --no-backup   Skip backup creation
  --project DIR Specify project directory (default: current)
  --help        Show this help message

Examples:
  update.sh                          # Update everything
  update.sh global                   # Update only global installation
  update.sh project --project ~/app  # Update specific project
  update.sh skills --dry-run         # Preview skill updates
  update.sh all --force              # Force update everything
EOF
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Parse arguments
    scope="all"
    force="false"
    dry_run="false"
    no_backup="false"
    project_dir=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                force="true"
                shift
                ;;
            --dry-run)
                dry_run="true"
                shift
                ;;
            --no-backup)
                no_backup="true"
                shift
                ;;
            --project)
                project_dir="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            all|global|project|skills|hooks|commands|agents)
                scope="$1"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    jarvis_update "$scope" "$force" "$dry_run" "$no_backup" "$project_dir"
fi
