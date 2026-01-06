#!/usr/bin/env bash
#
# Jarvis Uninstaller
# Removes Jarvis AI assistant configuration from Claude Code CLI
#
# This script safely removes Jarvis while preserving user data.
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
CLAUDE_DIR="${HOME}/.claude"
BACKUP_DIR="${CLAUDE_DIR}/uninstall-backup-$(date +%Y%m%d_%H%M%S)"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${CYAN}==>${NC} $1"
}

# Print banner
print_banner() {
    echo -e "${RED}"
    cat << 'EOF'
     _                  _
    | | __ _ _ ____   _(_)___
 _  | |/ _` | '__\ \ / / / __|
| |_| | (_| | |   \ V /| \__ \
 \___/ \__,_|_|    \_/ |_|___/

    Uninstaller
EOF
    echo -e "${NC}"
    echo "-----------------------------------"
}

# Check if Jarvis is installed
check_installation() {
    log_step "Checking Jarvis installation..."

    if [[ ! -d "$CLAUDE_DIR" ]]; then
        log_error "No ~/.claude directory found"
        log_info "Jarvis does not appear to be installed"
        exit 0
    fi

    if [[ ! -f "${CLAUDE_DIR}/.jarvis-version" ]]; then
        log_warning "Jarvis version marker not found"
        log_warning "This may not be a Jarvis installation"
        echo ""
        read -p "Continue anyway? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "Uninstallation cancelled"
            exit 0
        fi
    else
        local version=$(grep "^version=" "${CLAUDE_DIR}/.jarvis-version" | cut -d'=' -f2)
        local installed=$(grep "^installed=" "${CLAUDE_DIR}/.jarvis-version" | cut -d'=' -f2)
        log_info "Found Jarvis version: $version"
        log_info "Installed on: $installed"
    fi
}

# Prompt for confirmation
confirm_uninstall() {
    log_step "Confirmation required"

    echo ""
    echo -e "${YELLOW}This will remove Jarvis from your system.${NC}"
    echo ""
    echo "The following will be removed:"
    echo "  - ~/.claude/agents/"
    echo "  - ~/.claude/commands/"
    echo "  - ~/.claude/hooks/"
    echo "  - ~/.claude/lib/"
    echo "  - ~/.claude/patterns/"
    echo "  - ~/.claude/rules/"
    echo "  - ~/.claude/skills/"
    echo "  - ~/.claude/settings.json"
    echo "  - ~/.claude/skill-rules.json"
    echo "  - ~/.claude/hooks.json"
    echo "  - ~/.claude/.jarvis-version"
    echo ""
    echo "A backup will be created before removal."
    echo ""

    read -p "Are you sure you want to uninstall Jarvis? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Uninstallation cancelled"
        exit 0
    fi
}

# Create backup before uninstall
create_backup() {
    log_step "Creating backup..."

    mkdir -p "$BACKUP_DIR"

    # Backup everything
    for item in "$CLAUDE_DIR"/*; do
        if [[ -e "$item" ]]; then
            local basename="$(basename "$item")"
            # Skip existing backup directories
            if [[ "$basename" != "backups" && "$basename" != uninstall-backup-* ]]; then
                cp -R "$item" "$BACKUP_DIR/"
                log_info "Backed up: $basename"
            fi
        fi
    done

    # Also backup hidden files
    for item in "$CLAUDE_DIR"/.*; do
        if [[ -e "$item" ]]; then
            local basename="$(basename "$item")"
            if [[ "$basename" != "." && "$basename" != ".." ]]; then
                cp -R "$item" "$BACKUP_DIR/"
                log_info "Backed up: $basename"
            fi
        fi
    done

    log_success "Backup created at: $BACKUP_DIR"
}

# Remove Jarvis files
remove_files() {
    log_step "Removing Jarvis files..."

    # Directories to remove
    local directories=(
        "agents"
        "commands"
        "hooks"
        "lib"
        "patterns"
        "rules"
        "skills"
    )

    for dir in "${directories[@]}"; do
        local path="${CLAUDE_DIR}/${dir}"
        if [[ -d "$path" ]]; then
            rm -rf "$path"
            log_info "Removed: ~/.claude/${dir}"
        fi
    done

    # Files to remove
    local files=(
        "settings.json"
        "skill-rules.json"
        "hooks.json"
        "README.md"
        ".jarvis-version"
    )

    for file in "${files[@]}"; do
        local path="${CLAUDE_DIR}/${file}"
        if [[ -f "$path" ]]; then
            rm -f "$path"
            log_info "Removed: ~/.claude/${file}"
        fi
    done

    log_success "Jarvis files removed"
}

# Clean up empty directories
cleanup() {
    log_step "Cleaning up..."

    # Check if ~/.claude is empty (except backups)
    local remaining=0
    for item in "$CLAUDE_DIR"/*; do
        if [[ -e "$item" ]]; then
            local basename="$(basename "$item")"
            if [[ "$basename" != "backups" && "$basename" != uninstall-backup-* ]]; then
                ((remaining++))
            fi
        fi
    done

    if [[ $remaining -eq 0 ]]; then
        log_info "~/.claude directory is empty (except backups)"
        echo ""
        read -p "Remove ~/.claude directory entirely? Backups will be preserved in a temp location. (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            # Move backups to temp location
            local temp_backup="/tmp/jarvis-backups-$(date +%Y%m%d_%H%M%S)"
            if [[ -d "${CLAUDE_DIR}/backups" ]] || ls "${CLAUDE_DIR}"/uninstall-backup-* >/dev/null 2>&1; then
                mkdir -p "$temp_backup"
                mv "${CLAUDE_DIR}/backups" "$temp_backup/" 2>/dev/null || true
                mv "${CLAUDE_DIR}"/uninstall-backup-* "$temp_backup/" 2>/dev/null || true
                log_info "Backups preserved at: $temp_backup"
            fi
            rm -rf "$CLAUDE_DIR"
            log_info "Removed ~/.claude directory"
        fi
    else
        log_info "$remaining items remain in ~/.claude (user files preserved)"
    fi

    log_success "Cleanup complete"
}

# Print completion message
print_completion() {
    log_step "Uninstallation complete!"

    echo ""
    echo -e "${GREEN}Jarvis has been uninstalled successfully.${NC}"
    echo ""
    echo "Backup location: $BACKUP_DIR"
    echo ""
    echo -e "${CYAN}To restore:${NC}"
    echo "  cp -R $BACKUP_DIR/* ~/.claude/"
    echo ""
    echo -e "${CYAN}To reinstall:${NC}"
    echo "  ./install.sh"
    echo ""
}

# Full removal without backup (for --purge)
purge_all() {
    log_step "Purging all Jarvis data..."

    log_warning "This will permanently delete all data including backups!"
    echo ""
    read -p "Type 'PURGE' to confirm: " confirm
    if [[ "$confirm" != "PURGE" ]]; then
        log_info "Purge cancelled"
        exit 0
    fi

    rm -rf "$CLAUDE_DIR"
    log_success "All Jarvis data has been permanently removed"
}

# Main uninstall flow
main() {
    print_banner

    # Parse arguments
    local purge=false
    local force=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --purge)
                purge=true
                shift
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  -f, --force    Skip confirmation prompts"
                echo "  --purge        Remove everything including backups (dangerous)"
                echo "  -h, --help     Show this help message"
                echo ""
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    check_installation

    if $purge; then
        purge_all
        exit 0
    fi

    if ! $force; then
        confirm_uninstall
    fi

    create_backup
    remove_files
    cleanup
    print_completion
}

# Run main
main "$@"
