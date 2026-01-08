#!/usr/bin/env bash
# Jarvis Project Setup Script
# 
# Sets up enforcement tools in a project:
# - ESLint with strict TypeScript rules
# - Commitlint for conventional commits
# - Husky for git hooks
# - Vitest with coverage thresholds
# - Strict TypeScript config
#
# Usage: ./setup-enforcement.sh [--all] [--eslint] [--commitlint] [--husky] [--vitest] [--tsconfig]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory (where templates are)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🤖 Jarvis Project Enforcement Setup${NC}"
echo ""

# Parse arguments
INSTALL_ALL=false
INSTALL_ESLINT=false
INSTALL_COMMITLINT=false
INSTALL_HUSKY=false
INSTALL_VITEST=false
INSTALL_TSCONFIG=false

if [ $# -eq 0 ]; then
    INSTALL_ALL=true
fi

for arg in "$@"; do
    case $arg in
        --all) INSTALL_ALL=true ;;
        --eslint) INSTALL_ESLINT=true ;;
        --commitlint) INSTALL_COMMITLINT=true ;;
        --husky) INSTALL_HUSKY=true ;;
        --vitest) INSTALL_VITEST=true ;;
        --tsconfig) INSTALL_TSCONFIG=true ;;
        --help)
            echo "Usage: $0 [--all] [--eslint] [--commitlint] [--husky] [--vitest] [--tsconfig]"
            echo ""
            echo "Options:"
            echo "  --all        Install all enforcement tools (default if no args)"
            echo "  --eslint     Install ESLint with strict TypeScript rules"
            echo "  --commitlint Install commitlint for conventional commits"
            echo "  --husky      Install husky git hooks"
            echo "  --vitest     Install vitest with coverage thresholds"
            echo "  --tsconfig   Install strict TypeScript config"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $arg${NC}"
            exit 1
            ;;
    esac
done

if [ "$INSTALL_ALL" = true ]; then
    INSTALL_ESLINT=true
    INSTALL_COMMITLINT=true
    INSTALL_HUSKY=true
    INSTALL_VITEST=true
    INSTALL_TSCONFIG=true
fi

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ No package.json found. Run 'npm init' first.${NC}"
    exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════════
# ESLINT
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$INSTALL_ESLINT" = true ]; then
    echo -e "${YELLOW}→ Installing ESLint...${NC}"
    
    npm install -D eslint typescript-eslint @eslint/js eslint-plugin-import
    
    if [ ! -f "eslint.config.js" ]; then
        cp "$SCRIPT_DIR/eslint.config.js" ./eslint.config.js
        echo -e "  ${GREEN}✓ Created eslint.config.js${NC}"
    else
        echo -e "  ${YELLOW}⚠ eslint.config.js already exists, skipping${NC}"
    fi
    
    # Add lint script to package.json if not exists
    if ! grep -q '"lint"' package.json; then
        npm pkg set scripts.lint="eslint src/"
        echo -e "  ${GREEN}✓ Added 'lint' script to package.json${NC}"
    fi
    
    echo -e "${GREEN}✓ ESLint installed${NC}"
    echo ""
fi

# ═══════════════════════════════════════════════════════════════════════════════
# COMMITLINT
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$INSTALL_COMMITLINT" = true ]; then
    echo -e "${YELLOW}→ Installing Commitlint...${NC}"
    
    npm install -D @commitlint/{cli,config-conventional}
    
    if [ ! -f "commitlint.config.js" ]; then
        cp "$SCRIPT_DIR/commitlint.config.js" ./commitlint.config.js
        echo -e "  ${GREEN}✓ Created commitlint.config.js${NC}"
    else
        echo -e "  ${YELLOW}⚠ commitlint.config.js already exists, skipping${NC}"
    fi
    
    echo -e "${GREEN}✓ Commitlint installed${NC}"
    echo ""
fi

# ═══════════════════════════════════════════════════════════════════════════════
# HUSKY
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$INSTALL_HUSKY" = true ]; then
    echo -e "${YELLOW}→ Installing Husky...${NC}"
    
    npm install -D husky
    npx husky init
    
    # Copy hook files
    cp "$SCRIPT_DIR/husky/pre-commit" .husky/pre-commit
    chmod +x .husky/pre-commit
    echo -e "  ${GREEN}✓ Created .husky/pre-commit${NC}"
    
    cp "$SCRIPT_DIR/husky/commit-msg" .husky/commit-msg
    chmod +x .husky/commit-msg
    echo -e "  ${GREEN}✓ Created .husky/commit-msg${NC}"
    
    echo -e "${GREEN}✓ Husky installed${NC}"
    echo ""
fi

# ═══════════════════════════════════════════════════════════════════════════════
# VITEST
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$INSTALL_VITEST" = true ]; then
    echo -e "${YELLOW}→ Installing Vitest...${NC}"
    
    npm install -D vitest @vitest/coverage-v8
    
    if [ ! -f "vitest.config.ts" ]; then
        cp "$SCRIPT_DIR/vitest.config.ts" ./vitest.config.ts
        echo -e "  ${GREEN}✓ Created vitest.config.ts${NC}"
    else
        echo -e "  ${YELLOW}⚠ vitest.config.ts already exists, skipping${NC}"
    fi
    
    # Add test scripts to package.json if not exists
    if ! grep -q '"test"' package.json; then
        npm pkg set scripts.test="vitest run"
        npm pkg set scripts.test:watch="vitest"
        npm pkg set scripts.test:coverage="vitest run --coverage"
        echo -e "  ${GREEN}✓ Added test scripts to package.json${NC}"
    fi
    
    echo -e "${GREEN}✓ Vitest installed${NC}"
    echo ""
fi

# ═══════════════════════════════════════════════════════════════════════════════
# TSCONFIG
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$INSTALL_TSCONFIG" = true ]; then
    echo -e "${YELLOW}→ Installing strict TypeScript config...${NC}"
    
    if [ ! -f "tsconfig.json" ]; then
        cp "$SCRIPT_DIR/tsconfig.strict.json" ./tsconfig.json
        echo -e "  ${GREEN}✓ Created tsconfig.json${NC}"
    else
        echo -e "  ${YELLOW}⚠ tsconfig.json already exists${NC}"
        echo -e "  ${YELLOW}  Consider extending tsconfig.strict.json:${NC}"
        echo -e "  ${YELLOW}  { \"extends\": \"./node_modules/jarvis/tsconfig.strict.json\" }${NC}"
    fi
    
    # Add type-check script
    if ! grep -q '"type-check"' package.json; then
        npm pkg set scripts.type-check="tsc --noEmit"
        echo -e "  ${GREEN}✓ Added 'type-check' script to package.json${NC}"
    fi
    
    echo -e "${GREEN}✓ TypeScript config installed${NC}"
    echo ""
fi

# ═══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Jarvis enforcement tools installed!${NC}"
echo ""
echo -e "These soft rules are now ${GREEN}hard rules${NC}:"
echo -e "  • No \`any\` types → ESLint error"
echo -e "  • No \`@ts-ignore\` without justification → ESLint error"
echo -e "  • Conventional commits → commitlint blocks invalid messages"
echo -e "  • TypeScript errors → pre-commit hook blocks"
echo -e "  • Lint errors → pre-commit hook blocks"
echo -e "  • Coverage < 80% → vitest fails"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Run 'npm run lint' to check current code"
echo -e "  2. Run 'npm run type-check' to verify TypeScript"
echo -e "  3. Try a commit to test the hooks"
echo ""
