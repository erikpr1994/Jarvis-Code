#!/usr/bin/env bash
# File Sync Library for Jarvis Update System
# Handles file synchronization with user customization preservation

set -euo pipefail

# ============================================================================
# CONSTANTS
# ============================================================================

USER_MODIFIED_MARKER="# JARVIS-USER-MODIFIED"
USER_SECTION_START="<!-- USER CUSTOMIZATIONS -->"
USER_SECTION_END="<!-- END USER CUSTOMIZATIONS -->"

# ============================================================================
# FILE CHECKING
# ============================================================================

# Check if file has user modifications marker
is_user_modified() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    # Check for marker in first 5 lines
    head -5 "$file" 2>/dev/null | grep -q "$USER_MODIFIED_MARKER"
}

# Check if file content differs (ignoring whitespace)
files_differ() {
    local file1="$1"
    local file2="$2"

    if [[ ! -f "$file1" ]] || [[ ! -f "$file2" ]]; then
        return 0  # Different if one doesn't exist
    fi

    ! diff -q "$file1" "$file2" >/dev/null 2>&1
}

# Get file checksum
get_checksum() {
    local file="$1"

    if [[ -f "$file" ]]; then
        if command -v md5sum >/dev/null 2>&1; then
            md5sum "$file" | cut -d' ' -f1
        elif command -v md5 >/dev/null 2>&1; then
            md5 -q "$file"
        else
            # Fallback to cksum
            cksum "$file" | cut -d' ' -f1
        fi
    else
        echo ""
    fi
}

# ============================================================================
# FILE SYNC OPERATIONS
# ============================================================================

# Sync a single file with preservation logic
# Args: $1=source, $2=dest, $3=force (true/false), $4=dry_run (true/false)
# Returns: 0=synced, 1=skipped (user-modified), 2=unchanged, 3=error
sync_file() {
    local source="$1"
    local dest="$2"
    local force="${3:-false}"
    local dry_run="${4:-false}"

    # Source must exist
    if [[ ! -f "$source" ]]; then
        echo "error: Source file not found: $source" >&2
        return 3
    fi

    # If dest doesn't exist, just copy
    if [[ ! -f "$dest" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            echo "CREATE: $dest"
            return 0
        fi
        mkdir -p "$(dirname "$dest")"
        cp "$source" "$dest"
        echo "created: $dest"
        return 0
    fi

    # Check if files are identical
    if ! files_differ "$source" "$dest"; then
        return 2  # Unchanged
    fi

    # Check for user modifications
    if is_user_modified "$dest"; then
        if [[ "$force" != "true" ]]; then
            echo "skipped (user-modified): $dest"
            return 1
        fi
        echo "warning: Overwriting user-modified file: $dest"
    fi

    if [[ "$dry_run" == "true" ]]; then
        echo "UPDATE: $dest"
        return 0
    fi

    cp "$source" "$dest"
    echo "updated: $dest"
    return 0
}

# Sync a directory recursively
# Args: $1=source_dir, $2=dest_dir, $3=force, $4=dry_run
sync_directory() {
    local source_dir="$1"
    local dest_dir="$2"
    local force="${3:-false}"
    local dry_run="${4:-false}"

    local synced=0
    local skipped=0
    local unchanged=0
    local errors=0

    if [[ ! -d "$source_dir" ]]; then
        echo "error: Source directory not found: $source_dir" >&2
        return 1
    fi

    # Find all files in source
    # Note: read returns non-zero at EOF, so we use || true to prevent set -e from exiting
    while IFS= read -r -d '' source_file; do
        local relative_path="${source_file#$source_dir/}"
        local dest_file="${dest_dir}/${relative_path}"

        local result=0
        sync_file "$source_file" "$dest_file" "$force" "$dry_run" || result=$?

        case $result in
            0) ((synced++)) ;;
            1) ((skipped++)) ;;
            2) ((unchanged++)) ;;
            *) ((errors++)) ;;
        esac
    done < <(find "$source_dir" -type f -print0 2>/dev/null) || true

    echo ""
    echo "Sync summary: $synced synced, $skipped skipped, $unchanged unchanged, $errors errors"

    [[ $errors -eq 0 ]]
}

# ============================================================================
# CLAUDE.MD PRESERVATION
# ============================================================================

# Extract user customizations section from CLAUDE.md
extract_user_section() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return
    fi

    # Extract content between markers
    sed -n "/${USER_SECTION_START}/,/${USER_SECTION_END}/p" "$file" 2>/dev/null || true
}

# Merge user customizations into new CLAUDE.md
# Args: $1=new_file, $2=old_file (with customizations)
merge_claude_md() {
    local new_file="$1"
    local old_file="$2"

    if [[ ! -f "$old_file" ]]; then
        return 0
    fi

    local user_section
    user_section=$(extract_user_section "$old_file")

    if [[ -z "$user_section" ]]; then
        return 0
    fi

    # If new file doesn't have the marker, add section at end
    if ! grep -q "$USER_SECTION_START" "$new_file" 2>/dev/null; then
        echo "" >> "$new_file"
        echo "$user_section" >> "$new_file"
    else
        # Replace placeholder section with actual content
        local temp_file
        temp_file=$(mktemp)

        # Use awk to replace the section
        awk -v section="$user_section" '
            /<!-- USER CUSTOMIZATIONS -->/ {
                found=1
                print section
                next
            }
            /<!-- END USER CUSTOMIZATIONS -->/ {
                found=0
                next
            }
            !found { print }
        ' "$new_file" > "$temp_file"

        mv "$temp_file" "$new_file"
    fi

    echo "Preserved user customizations in CLAUDE.md"
}

# ============================================================================
# BACKUP OPERATIONS
# ============================================================================

# Create timestamped backup
# Args: $1=source_path, $2=backup_dir (optional)
create_backup() {
    local source_path="$1"
    local backup_dir="${2:-$(dirname "$source_path")}"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)

    local source_name
    source_name=$(basename "$source_path")
    local backup_path="${backup_dir}/${source_name}.backup.${timestamp}"

    if [[ -d "$source_path" ]]; then
        cp -r "$source_path" "$backup_path"
    elif [[ -f "$source_path" ]]; then
        cp "$source_path" "$backup_path"
    else
        echo "warning: Nothing to backup at $source_path" >&2
        return 1
    fi

    echo "$backup_path"
}

# ============================================================================
# CLI INTERFACE
# ============================================================================

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
    case "${1:-}" in
        sync-file)
            sync_file "${2:-}" "${3:-}" "${4:-false}" "${5:-false}"
            ;;
        sync-dir)
            sync_directory "${2:-}" "${3:-}" "${4:-false}" "${5:-false}"
            ;;
        is-modified)
            is_user_modified "${2:-}" && echo "yes" || echo "no"
            ;;
        checksum)
            get_checksum "${2:-}"
            ;;
        backup)
            create_backup "${2:-}" "${3:-}"
            ;;
        *)
            echo "Usage: $0 {sync-file|sync-dir|is-modified|checksum|backup} [args]"
            exit 1
            ;;
    esac
fi
