#!/usr/bin/env bash
# Testing Strategy Detector
# Detects appropriate testing strategy (pyramid vs trophy) based on project type and directory
#
# Usage:
#   source strategy-detector.sh
#   strategy=$(detect_testing_strategy "/path/to/project" "next-app")
#   dir_strategy=$(detect_directory_strategy "/path/to/project" "src/components/Button")

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

# Default settings path
SETTINGS_FILE="${JARVIS_SETTINGS:-${HOME}/.claude/settings.json}"

# Strategy definitions (Bash 3.2 compatible - using parallel indexed arrays)
PROJECT_TYPE_KEYS=(
    "library" "rust-package" "go-module" "python-package"
    "next-app" "react-app" "flutter-app" "node-api"
    "monorepo" "standalone"
)
PROJECT_TYPE_VALUES=(
    "pyramid" "pyramid" "pyramid" "pyramid"
    "trophy" "trophy" "trophy" "trophy"
    "balanced" "auto"
)

DIRECTORY_KEYS=(
    "lib" "packages" "utils"
    "src/components" "src/app" "app" "api" "server"
    "algorithms" "core"
)
DIRECTORY_VALUES=(
    "pyramid" "pyramid" "pyramid"
    "trophy" "trophy" "trophy" "trophy" "trophy"
    "pyramid" "pyramid"
)

# Lookup function for project type strategy
get_project_type_strategy() {
    local key="$1"
    local i
    for i in "${!PROJECT_TYPE_KEYS[@]}"; do
        if [[ "${PROJECT_TYPE_KEYS[$i]}" == "$key" ]]; then
            echo "${PROJECT_TYPE_VALUES[$i]}"
            return 0
        fi
    done
    echo "auto"
}

# Lookup function for directory strategy
get_directory_strategy() {
    local key="$1"
    local i
    for i in "${!DIRECTORY_KEYS[@]}"; do
        if [[ "${DIRECTORY_KEYS[$i]}" == "$key" ]]; then
            echo "${DIRECTORY_VALUES[$i]}"
            return 0
        fi
    done
    echo ""
}

# ============================================================================
# STRATEGY DETECTION
# ============================================================================

# Detect testing strategy for a project
# Args: $1 = project_dir, $2 = project_type (optional)
detect_testing_strategy() {
    local project_dir="${1:-.}"
    local project_type="${2:-}"

    # Check for explicit override in project settings
    local project_settings="${project_dir}/.claude/settings.json"
    if [[ -f "$project_settings" ]]; then
        local override
        override=$(jq -r '.testing.strategy // empty' "$project_settings" 2>/dev/null || true)
        if [[ -n "$override" && "$override" != "null" ]]; then
            echo "$override"
            return 0
        fi
    fi

    # Use project type if provided
    if [[ -n "$project_type" ]]; then
        local strategy
        strategy=$(get_project_type_strategy "$project_type")
        if [[ "$strategy" != "auto" ]]; then
            echo "$strategy"
            return 0
        fi
    fi

    # Auto-detect based on project characteristics
    detect_strategy_from_project "$project_dir"
}

# Detect strategy based on project characteristics
detect_strategy_from_project() {
    local project_dir="$1"

    # Check for UI framework indicators (trophy)
    if [[ -f "${project_dir}/next.config.js" ]] || \
       [[ -f "${project_dir}/next.config.ts" ]] || \
       [[ -f "${project_dir}/next.config.mjs" ]]; then
        echo "trophy"
        return 0
    fi

    # Check for React (trophy)
    if [[ -f "${project_dir}/package.json" ]]; then
        if grep -q '"react"' "${project_dir}/package.json" 2>/dev/null; then
            echo "trophy"
            return 0
        fi
    fi

    # Check for library indicators (pyramid)
    if [[ -f "${project_dir}/package.json" ]]; then
        # Has "main" or "exports" but no "private": true usually indicates a library
        if jq -e '.main or .exports' "${project_dir}/package.json" >/dev/null 2>&1; then
            if ! jq -e '.private == true' "${project_dir}/package.json" >/dev/null 2>&1; then
                echo "pyramid"
                return 0
            fi
        fi
    fi

    # Check for Rust/Go/Python packages (pyramid)
    if [[ -f "${project_dir}/Cargo.toml" ]] || \
       [[ -f "${project_dir}/go.mod" ]] || \
       [[ -f "${project_dir}/pyproject.toml" ]] || \
       [[ -f "${project_dir}/setup.py" ]]; then
        echo "pyramid"
        return 0
    fi

    # Default to trophy for modern full-stack apps
    echo "trophy"
}

# Detect strategy for a specific directory within a project
# Args: $1 = project_dir, $2 = relative_path
detect_directory_strategy() {
    local project_dir="${1:-.}"
    local relative_path="${2:-}"

    # Check for folder-level override in CLAUDE.md frontmatter
    local folder_claude="${project_dir}/${relative_path}/CLAUDE.md"
    if [[ -f "$folder_claude" ]]; then
        local override
        override=$(grep -m1 "^testing_strategy:" "$folder_claude" 2>/dev/null | cut -d: -f2 | tr -d ' ' || true)
        if [[ -n "$override" ]]; then
            echo "$override"
            return 0
        fi
    fi

    # Check directory patterns
    local i
    for i in "${!DIRECTORY_KEYS[@]}"; do
        local pattern="${DIRECTORY_KEYS[$i]}"
        if [[ "$relative_path" == "$pattern"* ]] || \
           [[ "$relative_path" == *"/$pattern"* ]]; then
            echo "${DIRECTORY_VALUES[$i]}"
            return 0
        fi
    done

    # Fall back to project-level strategy
    detect_testing_strategy "$project_dir"
}

# ============================================================================
# STRATEGY DESCRIPTIONS
# ============================================================================

# Get human-readable description of a strategy
describe_strategy() {
    local strategy="$1"

    case "$strategy" in
        pyramid)
            cat << 'EOF'
Testing Pyramid (Traditional)
├── Few E2E tests (slow, high confidence)
├── Some integration tests (moderate)
└── Many unit tests (fast, isolated)

Best for: Libraries, utilities, pure algorithms, microservices
Focus: Test implementation details, edge cases, fast feedback
EOF
            ;;
        trophy)
            cat << 'EOF'
Testing Trophy (Kent C. Dodds)
├── Few E2E tests (critical paths only)
├── MOST integration tests (best ROI)
├── Some unit tests (complex logic)
└── Static analysis (TypeScript, ESLint)

Best for: React apps, user-facing features, full-stack apps
Focus: Test user behavior, not implementation details
EOF
            ;;
        balanced)
            cat << 'EOF'
Balanced Strategy (Monorepo)
├── E2E for critical user journeys
├── Integration for package boundaries
├── Unit tests vary by package type
└── Per-folder strategy based on content

Best for: Monorepos with mixed package types
Focus: Let each package choose appropriate strategy
EOF
            ;;
        *)
            echo "Unknown strategy: $strategy"
            ;;
    esac
}

# Get testing guidance based on strategy
get_strategy_guidance() {
    local strategy="$1"

    case "$strategy" in
        pyramid)
            cat << 'EOF'
## Testing Guidance (Pyramid)

### Unit Tests (Priority: HIGH)
- Test every public function
- Cover edge cases extensively
- Mock external dependencies
- Aim for >80% coverage

### Integration Tests (Priority: MEDIUM)
- Test module boundaries
- Verify API contracts
- Use real dependencies when practical

### E2E Tests (Priority: LOW)
- Critical happy paths only
- Smoke tests for deployment validation
EOF
            ;;
        trophy)
            cat << 'EOF'
## Testing Guidance (Trophy)

### Integration Tests (Priority: HIGH)
- Test user workflows end-to-end within the app
- Use Testing Library patterns (query by role, text)
- Test real components with real hooks
- Mock only network/external services

### Unit Tests (Priority: MEDIUM)
- Complex business logic only
- Pure utility functions
- Skip for simple components

### E2E Tests (Priority: MEDIUM)
- Critical user journeys
- Cross-page workflows
- Authentication flows
EOF
            ;;
        balanced)
            cat << 'EOF'
## Testing Guidance (Balanced)

Check per-folder strategy:
- `lib/`, `packages/utils/` → Pyramid (many unit tests)
- `apps/`, `src/components/` → Trophy (integration-focused)
- Shared packages → Integration tests at boundaries

Use `/test` command with --strategy flag to override per-run.
EOF
            ;;
    esac
}

# ============================================================================
# CLI INTERFACE
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        detect)
            detect_testing_strategy "${2:-.}" "${3:-}"
            ;;
        detect-dir)
            detect_directory_strategy "${2:-.}" "${3:-}"
            ;;
        describe)
            describe_strategy "${2:-pyramid}"
            ;;
        guidance)
            get_strategy_guidance "${2:-pyramid}"
            ;;
        *)
            echo "Usage: $0 {detect|detect-dir|describe|guidance} [args]"
            echo ""
            echo "Commands:"
            echo "  detect [project_dir] [project_type]  - Detect project strategy"
            echo "  detect-dir [project_dir] [rel_path]  - Detect directory strategy"
            echo "  describe [strategy]                  - Describe a strategy"
            echo "  guidance [strategy]                  - Get testing guidance"
            exit 1
            ;;
    esac
fi
