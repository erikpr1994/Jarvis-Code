#!/usr/bin/env bash
#
# Jarvis Installer
# Installs Jarvis AI assistant configuration for Claude Code CLI
#
# This script is idempotent - safe to run multiple times.
# Existing user customizations are preserved with backups.
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_SOURCE="${SCRIPT_DIR}/global"
CLAUDE_DIR="${HOME}/.claude"
BACKUP_DIR="${CLAUDE_DIR}/backups/$(date +%Y%m%d_%H%M%S)"
VERSION="1.0.0"

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
    echo -e "${CYAN}"
    cat << 'EOF'
     _                  _
    | | __ _ _ ____   _(_)___
 _  | |/ _` | '__\ \ / / / __|
| |_| | (_| | |   \ V /| \__ \
 \___/ \__,_|_|    \_/ |_|___/

    AI Assistant for Claude Code
EOF
    echo -e "${NC}"
    echo "Version: ${VERSION}"
    echo "-----------------------------------"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."

    local missing=()

    # Check for git
    if ! command_exists git; then
        missing+=("git")
    else
        log_info "git: $(git --version)"
    fi

    # Check for Claude CLI
    if ! command_exists claude; then
        log_warning "Claude CLI not found in PATH"
        log_info "Please install Claude CLI from: https://claude.ai/code"
        log_info "Continuing installation (Claude CLI can be installed later)..."
    else
        log_info "Claude CLI: found at $(which claude)"
    fi

    # Check for bash version (need 4+ for associative arrays)
    local bash_version="${BASH_VERSION%%.*}"
    if [[ "$bash_version" -lt 4 ]]; then
        log_warning "Bash version $BASH_VERSION detected. Some features require Bash 4+"
    else
        log_info "Bash: version $BASH_VERSION"
    fi

    # Check for Node.js (optional, for hooks)
    if command_exists node; then
        log_info "Node.js: $(node --version)"
    else
        log_warning "Node.js not found. Some hooks may require Node.js"
    fi

    # Check source directory exists
    if [[ ! -d "$GLOBAL_SOURCE" ]]; then
        log_error "Source directory not found: $GLOBAL_SOURCE"
        log_error "Please run this script from the jarvis directory"
        exit 1
    fi

    # Report missing required tools
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing[*]}"
        log_error "Please install the missing tools and try again"
        exit 1
    fi

    log_success "Prerequisites check passed"
}

# Create backup of existing files
backup_existing() {
    log_step "Checking for existing configuration..."

    if [[ -d "$CLAUDE_DIR" ]]; then
        # Check if there are files to backup (excluding backups directory)
        local has_files=false
        for item in "$CLAUDE_DIR"/*; do
            if [[ -e "$item" && "$(basename "$item")" != "backups" ]]; then
                has_files=true
                break
            fi
        done

        if $has_files; then
            log_info "Existing configuration found at $CLAUDE_DIR"
            log_info "Creating backup at $BACKUP_DIR"

            mkdir -p "$BACKUP_DIR"

            # Backup each item except the backups directory
            for item in "$CLAUDE_DIR"/*; do
                if [[ -e "$item" && "$(basename "$item")" != "backups" ]]; then
                    cp -R "$item" "$BACKUP_DIR/"
                fi
            done

            log_success "Backup created successfully"
        else
            log_info "No existing configuration to backup"
        fi
    else
        log_info "No existing ~/.claude directory found"
    fi
}

# Create directory structure
create_directories() {
    log_step "Creating directory structure..."

    # Main Claude directory
    mkdir -p "$CLAUDE_DIR"

    # Core directories
    local directories=(
        "agents"
        "agents/core"
        "commands"
        "hooks"
        "hooks/lib"
        "lib"
        "patterns"
        "patterns/full"
        "rules"
        "skills"
        "skills/domain"
        "skills/meta"
        "skills/process"
        "backups"
    )

    for dir in "${directories[@]}"; do
        mkdir -p "${CLAUDE_DIR}/${dir}"
        log_info "Created: ~/.claude/${dir}"
    done

    log_success "Directory structure created"
}

# Copy files with preservation of user modifications
copy_files() {
    log_step "Installing Jarvis files..."

    local files_copied=0
    local files_skipped=0
    local files_updated=0

    # Function to copy a single file
    copy_file() {
        local src="$1"
        local dest="$2"
        local relative_path="${src#$GLOBAL_SOURCE/}"

        if [[ -f "$dest" ]]; then
            # File exists - check if it's different
            if cmp -s "$src" "$dest"; then
                log_info "Unchanged: $relative_path"
                ((files_skipped++))
            else
                # Check for user modifications marker
                if grep -q "# JARVIS-USER-MODIFIED" "$dest" 2>/dev/null; then
                    log_warning "Preserving user-modified: $relative_path"
                    ((files_skipped++))
                else
                    cp "$src" "$dest"
                    log_info "Updated: $relative_path"
                    ((files_updated++))
                fi
            fi
        else
            cp "$src" "$dest"
            log_info "Installed: $relative_path"
            ((files_copied++))
        fi
    }

    # Recursively copy files
    while IFS= read -r -d '' file; do
        local relative_path="${file#$GLOBAL_SOURCE/}"
        local dest_path="${CLAUDE_DIR}/${relative_path}"
        local dest_dir="$(dirname "$dest_path")"

        # Create destination directory if needed
        mkdir -p "$dest_dir"

        # Copy the file
        copy_file "$file" "$dest_path"

    done < <(find "$GLOBAL_SOURCE" -type f -print0)

    echo ""
    log_success "Files installed: $files_copied new, $files_updated updated, $files_skipped unchanged"
}

# Set up hooks configuration
setup_hooks() {
    log_step "Setting up hooks configuration..."

    local hooks_config="${CLAUDE_DIR}/hooks.json"

    # Only create if doesn't exist
    if [[ ! -f "$hooks_config" ]]; then
        cat > "$hooks_config" << 'EOF'
{
  "$schema": "./schemas/hooks.schema.json",
  "version": "1.0.0",
  "description": "Jarvis hooks configuration",

  "hooks": {
    "session-start": {
      "enabled": true,
      "scripts": []
    },
    "pre-tool-use": {
      "enabled": true,
      "scripts": []
    },
    "post-tool-use": {
      "enabled": true,
      "scripts": []
    },
    "on-error": {
      "enabled": true,
      "scripts": []
    }
  },

  "settings": {
    "timeout": 30000,
    "parallel": false,
    "continueOnError": true
  }
}
EOF
        log_info "Created hooks configuration"
    else
        log_info "Hooks configuration already exists"
    fi

    log_success "Hooks setup complete"
}

# Make all scripts executable
make_executable() {
    log_step "Setting file permissions..."

    # Make shell scripts executable
    find "$CLAUDE_DIR" -name "*.sh" -type f -exec chmod +x {} \;

    # Make JavaScript files in hooks executable
    find "$CLAUDE_DIR/hooks" -name "*.js" -type f -exec chmod +x {} \;

    # Make lib scripts executable
    find "$CLAUDE_DIR/lib" -name "*.js" -type f -exec chmod +x {} \;

    log_success "Permissions set"
}

# Create version file
create_version_file() {
    log_step "Creating version marker..."

    cat > "${CLAUDE_DIR}/.jarvis-version" << EOF
version=${VERSION}
installed=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
source=${SCRIPT_DIR}
EOF

    log_success "Version marker created"
}

# Print usage instructions
print_usage() {
    log_step "Installation complete!"

    echo ""
    echo -e "${GREEN}Jarvis has been installed successfully!${NC}"
    echo ""
    echo "Configuration location: ${CLAUDE_DIR}"
    echo ""
    echo -e "${CYAN}Quick Start:${NC}"
    echo "  1. Navigate to any project directory"
    echo "  2. Run: claude"
    echo "  3. Use /init to initialize Jarvis in that project"
    echo ""
    echo -e "${CYAN}Available Commands:${NC}"
    echo "  /init           - Initialize Jarvis in current project"
    echo "  /skills         - List available skills"
    echo "  /agents         - List available agents"
    echo ""
    echo -e "${CYAN}Key Features:${NC}"
    echo "  - Smart skill activation based on context"
    echo "  - Code review and test generation agents"
    echo "  - Pattern library for common solutions"
    echo "  - Session tracking and learning"
    echo ""
    echo -e "${CYAN}Customization:${NC}"
    echo "  - Add # JARVIS-USER-MODIFIED to any file to preserve it during updates"
    echo "  - Add custom skills to ~/.claude/skills/"
    echo "  - Add custom agents to ~/.claude/agents/"
    echo "  - Modify settings in ~/.claude/settings.json"
    echo ""
    echo -e "${YELLOW}Note:${NC} If Claude CLI is not installed, get it from: https://claude.ai/code"
    echo ""
    echo -e "For more information, see: ${BLUE}${SCRIPT_DIR}/README.md${NC}"
}

# Main installation flow
main() {
    print_banner

    # Parse arguments
    local force=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force)
                force=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  -f, --force    Force installation without prompts"
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

    # Run installation steps
    check_prerequisites
    backup_existing
    create_directories
    copy_files
    setup_hooks
    make_executable
    create_version_file
    print_usage
}

# Run main
main "$@"
