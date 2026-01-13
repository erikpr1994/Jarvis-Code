#!/usr/bin/env bash
# Jarvis Update Script - Safe sync to ~/.claude
# IMPORTANT: Only syncs Jarvis-managed directories, preserves native Claude files

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
JARVIS_SOURCE="${JARVIS_SOURCE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
VERSION_FILE="$CLAUDE_HOME/.jarvis-version"

# Jarvis-managed directories (ONLY these get synced)
JARVIS_DIRS=(
    "agents"
    "commands"
    "hooks"
    "learning"
    "lib"
    "metrics"
    "patterns"
    "rules"
    "skills"
)

# Jarvis-managed files (ONLY these get synced)
JARVIS_FILES=(
    "CLAUDE.md"
    "README.md"
    "jarvis.json"
    "settings.json"
    "skill-rules.json"
)

# Native Claude directories (NEVER touch these)
# plugins, cache, chrome, config, debug, file-history, history.jsonl,
# logs, paste-cache, plans, projects, session-env, shell-snapshots,
# state, statsig, todos

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    Jarvis Update System                      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check source exists
if [[ ! -d "$JARVIS_SOURCE/global" ]]; then
    echo -e "${RED}Error: Jarvis source not found at $JARVIS_SOURCE${NC}"
    echo "Set JARVIS_SOURCE environment variable to your Jarvis repo path"
    exit 1
fi

# Version check
echo -e "${YELLOW}=== Version Check ===${NC}"
INSTALLED_VERSION="unknown"
if [[ -f "$VERSION_FILE" ]]; then
    INSTALLED_VERSION=$(grep "^version=" "$VERSION_FILE" | cut -d= -f2)
fi
AVAILABLE_VERSION=$(cat "$JARVIS_SOURCE/VERSION" 2>/dev/null || echo "unknown")

echo "Installed: $INSTALLED_VERSION"
echo "Available: $AVAILABLE_VERSION"
echo ""

# Sync function for directories
sync_directory() {
    local dir="$1"
    local source="$JARVIS_SOURCE/global/$dir"
    local target="$CLAUDE_HOME/$dir"

    if [[ ! -d "$source" ]]; then
        echo -e "  ${YELLOW}skip${NC}: $dir (not in source)"
        return
    fi

    # Create target if doesn't exist
    mkdir -p "$target"

    # Count changes
    local created=0
    local updated=0
    local skipped=0

    # Sync files (without --delete!)
    while IFS= read -r -d '' file; do
        local rel_path="${file#$source/}"
        local target_file="$target/$rel_path"
        local target_dir=$(dirname "$target_file")

        # Create subdirectories as needed
        mkdir -p "$target_dir"

        # Check for user-modified marker
        if [[ -f "$target_file" ]] && head -1 "$target_file" 2>/dev/null | grep -q "JARVIS-USER-MODIFIED"; then
            ((skipped++))
            continue
        fi

        # Compare and copy
        if [[ ! -f "$target_file" ]]; then
            cp "$file" "$target_file"
            ((created++))
        elif ! diff -q "$file" "$target_file" > /dev/null 2>&1; then
            cp "$file" "$target_file"
            ((updated++))
        fi
    done < <(find "$source" -type f -print0)

    echo -e "  ${GREEN}$dir${NC}: $created created, $updated updated, $skipped skipped"
}

# Sync function for individual files
sync_file() {
    local file="$1"
    local source="$JARVIS_SOURCE/global/$file"
    local target="$CLAUDE_HOME/$file"

    if [[ ! -f "$source" ]]; then
        echo -e "  ${YELLOW}skip${NC}: $file (not in source)"
        return
    fi

    # Check for user-modified marker
    if [[ -f "$target" ]] && head -1 "$target" 2>/dev/null | grep -q "JARVIS-USER-MODIFIED"; then
        echo -e "  ${YELLOW}skip${NC}: $file (user-modified)"
        return
    fi

    if [[ ! -f "$target" ]]; then
        cp "$source" "$target"
        echo -e "  ${GREEN}created${NC}: $file"
    elif ! diff -q "$source" "$target" > /dev/null 2>&1; then
        cp "$source" "$target"
        echo -e "  ${GREEN}updated${NC}: $file"
    else
        echo -e "  ${BLUE}unchanged${NC}: $file"
    fi
}

# Main sync
echo -e "${YELLOW}=== Syncing Jarvis Components ===${NC}"
echo "Source: $JARVIS_SOURCE/global"
echo "Target: $CLAUDE_HOME"
echo ""

echo -e "${YELLOW}--- Directories ---${NC}"
for dir in "${JARVIS_DIRS[@]}"; do
    sync_directory "$dir"
done

echo ""
echo -e "${YELLOW}--- Files ---${NC}"
for file in "${JARVIS_FILES[@]}"; do
    sync_file "$file"
done

# Configure file suggestion hook (ensure it's enabled even if settings.json was skipped)
if [[ -f "$CLAUDE_HOME/settings.json" ]] && command -v jq >/dev/null; then
    SETTINGS_FILE="$CLAUDE_HOME/settings.json"
    HOOK_SCRIPT="~/.claude/hooks/file-suggestion.sh"
    
    # Check if fileSuggestion is already configured
    if [[ "$(jq -r '.fileSuggestion // empty' "$SETTINGS_FILE")" == "null" ]]; then
        echo -e "  ${YELLOW}configuring${NC}: fileSuggestion in settings.json"
        TMP_FILE="${SETTINGS_FILE}.tmp"
        if jq --arg cmd "$HOOK_SCRIPT" '.fileSuggestion = {"type": "command", "command": $cmd}' "$SETTINGS_FILE" > "$TMP_FILE"; then
            mv "$TMP_FILE" "$SETTINGS_FILE"
        else
            rm -f "$TMP_FILE"
        fi
    fi
fi

# Update version file
echo ""
echo -e "${YELLOW}=== Updating Version ===${NC}"
cat > "$VERSION_FILE" << EOF
version=$AVAILABLE_VERSION
installed=$(date -u +%Y-%m-%dT%H:%M:%SZ)
source=$JARVIS_SOURCE
previous_version=$INSTALLED_VERSION
EOF
echo -e "${GREEN}Updated to version $AVAILABLE_VERSION${NC}"

# Validation
echo ""
echo -e "${YELLOW}=== Validation ===${NC}"
ERRORS=0

# Check hook syntax
echo -n "Checking hook syntax... "
for hook in "$CLAUDE_HOME"/hooks/*.sh; do
    if [[ -f "$hook" ]] && ! bash -n "$hook" 2>/dev/null; then
        echo -e "${RED}FAIL${NC}: $hook"
        ((ERRORS++))
    fi
done
if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}OK${NC}"
fi

# Check settings.json
echo -n "Checking settings.json... "
if [[ -f "$CLAUDE_HOME/settings.json" ]] && python3 -c "import json; json.load(open('$CLAUDE_HOME/settings.json'))" 2>/dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL${NC}"
    ((ERRORS++))
fi

# Summary
echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}✅ Update completed successfully!${NC}"
else
    echo -e "${RED}⚠️ Update completed with $ERRORS errors${NC}"
fi

echo ""
echo -e "${BLUE}Note: Native Claude files (plugins, cache, etc.) were NOT modified.${NC}"
