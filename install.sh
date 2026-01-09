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
VERSION_FILE="${SCRIPT_DIR}/VERSION"
INSTALLED_VERSION_FILE="${CLAUDE_DIR}/.jarvis-version"

# Read version from VERSION file
if [[ -f "$VERSION_FILE" ]]; then
    VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
else
    VERSION="1.0.0"
fi

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

# ============================================================================
# VERSION MANAGEMENT
# ============================================================================

# Compare two semantic versions (returns 0 if v1 >= v2, 1 otherwise)
version_gte() {
    local v1="$1"
    local v2="$2"

    # Split versions into components
    local IFS='.'
    read -ra v1_parts <<< "$v1"
    read -ra v2_parts <<< "$v2"

    # Compare each component
    for i in 0 1 2; do
        local n1="${v1_parts[i]:-0}"
        local n2="${v2_parts[i]:-0}"
        if [[ "$n1" -gt "$n2" ]]; then
            return 0
        elif [[ "$n1" -lt "$n2" ]]; then
            return 1
        fi
    done

    return 0  # Equal versions
}

# Get installed version
get_installed_version() {
    if [[ -f "$INSTALLED_VERSION_FILE" ]]; then
        grep -E "^version=" "$INSTALLED_VERSION_FILE" 2>/dev/null | cut -d= -f2 | tr -d '[:space:]'
    else
        echo ""
    fi
}

# Check if upgrade is needed
check_upgrade_needed() {
    local installed_version
    installed_version=$(get_installed_version)

    if [[ -z "$installed_version" ]]; then
        log_info "No previous installation found"
        return 0  # Fresh install
    fi

    log_info "Installed version: $installed_version"
    log_info "New version: $VERSION"

    if version_gte "$VERSION" "$installed_version"; then
        if [[ "$VERSION" == "$installed_version" ]]; then
            log_info "Already at version $VERSION"
        else
            log_info "Upgrade available: $installed_version -> $VERSION"
        fi
        return 0
    else
        log_warning "Installed version ($installed_version) is newer than package ($VERSION)"
        log_warning "Use --force to downgrade"
        return 1
    fi
}

# Save version information
save_version_info() {
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat > "$INSTALLED_VERSION_FILE" << EOF
version=$VERSION
installed=$timestamp
source=$SCRIPT_DIR
previous_version=$(get_installed_version)
EOF

    log_info "Version info saved to $INSTALLED_VERSION_FILE"
}

# Show version command
show_version() {
    echo "Jarvis AI Assistant"
    echo "Package version: $VERSION"
    local installed
    installed=$(get_installed_version)
    if [[ -n "$installed" ]]; then
        echo "Installed version: $installed"
    else
        echo "Installed version: Not installed"
    fi
}

# Check for updates (placeholder for remote check)
check_for_updates() {
    log_info "Checking for updates..."

    # In a real implementation, this would check a remote source
    # For now, just compare local VERSION file with installed

    local installed_version
    installed_version=$(get_installed_version)

    if [[ -z "$installed_version" ]]; then
        log_info "Jarvis is not installed. Run ./install.sh to install."
        return 0
    fi

    if [[ "$VERSION" == "$installed_version" ]]; then
        log_success "You're running the latest version ($VERSION)"
    elif version_gte "$VERSION" "$installed_version"; then
        log_info "Update available: $installed_version -> $VERSION"
        log_info "Run ./install.sh to update"
    else
        log_info "You're running a newer version ($installed_version) than the package ($VERSION)"
    fi
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

    # Check for bash version (recommend 4+ for better performance)
    local bash_version="${BASH_VERSION%%.*}"
    if [[ "$bash_version" -lt 4 ]]; then
        log_warning "Bash version $BASH_VERSION detected (macOS default)"
        log_info "Jarvis is compatible, but Bash 5+ is recommended for best experience"
        if command_exists brew; then
            log_info "Install newer Bash with: brew install bash"
        else
            log_info "Install Homebrew (https://brew.sh) then run: brew install bash"
        fi
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
                files_skipped=$((files_skipped + 1))
            else
                # Check for user modifications marker
                if grep -q "# JARVIS-USER-MODIFIED" "$dest" 2>/dev/null; then
                    log_warning "Preserving user-modified: $relative_path"
                    files_skipped=$((files_skipped + 1))
                else
                    cp "$src" "$dest"
                    log_info "Updated: $relative_path"
                    files_updated=$((files_updated + 1))
                fi
            fi
        else
            cp "$src" "$dest"
            log_info "Installed: $relative_path"
            files_copied=$((files_copied + 1))
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

# Install and configure Claude HUD
install_claude_hud() {
    log_step "Installing Claude HUD..."

    if ! command_exists claude; then
        log_warning "Claude CLI not found. Skipping Claude HUD installation."
        return
    fi

    if ! command_exists jq; then
        log_warning "jq not found. Skipping Claude HUD configuration."
        return
    fi

    log_info "Adding marketplace..."
    # Capture output to check for specific errors
    local market_output
    if ! market_output=$(claude plugin marketplace add jarrodwatts/claude-hud 2>&1); then
        # Check if it failed because it already exists (which is fine)
        if [[ "$market_output" == *"already exists"* ]]; then
             log_info "Marketplace already exists."
        else
             log_warning "Failed to add marketplace: $market_output"
             log_info "Attempting to proceed with installation anyway..."
        fi
    else
        log_success "Marketplace added."
    fi

    log_info "Installing plugin..."
    local install_output
    if ! install_output=$(claude plugin install claude-hud 2>&1); then
        if [[ "$install_output" == *"already installed"* ]]; then
             log_info "Plugin already installed."
        else
             log_warning "Failed to install plugin: $install_output"
             log_info "Setup may be incomplete."
        fi
    else
        log_success "Plugin installed."
    fi

    # Configure statusline
    log_info "Configuring statusline..."
    
    # Find install path from installed_plugins.json
    local plugins_file="${CLAUDE_DIR}/plugins/installed_plugins.json"
    
    if [[ ! -f "$plugins_file" ]]; then
        log_warning "Plugins file not found at $plugins_file"
        return
    fi
    
    local install_path
    install_path=$(jq -r '.plugins["claude-hud@claude-hud"][0].installPath // empty' "$plugins_file")
    
    if [[ -z "$install_path" ]]; then
        log_warning "Could not determine Claude HUD installation path."
        return
    fi
    
    local cmd="node ${install_path}/dist/index.js"
    local settings_file="${CLAUDE_DIR}/settings.json"
    
    if [[ -f "$settings_file" ]]; then
        local tmp_file="${settings_file}.tmp"
        # Add statusLine config
        jq --arg cmd "$cmd" '.statusLine = {"type": "command", "command": $cmd, "padding": 0}' "$settings_file" > "$tmp_file" && mv "$tmp_file" "$settings_file"
        log_success "Claude HUD configured successfully"
    else
        log_warning "settings.json not found. Skipping configuration."
    fi
}

# Create version file (uses save_version_info from version management section)
create_version_file() {
    log_step "Creating version marker..."
    save_version_info
    log_success "Version marker created"
}

# Configure user preferences interactively
configure_preferences() {
    log_step "Configuring preferences..."

    local config_dir="${CLAUDE_DIR}/config"
    local config_file="${config_dir}/preferences.json"
    local defaults_file="${GLOBAL_SOURCE}/config/defaults.json"

    mkdir -p "$config_dir"

    # If config already exists, ask if they want to reconfigure
    if [[ -f "$config_file" ]]; then
        log_info "Existing preferences found"
        read -p "Reconfigure preferences? (y/N): " reconfigure
        if [[ ! "$reconfigure" =~ ^[Yy]$ ]]; then
            log_info "Keeping existing preferences"
            return 0
        fi
    fi

    # Start with defaults
    if [[ -f "$defaults_file" ]]; then
        cp "$defaults_file" "$config_file"
    else
        cat > "$config_file" << 'DEFAULTS'
{
  "version": "1.0.0",
  "rules": {
    "tdd": { "enabled": false, "severity": "warning" },
    "conventionalCommits": { "enabled": true, "severity": "warning" }
  },
  "hooks": {
    "gitSafetyGuard": { "enabled": true, "bypassable": true },
    "requireIsolation": { "enabled": false, "bypassable": true },
    "preCommitTests": { "enabled": false, "bypassable": true },
    "skillActivation": { "enabled": true, "bypassable": false }
  }
}
DEFAULTS
    fi

    echo ""
    echo -e "${CYAN}Configure your preferences:${NC}"
    echo ""

    # Hook: Git Safety Guard
    echo -e "${YELLOW}Git Safety Guard${NC} - Blocks dangerous git commands (reset --hard, push --force)"
    read -p "Enable? (Y/n): " git_safety
    if [[ "$git_safety" =~ ^[Nn]$ ]]; then
        jq '.hooks.gitSafetyGuard.enabled = false' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
    fi

    # Hook: Require Isolation
    echo ""
    echo -e "${YELLOW}Branch Isolation${NC} - Block file edits on main/master branch"
    read -p "Enable? (y/N): " isolation
    if [[ "$isolation" =~ ^[Yy]$ ]]; then
        jq '.hooks.requireIsolation.enabled = true' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
    fi

    # Hook: Pre-commit Tests
    echo ""
    echo -e "${YELLOW}Pre-commit Tests${NC} - Require tests to pass before commits"
    read -p "Enable? (y/N): " precommit
    if [[ "$precommit" =~ ^[Yy]$ ]]; then
        jq '.hooks.preCommitTests.enabled = true' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
    fi

    # Rule: TDD
    echo ""
    echo -e "${YELLOW}Test-Driven Development${NC} - Encourage writing tests before implementation"
    read -p "Enable? (y/N): " tdd
    if [[ "$tdd" =~ ^[Yy]$ ]]; then
        jq '.rules.tdd.enabled = true' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
    fi

    # Rule: Conventional Commits
    echo ""
    echo -e "${YELLOW}Conventional Commits${NC} - Use feat:, fix:, chore: prefixes"
    read -p "Enable? (Y/n): " conventional
    if [[ "$conventional" =~ ^[Nn]$ ]]; then
        jq '.rules.conventionalCommits.enabled = false' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
    fi

    echo ""
    log_success "Preferences saved to $config_file"
    log_info "Run '/jarvis-config' in Claude Code to change these later"
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
    echo "  3. Use /jarvis-init to initialize Jarvis in that project"
    echo ""
    echo -e "${CYAN}Available Commands:${NC}"
    echo "  /jarvis-init    - Initialize Jarvis in current project"
    echo "  /skills         - List available skills"
    echo "  /agents         - List available agents"
    echo ""
    echo -e "${CYAN}Key Features:${NC}"
    echo "  - Smart skill activation based on context"
    echo "  - Enhanced status line (Claude HUD)"
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
    # Parse arguments first (some don't need banner)
    local force=false
    local skip_config=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force)
                force=true
                shift
                ;;
            -s|--skip-config)
                skip_config=true
                shift
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -c|--check-update)
                check_for_updates
                exit 0
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  -f, --force        Force installation without prompts"
                echo "  -s, --skip-config  Skip interactive configuration"
                echo "  -v, --version      Show version information"
                echo "  -c, --check-update Check for updates"
                echo "  -h, --help         Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0              Install/update Jarvis (interactive)"
                echo "  $0 --skip-config  Install with default preferences"
                echo "  $0 --version    Show current version"
                echo "  $0 --force      Force reinstall"
                echo ""
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    print_banner

    # Check if upgrade is needed/allowed
    if [[ "$force" != true ]]; then
        if ! check_upgrade_needed; then
            log_error "Installation cancelled. Use --force to override."
            exit 1
        fi
    fi

    # Run installation steps
    check_prerequisites
    backup_existing
    create_directories
    copy_files
    setup_hooks
    make_executable
    install_claude_hud
    create_version_file

    # Configure preferences (unless skipped)
    if [[ "$skip_config" != true ]]; then
        configure_preferences
    else
        log_info "Skipping configuration (use '/jarvis-config' in Claude Code to configure later)"
    fi

    print_usage
}

# Run main
main "$@"
