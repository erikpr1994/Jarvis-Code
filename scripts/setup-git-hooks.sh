#!/usr/bin/env bash
# Setup git hooks for the Jarvis repository
# Run this after cloning to enable conventional commit validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Setting up git hooks for Jarvis...${NC}"

# Get the hooks directory that git actually uses (handles worktrees correctly)
HOOKS_DIR=$(git -C "$REPO_ROOT" rev-parse --git-path hooks)

# Ensure hooks directory exists
mkdir -p "$HOOKS_DIR"

# Install commit-msg hook
HOOK_SOURCE="$SCRIPT_DIR/commit-msg"
HOOK_DEST="$HOOKS_DIR/commit-msg"

if [[ -f "$HOOK_SOURCE" ]]; then
    cp "$HOOK_SOURCE" "$HOOK_DEST"
    chmod +x "$HOOK_DEST"
    echo -e "${GREEN}✓${NC} Installed commit-msg hook"
else
    echo -e "${RED}✗${NC} commit-msg hook source not found: $HOOK_SOURCE"
    exit 1
fi

echo ""
echo -e "${GREEN}Git hooks setup complete!${NC}"
echo ""
echo "Conventional commit format is now enforced."
echo "Format: <type>(<scope>): <description>"
echo ""
echo "Valid types: feat, fix, docs, style, refactor, perf, test, chore, ci, build, revert, merge"
