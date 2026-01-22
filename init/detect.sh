#!/usr/bin/env bash
#
# Jarvis Project Detection Script
# ================================
# Auto-detects project type, tech stack, and frameworks.
# Outputs detection results as JSON for use by init.sh.
#
# Usage:
#   source detect.sh
#   detect_project /path/to/project
#
# Output Format (JSON):
#   {
#     "project_type": "next-app|monorepo|library|standalone",
#     "stack": ["next.js", "typescript", "tailwind", ...],
#     "frameworks": {...},
#     "tools": {...},
#     "suggested_template": "web-fullstack|minimal|...",
#     "has_existing_claude": boolean
#   }

set -euo pipefail

# =============================================================================
# DETECTION FUNCTIONS
# =============================================================================

# Main detection entry point
detect_project() {
    local project_dir="${1:-.}"

    # Ensure we're working with absolute path
    project_dir="$(cd "$project_dir" && pwd)"

    # Initialize results
    local project_type="standalone"
    local stack="[]"
    local frameworks="{}"
    local tools="{}"
    local suggested_template="minimal"
    local has_existing_claude=false

    # Check for existing .claude folder
    if [[ -d "${project_dir}/.claude" ]]; then
        has_existing_claude=true
    fi

    # Run all detection phases
    project_type=$(detect_project_type "$project_dir")
    stack=$(detect_tech_stack "$project_dir")
    frameworks=$(detect_frameworks "$project_dir")
    tools=$(detect_tools "$project_dir")
    suggested_template=$(suggest_template "$project_type" "$stack" "$frameworks")
    testing_strategy=$(detect_testing_strategy "$project_dir" "$project_type" "$stack")

    # Build final JSON output
    jq -n \
        --arg project_type "$project_type" \
        --argjson stack "$stack" \
        --argjson frameworks "$frameworks" \
        --argjson tools "$tools" \
        --arg suggested_template "$suggested_template" \
        --argjson has_existing_claude "$has_existing_claude" \
        --arg testing_strategy "$testing_strategy" \
        '{
            project_type: $project_type,
            stack: $stack,
            frameworks: $frameworks,
            tools: $tools,
            suggested_template: $suggested_template,
            has_existing_claude: $has_existing_claude,
            testing_strategy: $testing_strategy
        }'
}

# =============================================================================
# PROJECT TYPE DETECTION
# =============================================================================

detect_project_type() {
    local project_dir="$1"

    # Monorepo detection
    if [[ -f "${project_dir}/turbo.json" ]] || \
       [[ -f "${project_dir}/pnpm-workspace.yaml" ]] || \
       [[ -f "${project_dir}/lerna.json" ]] || \
       [[ -f "${project_dir}/nx.json" ]]; then
        echo "monorepo"
        return
    fi

    # Next.js App detection
    if [[ -f "${project_dir}/next.config.js" ]] || \
       [[ -f "${project_dir}/next.config.ts" ]] || \
       [[ -f "${project_dir}/next.config.mjs" ]]; then
        echo "next-app"
        return
    fi

    # Flutter detection
    if [[ -f "${project_dir}/pubspec.yaml" ]] && \
       [[ -f "${project_dir}/lib/main.dart" ]]; then
        echo "flutter-app"
        return
    fi

    # iOS/Swift detection
    if find "$project_dir" -maxdepth 2 -name "*.xcodeproj" -type d 2>/dev/null | grep -q . || \
       [[ -f "${project_dir}/Package.swift" ]]; then
        echo "ios-app"
        return
    fi

    # Python package detection
    if [[ -f "${project_dir}/pyproject.toml" ]] || \
       [[ -f "${project_dir}/setup.py" ]]; then
        echo "python-package"
        return
    fi

    # Rust detection
    if [[ -f "${project_dir}/Cargo.toml" ]]; then
        echo "rust-package"
        return
    fi

    # Go detection
    if [[ -f "${project_dir}/go.mod" ]]; then
        echo "go-module"
        return
    fi

    # Library detection (has packages but no apps)
    if [[ -d "${project_dir}/packages" ]] && [[ ! -d "${project_dir}/apps" ]]; then
        echo "library"
        return
    fi

    # React app detection (standalone)
    if [[ -f "${project_dir}/src/App.tsx" ]] || \
       [[ -f "${project_dir}/src/App.jsx" ]]; then
        echo "react-app"
        return
    fi

    # Express/Node API detection
    if [[ -f "${project_dir}/src/server.ts" ]] || \
       [[ -f "${project_dir}/src/index.ts" ]] || \
       [[ -f "${project_dir}/src/app.ts" ]]; then
        if grep -q "express\|fastify\|hono\|koa" "${project_dir}/package.json" 2>/dev/null; then
            echo "node-api"
            return
        fi
    fi

    echo "standalone"
}

# =============================================================================
# TECH STACK DETECTION
# =============================================================================

detect_tech_stack() {
    local project_dir="$1"
    local stack="[]"

    # JavaScript/TypeScript ecosystem
    if [[ -f "${project_dir}/package.json" ]]; then
        local pkg_json
        pkg_json=$(cat "${project_dir}/package.json" 2>/dev/null || echo "{}")

        # TypeScript
        if [[ -f "${project_dir}/tsconfig.json" ]] || \
           echo "$pkg_json" | jq -e '.devDependencies.typescript // .dependencies.typescript' > /dev/null 2>&1; then
            stack=$(echo "$stack" | jq '. + ["typescript"]')
        fi

        # Next.js
        if echo "$pkg_json" | jq -e '.dependencies.next' > /dev/null 2>&1; then
            stack=$(echo "$stack" | jq '. + ["next.js"]')
        fi

        # React
        if echo "$pkg_json" | jq -e '.dependencies.react' > /dev/null 2>&1; then
            stack=$(echo "$stack" | jq '. + ["react"]')
        fi

        # Vue
        if echo "$pkg_json" | jq -e '.dependencies.vue' > /dev/null 2>&1; then
            stack=$(echo "$stack" | jq '. + ["vue"]')
        fi

        # Svelte
        if echo "$pkg_json" | jq -e '.dependencies.svelte // .devDependencies.svelte' > /dev/null 2>&1; then
            stack=$(echo "$stack" | jq '. + ["svelte"]')
        fi

        # Tailwind CSS
        if [[ -f "${project_dir}/tailwind.config.js" ]] || \
           [[ -f "${project_dir}/tailwind.config.ts" ]] || \
           echo "$pkg_json" | jq -e '.devDependencies.tailwindcss' > /dev/null 2>&1; then
            stack=$(echo "$stack" | jq '. + ["tailwind"]')
        fi

        # Supabase
        if [[ -f "${project_dir}/supabase/config.toml" ]] || \
           echo "$pkg_json" | jq -e '.dependencies["@supabase/supabase-js"]' > /dev/null 2>&1; then
            stack=$(echo "$stack" | jq '. + ["supabase"]')
        fi

        # Prisma
        if [[ -f "${project_dir}/prisma/schema.prisma" ]] || \
           echo "$pkg_json" | jq -e '.devDependencies.prisma' > /dev/null 2>&1; then
            stack=$(echo "$stack" | jq '. + ["prisma"]')
        fi

        # Drizzle
        if [[ -f "${project_dir}/drizzle.config.ts" ]] || \
           echo "$pkg_json" | jq -e '.dependencies["drizzle-orm"]' > /dev/null 2>&1; then
            stack=$(echo "$stack" | jq '. + ["drizzle"]')
        fi

        # Express
        if echo "$pkg_json" | jq -e '.dependencies.express' > /dev/null 2>&1; then
            stack=$(echo "$stack" | jq '. + ["express"]')
        fi

        # Fastify
        if echo "$pkg_json" | jq -e '.dependencies.fastify' > /dev/null 2>&1; then
            stack=$(echo "$stack" | jq '. + ["fastify"]')
        fi

        # Hono
        if echo "$pkg_json" | jq -e '.dependencies.hono' > /dev/null 2>&1; then
            stack=$(echo "$stack" | jq '. + ["hono"]')
        fi
    fi

    # Python ecosystem
    if [[ -f "${project_dir}/pyproject.toml" ]] || \
       [[ -f "${project_dir}/requirements.txt" ]] || \
       [[ -f "${project_dir}/setup.py" ]]; then
        stack=$(echo "$stack" | jq '. + ["python"]')

        local deps=""
        if [[ -f "${project_dir}/pyproject.toml" ]]; then
            deps=$(cat "${project_dir}/pyproject.toml" 2>/dev/null || echo "")
        elif [[ -f "${project_dir}/requirements.txt" ]]; then
            deps=$(cat "${project_dir}/requirements.txt" 2>/dev/null || echo "")
        fi

        # FastAPI
        if echo "$deps" | grep -qi "fastapi"; then
            stack=$(echo "$stack" | jq '. + ["fastapi"]')
        fi

        # Django
        if echo "$deps" | grep -qi "django"; then
            stack=$(echo "$stack" | jq '. + ["django"]')
        fi

        # Flask
        if echo "$deps" | grep -qi "flask"; then
            stack=$(echo "$stack" | jq '. + ["flask"]')
        fi
    fi

    # Flutter/Dart
    if [[ -f "${project_dir}/pubspec.yaml" ]]; then
        stack=$(echo "$stack" | jq '. + ["flutter", "dart"]')

        local pubspec
        pubspec=$(cat "${project_dir}/pubspec.yaml" 2>/dev/null || echo "")

        # Firebase
        if echo "$pubspec" | grep -qi "firebase"; then
            stack=$(echo "$stack" | jq '. + ["firebase"]')
        fi
    fi

    # Rust
    if [[ -f "${project_dir}/Cargo.toml" ]]; then
        stack=$(echo "$stack" | jq '. + ["rust"]')
    fi

    # Go
    if [[ -f "${project_dir}/go.mod" ]]; then
        stack=$(echo "$stack" | jq '. + ["go"]')
    fi

    # Swift/iOS
    if find "$project_dir" -maxdepth 3 -name "*.swift" -type f 2>/dev/null | head -1 | grep -q .; then
        stack=$(echo "$stack" | jq '. + ["swift"]')
    fi

    echo "$stack"
}

# =============================================================================
# FRAMEWORK DETECTION
# =============================================================================

detect_frameworks() {
    local project_dir="$1"
    local frameworks="{}"

    if [[ -f "${project_dir}/package.json" ]]; then
        local pkg_json
        pkg_json=$(cat "${project_dir}/package.json" 2>/dev/null || echo "{}")

        # Testing frameworks
        if echo "$pkg_json" | jq -e '.devDependencies.vitest' > /dev/null 2>&1; then
            frameworks=$(echo "$frameworks" | jq '.testing = "vitest"')
        elif echo "$pkg_json" | jq -e '.devDependencies.jest' > /dev/null 2>&1; then
            frameworks=$(echo "$frameworks" | jq '.testing = "jest"')
        elif echo "$pkg_json" | jq -e '.devDependencies.mocha' > /dev/null 2>&1; then
            frameworks=$(echo "$frameworks" | jq '.testing = "mocha"')
        fi

        # E2E testing
        if [[ -f "${project_dir}/playwright.config.ts" ]] || \
           echo "$pkg_json" | jq -e '.devDependencies["@playwright/test"]' > /dev/null 2>&1; then
            frameworks=$(echo "$frameworks" | jq '.e2e = "playwright"')
        elif echo "$pkg_json" | jq -e '.devDependencies.cypress' > /dev/null 2>&1; then
            frameworks=$(echo "$frameworks" | jq '.e2e = "cypress"')
        fi

        # UI component libraries
        if echo "$pkg_json" | jq -e '.dependencies["@radix-ui/react-dialog"] // .dependencies["@radix-ui/themes"]' > /dev/null 2>&1; then
            frameworks=$(echo "$frameworks" | jq '.ui = "radix"')
        elif echo "$pkg_json" | jq -e '.dependencies["@chakra-ui/react"]' > /dev/null 2>&1; then
            frameworks=$(echo "$frameworks" | jq '.ui = "chakra"')
        elif echo "$pkg_json" | jq -e '.dependencies["@mui/material"]' > /dev/null 2>&1; then
            frameworks=$(echo "$frameworks" | jq '.ui = "mui"')
        elif echo "$pkg_json" | jq -e '.dependencies["shadcn-ui"] // .dependencies["@shadcn/ui"]' > /dev/null 2>&1; then
            frameworks=$(echo "$frameworks" | jq '.ui = "shadcn"')
        fi

        # State management
        if echo "$pkg_json" | jq -e '.dependencies.zustand' > /dev/null 2>&1; then
            frameworks=$(echo "$frameworks" | jq '.state = "zustand"')
        elif echo "$pkg_json" | jq -e '.dependencies["@reduxjs/toolkit"]' > /dev/null 2>&1; then
            frameworks=$(echo "$frameworks" | jq '.state = "redux"')
        elif echo "$pkg_json" | jq -e '.dependencies.jotai' > /dev/null 2>&1; then
            frameworks=$(echo "$frameworks" | jq '.state = "jotai"')
        fi

        # Auth
        if echo "$pkg_json" | jq -e '.dependencies["next-auth"] // .dependencies["@auth/core"]' > /dev/null 2>&1; then
            frameworks=$(echo "$frameworks" | jq '.auth = "next-auth"')
        elif echo "$pkg_json" | jq -e '.dependencies["@clerk/nextjs"]' > /dev/null 2>&1; then
            frameworks=$(echo "$frameworks" | jq '.auth = "clerk"')
        fi

        # Payments
        if echo "$pkg_json" | jq -e '.dependencies["@polar-sh/sdk"] // .dependencies["@polar-sh/nextjs"]' > /dev/null 2>&1; then
            frameworks=$(echo "$frameworks" | jq '.payments = "polar"')
        elif echo "$pkg_json" | jq -e '.dependencies.stripe' > /dev/null 2>&1; then
            frameworks=$(echo "$frameworks" | jq '.payments = "stripe"')
        fi

        # Analytics
        if echo "$pkg_json" | jq -e '.dependencies["@umami/tracker"]' > /dev/null 2>&1; then
            frameworks=$(echo "$frameworks" | jq '.analytics = "umami"')
        elif echo "$pkg_json" | jq -e '.dependencies["@vercel/analytics"]' > /dev/null 2>&1; then
            frameworks=$(echo "$frameworks" | jq '.analytics = "vercel"')
        fi
    fi

    # Python testing
    if [[ -f "${project_dir}/pyproject.toml" ]] || [[ -f "${project_dir}/pytest.ini" ]]; then
        if grep -qi "pytest" "${project_dir}/pyproject.toml" 2>/dev/null || \
           [[ -f "${project_dir}/pytest.ini" ]]; then
            frameworks=$(echo "$frameworks" | jq '.testing = "pytest"')
        fi
    fi

    echo "$frameworks"
}

# =============================================================================
# TOOLS DETECTION
# =============================================================================

detect_tools() {
    local project_dir="$1"
    local tools="{}"

    # Package manager
    if [[ -f "${project_dir}/pnpm-lock.yaml" ]]; then
        tools=$(echo "$tools" | jq '.package_manager = "pnpm"')
    elif [[ -f "${project_dir}/yarn.lock" ]]; then
        tools=$(echo "$tools" | jq '.package_manager = "yarn"')
    elif [[ -f "${project_dir}/bun.lockb" ]]; then
        tools=$(echo "$tools" | jq '.package_manager = "bun"')
    elif [[ -f "${project_dir}/package-lock.json" ]]; then
        tools=$(echo "$tools" | jq '.package_manager = "npm"')
    fi

    # Linting
    if [[ -f "${project_dir}/.eslintrc.js" ]] || \
       [[ -f "${project_dir}/.eslintrc.json" ]] || \
       [[ -f "${project_dir}/eslint.config.js" ]] || \
       [[ -f "${project_dir}/eslint.config.mjs" ]]; then
        tools=$(echo "$tools" | jq '.linting = "eslint"')
    fi

    if [[ -f "${project_dir}/biome.json" ]]; then
        tools=$(echo "$tools" | jq '.linting = "biome"')
    fi

    # Formatting
    if [[ -f "${project_dir}/.prettierrc" ]] || \
       [[ -f "${project_dir}/.prettierrc.json" ]] || \
       [[ -f "${project_dir}/prettier.config.js" ]]; then
        tools=$(echo "$tools" | jq '.formatting = "prettier"')
    fi

    # CI/CD
    if [[ -d "${project_dir}/.github/workflows" ]]; then
        tools=$(echo "$tools" | jq '.ci = "github-actions"')
    elif [[ -f "${project_dir}/.gitlab-ci.yml" ]]; then
        tools=$(echo "$tools" | jq '.ci = "gitlab-ci"')
    elif [[ -f "${project_dir}/.circleci/config.yml" ]]; then
        tools=$(echo "$tools" | jq '.ci = "circleci"')
    fi

    # Containerization
    if [[ -f "${project_dir}/Dockerfile" ]] || [[ -f "${project_dir}/docker-compose.yml" ]]; then
        tools=$(echo "$tools" | jq '.containerization = "docker"')
    fi

    # Monorepo tools
    if [[ -f "${project_dir}/turbo.json" ]]; then
        tools=$(echo "$tools" | jq '.monorepo = "turborepo"')
    elif [[ -f "${project_dir}/nx.json" ]]; then
        tools=$(echo "$tools" | jq '.monorepo = "nx"')
    elif [[ -f "${project_dir}/lerna.json" ]]; then
        tools=$(echo "$tools" | jq '.monorepo = "lerna"')
    fi

    echo "$tools"
}

# =============================================================================
# TEMPLATE SUGGESTION
# =============================================================================

suggest_template() {
    local project_type="$1"
    local stack="$2"
    local frameworks="$3"

    # Check for full-stack web app
    if echo "$stack" | jq -e 'index("next.js")' > /dev/null 2>&1; then
        if echo "$stack" | jq -e 'index("supabase")' > /dev/null 2>&1; then
            echo "web-fullstack"
            return
        fi
        echo "web-nextjs"
        return
    fi

    # Check for Flutter
    if echo "$stack" | jq -e 'index("flutter")' > /dev/null 2>&1; then
        echo "mobile-flutter"
        return
    fi

    # Check for iOS
    if echo "$stack" | jq -e 'index("swift")' > /dev/null 2>&1; then
        echo "mobile-ios"
        return
    fi

    # Check for Python backend
    if echo "$stack" | jq -e 'index("fastapi") or index("django") or index("flask")' > /dev/null 2>&1; then
        echo "backend-python"
        return
    fi

    # Check for Node backend
    if echo "$stack" | jq -e 'index("express") or index("fastify") or index("hono")' > /dev/null 2>&1; then
        echo "backend-node"
        return
    fi

    # Check for React standalone
    if echo "$stack" | jq -e 'index("react")' > /dev/null 2>&1; then
        echo "web-react"
        return
    fi

    # Monorepo
    if [[ "$project_type" == "monorepo" ]]; then
        echo "monorepo"
        return
    fi

    # Library
    if [[ "$project_type" == "library" ]]; then
        echo "library"
        return
    fi

    # Default to minimal
    echo "minimal"
}

# =============================================================================
# TESTING STRATEGY DETECTION
# =============================================================================

# Detect appropriate testing strategy based on project type and characteristics
# Returns: pyramid, trophy, or balanced
detect_testing_strategy() {
    local project_dir="${1:-.}"
    local project_type="${2:-standalone}"
    local stack="${3:-[]}"

    # Check for explicit override in existing settings
    local project_settings="${project_dir}/.claude/settings.json"
    if [[ -f "$project_settings" ]]; then
        local override
        override=$(jq -r '.testing.strategy // empty' "$project_settings" 2>/dev/null || true)
        if [[ -n "$override" && "$override" != "null" ]]; then
            echo "$override"
            return
        fi
    fi

    # Strategy by project type
    case "$project_type" in
        library|rust-package|go-module|python-package)
            echo "pyramid"
            return
            ;;
        next-app|react-app|flutter-app)
            echo "trophy"
            return
            ;;
        monorepo)
            echo "balanced"
            return
            ;;
    esac

    # Strategy by stack detection
    # React/Next.js/UI-heavy → Trophy
    if echo "$stack" | jq -e 'index("react") or index("next.js") or index("vue") or index("svelte")' > /dev/null 2>&1; then
        echo "trophy"
        return
    fi

    # Backend with DB → Trophy (integration matters)
    if echo "$stack" | jq -e '(index("prisma") or index("drizzle") or index("supabase")) and (index("express") or index("fastify") or index("hono"))' > /dev/null 2>&1; then
        echo "trophy"
        return
    fi

    # Pure backend/API → Pyramid (test contracts)
    if echo "$stack" | jq -e 'index("express") or index("fastify") or index("hono") or index("fastapi") or index("django")' > /dev/null 2>&1; then
        echo "pyramid"
        return
    fi

    # Default: trophy for modern apps (integration-focused)
    echo "trophy"
}

# =============================================================================
# STANDALONE EXECUTION
# =============================================================================

# If run directly (not sourced), execute detection
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 0 ]]; then
        detect_project "."
    else
        detect_project "$1"
    fi
fi
