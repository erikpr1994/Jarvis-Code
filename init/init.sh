#!/usr/bin/env bash
#
# Jarvis Initialization Script
# ============================
# Main entry point for initializing Jarvis in a project directory.
#
# Usage:
#   jarvis init                    # Interactive initialization (full interview)
#   jarvis init --template NAME    # Quick init with template (skip interview)
#   jarvis init --refresh          # Re-initialize (preserve customizations)
#   jarvis init --claude-md-only   # Generate missing CLAUDE.md files only
#
# Exit codes:
#   0 - Success
#   1 - General error
#   2 - Invalid arguments
#   3 - Detection failed
#   4 - Template not found
#   5 - Permission denied

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JARVIS_ROOT="$(dirname "$SCRIPT_DIR")"
GLOBAL_DIR="${JARVIS_ROOT}/global"
TEMPLATES_DIR="${JARVIS_ROOT}/templates"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_step() {
    echo -e "\n${CYAN}${BOLD}==> $1${NC}"
}

print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
     ██╗ █████╗ ██████╗ ██╗   ██╗██╗███████╗
     ██║██╔══██╗██╔══██╗██║   ██║██║██╔════╝
     ██║███████║██████╔╝██║   ██║██║███████╗
██   ██║██╔══██║██╔══██╗╚██╗ ██╔╝██║╚════██║
╚█████╔╝██║  ██║██║  ██║ ╚████╔╝ ██║███████║
 ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚══════╝
EOF
    echo -e "${NC}"
    echo -e "${BOLD}Jarvis Initialization System${NC}"
    echo -e "Version 1.0.0"
    echo ""
}

# =============================================================================
# PHASE 1: AUTO-DETECTION
# =============================================================================

run_detection() {
    local project_dir="$1"
    log_step "Phase 1: Auto-Detection"

    # Source the detection script
    source "${SCRIPT_DIR}/detect.sh"

    # Run detection and capture JSON output
    local detection_result
    detection_result=$(detect_project "$project_dir")

    if [[ $? -ne 0 ]]; then
        log_error "Detection failed"
        return 3
    fi

    echo "$detection_result"
}

# =============================================================================
# PHASE 2: INTERVIEW
# =============================================================================

run_interview() {
    local detection_json="$1"
    local skip_interview="$2"

    log_step "Phase 2: Interview"

    if [[ "$skip_interview" == "true" ]]; then
        log_info "Skipping interview (template mode)"
        # Return default answers based on detection
        generate_default_answers "$detection_json"
        return 0
    fi

    # Check if we have an existing .claude/settings.json
    if [[ -f ".claude/settings.json" ]]; then
        log_info "Found existing configuration"
        read -p "Use existing settings? [Y/n]: " use_existing
        if [[ "${use_existing:-Y}" =~ ^[Yy]$ ]]; then
            cat ".claude/settings.json"
            return 0
        fi
    fi

    # Run interactive interview
    interview_interactive "$detection_json"
}

interview_interactive() {
    local detection_json="$1"
    local answers="{}"

    # Extract detected values
    local detected_stack
    detected_stack=$(echo "$detection_json" | jq -r '.stack | join(", ")' 2>/dev/null || echo "unknown")
    local detected_template
    detected_template=$(echo "$detection_json" | jq -r '.suggested_template' 2>/dev/null || echo "minimal")
    local detected_project_type
    detected_project_type=$(echo "$detection_json" | jq -r '.project_type' 2>/dev/null || echo "standalone")

    echo ""
    echo -e "${BOLD}Detected Configuration:${NC}"
    echo -e "  Stack: ${CYAN}${detected_stack}${NC}"
    echo -e "  Template: ${CYAN}${detected_template}${NC}"
    echo -e "  Type: ${CYAN}${detected_project_type}${NC}"
    echo ""

    # Q1: Confirm detection
    read -p "Is this detection correct? [Y/n]: " confirm_detection
    if [[ "${confirm_detection:-Y}" =~ ^[Nn]$ ]]; then
        log_info "Please manually select options below"
    fi

    # Q2: Project Type
    echo ""
    echo -e "${BOLD}Q1: Project Type${NC}"
    echo "  1) SaaS Product (user accounts, billing, dashboard)"
    echo "  2) Client Project (defined requirements, external stakeholder)"
    echo "  3) Open Source (community, contributions)"
    echo "  4) Internal Tool (company use)"
    echo "  5) Personal/Learning"
    read -p "Select [1-5] (default: 1): " project_type_choice

    case "${project_type_choice:-1}" in
        1) project_type="saas" ;;
        2) project_type="client" ;;
        3) project_type="oss" ;;
        4) project_type="internal" ;;
        5) project_type="personal" ;;
        *) project_type="saas" ;;
    esac

    # Q3: Git Workflow
    echo ""
    echo -e "${BOLD}Q2: Git Workflow${NC}"
    echo "  1) GitHub Flow (feature branches)"
    echo "  2) GitFlow (develop/release/hotfix)"
    echo "  3) Trunk-based (main only)"

    default_git="1"

    read -p "Select [1-3] (default: ${default_git}): " git_choice

    case "${git_choice:-$default_git}" in
        1) git_workflow="github-flow" ;;
        2) git_workflow="gitflow" ;;
        3) git_workflow="trunk" ;;
        *) git_workflow="github-flow" ;;
    esac

    # Q4: Code Review
    echo ""
    echo -e "${BOLD}Q3: Code Review Integration${NC}"
    echo "  1) CodeRabbit (automated AI review)"
    echo "  2) GitHub Reviews only"
    echo "  3) Both CodeRabbit + GitHub"
    echo "  4) None (solo project)"
    read -p "Select [1-4] (default: 2): " review_choice

    case "${review_choice:-2}" in
        1) code_review="coderabbit" ;;
        2) code_review="github" ;;
        3) code_review="both" ;;
        4) code_review="none" ;;
        *) code_review="github" ;;
    esac

    # Q5: TDD Strictness
    echo ""
    echo -e "${BOLD}Q4: Testing Strategy${NC}"
    echo "  1) Iron Law (no exceptions - write tests first ALWAYS)"
    echo "  2) Strong (tests required, but can write code first for exploration)"
    echo "  3) Flexible (tests encouraged but not required)"
    read -p "Select [1-3] (default: 2): " tdd_choice

    case "${tdd_choice:-2}" in
        1) tdd_level="iron-law" ;;
        2) tdd_level="strong" ;;
        3) tdd_level="flexible" ;;
        *) tdd_level="strong" ;;
    esac

    # Q6: Test Types
    echo ""
    echo -e "${BOLD}Q5: Test Types (comma-separated)${NC}"
    echo "  1) Unit tests"
    echo "  2) Integration tests"
    echo "  3) E2E tests"
    echo "  4) Visual regression tests"
    echo "  5) Performance tests"
    read -p "Select [e.g., 1,2,3] (default: 1,2): " test_types_choice

    test_types_choice="${test_types_choice:-1,2}"
    test_types="[]"
    if [[ "$test_types_choice" == *"1"* ]]; then test_types=$(echo "$test_types" | jq '. + ["unit"]'); fi
    if [[ "$test_types_choice" == *"2"* ]]; then test_types=$(echo "$test_types" | jq '. + ["integration"]'); fi
    if [[ "$test_types_choice" == *"3"* ]]; then test_types=$(echo "$test_types" | jq '. + ["e2e"]'); fi
    if [[ "$test_types_choice" == *"4"* ]]; then test_types=$(echo "$test_types" | jq '. + ["visual"]'); fi
    if [[ "$test_types_choice" == *"5"* ]]; then test_types=$(echo "$test_types" | jq '. + ["performance"]'); fi

    # Q7: Documentation
    echo ""
    echo -e "${BOLD}Q6: Documentation Structure${NC}"
    echo "  1) Full Lifecycle (specs/ -> plans/ -> design/ -> decisions/)"
    echo "  2) Simple (just README and docs/)"
    echo "  3) Minimal (README only)"
    read -p "Select [1-3] (default: 2): " docs_choice

    case "${docs_choice:-2}" in
        1) docs_level="full" ;;
        2) docs_level="simple" ;;
        3) docs_level="minimal" ;;
        *) docs_level="simple" ;;
    esac

    # Build answers JSON
    local project_name
    project_name=$(basename "$(pwd)")

    answers=$(jq -n \
        --arg name "$project_name" \
        --arg type "$project_type" \
        --arg template "$detected_template" \
        --arg git "$git_workflow" \
        --arg review "$code_review" \
        --arg tdd "$tdd_level" \
        --argjson test_types "$test_types" \
        --arg docs "$docs_level" \
        --argjson detection "$detection_json" \
        '{
            project: {
                name: $name,
                type: $type,
                template: $template
            },
            workflow: {
                git: $git,
                review: $review,
                tdd: $tdd,
                test_types: $test_types
            },
            documentation: {
                level: $docs
            },
            detection: $detection
        }')

    echo "$answers"
}

generate_default_answers() {
    local detection_json="$1"
    local project_name
    project_name=$(basename "$(pwd)")
    local template
    template=$(echo "$detection_json" | jq -r '.suggested_template // "minimal"')

    jq -n \
        --arg name "$project_name" \
        --arg template "$template" \
        --argjson detection "$detection_json" \
        '{
            project: {
                name: $name,
                type: "saas",
                template: $template
            },
            workflow: {
                git: "github-flow",
                review: "github",
                tdd: "strong",
                test_types: ["unit", "integration"]
            },
            documentation: {
                level: "simple"
            },
            detection: $detection
        }'
}

# =============================================================================
# PHASE 3: TEMPLATE SELECTION
# =============================================================================

select_template() {
    local answers_json="$1"
    local template_name
    template_name=$(echo "$answers_json" | jq -r '.project.template // "minimal"')

    log_step "Phase 3: Template Selection"
    log_info "Using template: ${template_name}"

    local template_file="${TEMPLATES_DIR}/project-types/${template_name}.yaml"

    # Check if template exists, otherwise use minimal
    if [[ ! -f "$template_file" ]]; then
        log_warning "Template '${template_name}' not found, using minimal"
        template_name="minimal"
        template_file="${TEMPLATES_DIR}/project-types/minimal.yaml"

        # Create minimal template if it doesn't exist
        if [[ ! -f "$template_file" ]]; then
            log_info "Creating minimal template"
            create_minimal_template "$template_file"
        fi
    fi

    echo "$template_name"
}

create_minimal_template() {
    local template_file="$1"
    mkdir -p "$(dirname "$template_file")"

    cat > "$template_file" << 'EOF'
name: minimal
description: Minimal setup for any project type

detection:
  default: true

agents:
  core:
    - implementer
    - code-reviewer

skills:
  always:
    - test-driven-development
    - verification-before-completion
    - git-expert

hooks:
  - session-start
  - skill-activation-prompt

rules: []
EOF
}

# =============================================================================
# PHASE 4: GENERATION
# =============================================================================

generate_structure() {
    local answers_json="$1"
    local template_name="$2"

    log_step "Phase 4: Generation"

    # Create .claude directory structure
    log_info "Creating .claude/ directory structure"
    create_claude_directory "$answers_json"

    # Generate settings.json
    log_info "Generating settings.json"
    generate_settings "$answers_json"

    # Generate CLAUDE.md
    log_info "Generating CLAUDE.md"
    generate_claude_md "$answers_json"

    # Set up hooks
    log_info "Setting up hooks"
    setup_hooks "$answers_json"

    # Create symlinks to global resources (if enabled)
    log_info "Checking symlink configuration"
    create_global_symlinks "$(pwd)"

    # Create initial session file
    log_info "Creating initial session file"
    create_initial_session

    # Create docs structure if needed
    local docs_level
    docs_level=$(echo "$answers_json" | jq -r '.documentation.level // "simple"')
    if [[ "$docs_level" != "minimal" ]]; then
        log_info "Creating documentation structure"
        create_docs_structure "$docs_level"
    fi

    log_success "Generation complete"
}

# =============================================================================
# SYMLINK MANAGEMENT
# =============================================================================

create_global_symlinks() {
    local project_dir="$1"
    local jarvis_root="${JARVIS_ROOT:-$HOME/.jarvis}"

    # Check if symlinks are enabled (via environment or settings)
    local symlink_enabled="${JARVIS_SYMLINK_GLOBALS:-0}"

    # Also check if there's a setting in the project's settings.json
    if [[ -f "${project_dir}/.claude/settings.json" ]]; then
        local settings_symlink
        settings_symlink=$(jq -r '.symlinks.enabled // "false"' "${project_dir}/.claude/settings.json" 2>/dev/null || echo "false")
        if [[ "$settings_symlink" == "true" ]]; then
            symlink_enabled="1"
        fi
    fi

    if [[ "$symlink_enabled" != "1" ]]; then
        log_info "Global symlinks disabled (set JARVIS_SYMLINK_GLOBALS=1 to enable)"
        return 0
    fi

    # Verify Jarvis global directory exists
    if [[ ! -d "$jarvis_root/global" ]]; then
        log_warning "Jarvis global directory not found at $jarvis_root/global"
        log_info "Skipping symlink creation"
        return 0
    fi

    # Create symlinks for global resources
    local symlink_targets=(
        "skills:global/skills"
        "agents:global/agents"
        "patterns:global/patterns"
        "rules:global/rules"
    )

    for target in "${symlink_targets[@]}"; do
        local name="${target%%:*}"
        local source_path="${target#*:}"
        local source_full="${jarvis_root}/${source_path}"
        local dest_full="${project_dir}/.claude/${name}"

        if [[ -d "$source_full" ]]; then
            # Remove existing symlink or directory
            if [[ -L "$dest_full" ]]; then
                rm -f "$dest_full"
            elif [[ -d "$dest_full" ]]; then
                # Don't overwrite existing directories with content
                if [[ -n "$(ls -A "$dest_full" 2>/dev/null)" ]]; then
                    log_warning "Skipping ${name}: directory not empty"
                    continue
                fi
                rmdir "$dest_full" 2>/dev/null || true
            fi

            # Create symlink
            ln -sf "$source_full" "$dest_full"
            log_success "Created symlink: .claude/${name} → ${source_path}"
        else
            log_warning "Source not found for ${name}: ${source_full}"
        fi
    done

    # Update settings to record symlink state
    if [[ -f "${project_dir}/.claude/settings.json" ]]; then
        local updated_settings
        updated_settings=$(jq '.symlinks = {"enabled": true, "created": now | todate}' "${project_dir}/.claude/settings.json")
        echo "$updated_settings" > "${project_dir}/.claude/settings.json"
    fi
}

create_claude_directory() {
    local answers_json="$1"

    mkdir -p .claude/{agents,skills,commands,hooks,rules,tasks}

    # Create init.md command for re-initialization
    cat > .claude/commands/init.md << 'EOF'
# /init Command

Re-run the Jarvis initialization process.

## Usage

```
/init           # Full re-initialization
/init --refresh # Preserve customizations
```

## What This Does

1. Re-detects project structure and tech stack
2. Optionally re-runs the interview
3. Updates templates and configurations
4. Preserves any custom rules, skills, or agents you've added
EOF
}

generate_settings() {
    local answers_json="$1"
    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Build settings.json from answers
    local settings
    settings=$(echo "$answers_json" | jq \
        --arg now "$now" \
        '{
            project: {
                name: .project.name,
                type: .project.type,
                template: .project.template,
                initialized: $now
            },
            stack: {
                detected: (.detection.stack // []),
                confirmed: true
            },
            workflow: .workflow,
            agents: {
                core: ["implementer", "code-reviewer"],
                domain: [],
                review: []
            },
            skills: {
                always: ["test-driven-development", "verification-before-completion", "git-expert"],
                domain: []
            },
            hooks: {
                active: ["session-start", "skill-activation-prompt"],
                disabled: []
            }
        }')

    # Add domain-specific agents and skills based on detection
    local stack
    stack=$(echo "$answers_json" | jq -r '.detection.stack // []')

    # Check for Next.js
    if echo "$stack" | jq -e 'index("next.js")' > /dev/null 2>&1; then
        settings=$(echo "$settings" | jq '.agents.domain += ["frontend-specialist"]')
        settings=$(echo "$settings" | jq '.skills.domain += ["frontend-design"]')
    fi

    # Check for Supabase
    if echo "$stack" | jq -e 'index("supabase")' > /dev/null 2>&1; then
        settings=$(echo "$settings" | jq '.agents.domain += ["supabase-specialist"]')
        settings=$(echo "$settings" | jq '.skills.domain += ["supabase-patterns"]')
    fi

    # Check for Python
    if echo "$stack" | jq -e 'index("python")' > /dev/null 2>&1; then
        settings=$(echo "$settings" | jq '.agents.domain += ["backend-engineer"]')
    fi

    # Check for Flutter
    if echo "$stack" | jq -e 'index("flutter")' > /dev/null 2>&1; then
        settings=$(echo "$settings" | jq '.agents.domain += ["flutter-expert"]')
    fi

    # Add review tools based on workflow
    local review_type
    review_type=$(echo "$answers_json" | jq -r '.workflow.review // "github"')
    if [[ "$review_type" == "coderabbit" || "$review_type" == "both" ]]; then
        settings=$(echo "$settings" | jq '.hooks.active += ["coderabbit-review"]')
    fi

    echo "$settings" | jq '.' > .claude/settings.json
    log_success "Created .claude/settings.json"
}

generate_claude_md() {
    local answers_json="$1"

    local project_name
    project_name=$(echo "$answers_json" | jq -r '.project.name')
    local project_type
    project_type=$(echo "$answers_json" | jq -r '.project.type')
    local stack
    stack=$(echo "$answers_json" | jq -r '.detection.stack | join(", ")' 2>/dev/null || echo "")
    local git_workflow
    git_workflow=$(echo "$answers_json" | jq -r '.workflow.git')
    local tdd_level
    tdd_level=$(echo "$answers_json" | jq -r '.workflow.tdd')
    local now
    now=$(date +"%Y-%m-%d")

    cat > CLAUDE.md << EOF
# ${project_name}

> Project Type: ${project_type}
> Initialized: ${now}

## Tech Stack

${stack:-"No specific stack detected"}

## Commands

| Command | Description |
|---------|-------------|
| \`/init\` | Re-run initialization |
| \`/plan\` | Create implementation plan |
| \`/implement\` | Start implementation |
| \`/review\` | Request code review |
| \`/test\` | Run tests |
| \`/commit\` | Create commit |

## Testing

**TDD Level**: ${tdd_level}

$(generate_tdd_rules "$tdd_level")

## Git Workflow

**Strategy**: ${git_workflow}

$(generate_git_rules "$git_workflow")

## Patterns

### Code Style
- Follow existing patterns in the codebase
- Use consistent naming conventions
- Document complex logic

### File Organization
- Group related files together
- Keep files focused and small
- Use clear, descriptive names

## Project-Specific Rules

<!-- Add project-specific rules below -->

---
*Generated by Jarvis on ${now}. Edit as needed.*
EOF

    log_success "Created CLAUDE.md"
}

generate_tdd_rules() {
    local tdd_level="$1"

    case "$tdd_level" in
        "iron-law")
            cat << 'EOF'
- **NEVER** write implementation code before tests
- All features MUST have tests before merge
- Test coverage must not decrease
- Red-Green-Refactor strictly enforced
EOF
            ;;
        "strong")
            cat << 'EOF'
- Tests required for all new features
- Can write exploratory code first, but tests before commit
- Coverage should improve or stay stable
- TDD encouraged but not strictly enforced
EOF
            ;;
        "flexible")
            cat << 'EOF'
- Tests encouraged for new features
- Critical paths should have tests
- No strict coverage requirements
EOF
            ;;
    esac
}

generate_git_rules() {
    local git_workflow="$1"

    case "$git_workflow" in
        "github-flow")
            cat << 'EOF'
- Create feature branches from main
- Open PR when ready for review
- Merge after approval
- Delete branch after merge
EOF
            ;;
        "gitflow")
            cat << 'EOF'
- Feature branches from develop
- Release branches for releases
- Hotfix branches for urgent fixes
- Never commit directly to main
EOF
            ;;
        "trunk")
            cat << 'EOF'
- Commit directly to main (with care)
- Use feature flags for WIP
- Keep main always deployable
- Small, frequent commits
EOF
            ;;
    esac
}

setup_hooks() {
    local answers_json="$1"

    # Create hook symlinks or copies from global
    local hooks_dir=".claude/hooks"

    # Create session-start hook
    cat > "${hooks_dir}/session-start.sh" << 'EOF'
#!/usr/bin/env bash
# Session Start Hook
# Runs at the beginning of each Claude session

echo "=== Jarvis Session Started ==="
echo "Project: $(basename "$(pwd)")"
echo "Time: $(date)"

# Check for pending tasks
if [[ -f ".claude/tasks/session-current.md" ]]; then
    echo ""
    echo "Current session tasks available."
fi
EOF
    chmod +x "${hooks_dir}/session-start.sh"

    log_success "Created hooks"
}

create_initial_session() {
    local now
    now=$(date +"%Y-%m-%d %H:%M")

    cat > .claude/tasks/session-current.md << EOF
# Current Session

Started: ${now}

## Goals

<!-- Define session goals here -->

## Tasks

- [ ] Review project structure
- [ ] Understand codebase
- [ ] Identify first task

## Notes

Session initialized by Jarvis.
EOF

    log_success "Created initial session file"
}

create_docs_structure() {
    local docs_level="$1"

    case "$docs_level" in
        "full")
            mkdir -p docs/{specs,plans,design,decisions,api}

            # Create placeholder files
            echo "# Specifications" > docs/specs/README.md
            echo "# Implementation Plans" > docs/plans/README.md
            echo "# Design Documents" > docs/design/README.md
            echo "# Architecture Decision Records" > docs/decisions/README.md
            echo "# API Documentation" > docs/api/README.md
            ;;
        "simple")
            mkdir -p docs
            # Don't create README in docs if it exists
            if [[ ! -f "docs/README.md" ]]; then
                echo "# Documentation" > docs/README.md
            fi
            ;;
    esac

    log_success "Created documentation structure"
}

# =============================================================================
# PHASE 5: VALIDATION & POST-INIT VERIFICATION
# =============================================================================

validate_setup() {
    log_step "Phase 5: Validation & Post-Init Verification"

    local errors=0
    local warnings=0

    echo ""
    echo -e "${BOLD}Structure Validation:${NC}"

    # Check .claude directory
    if [[ -d ".claude" ]]; then
        log_success ".claude/ directory exists"
    else
        log_error ".claude/ directory missing"
        ((errors++))
    fi

    # Check required subdirectories
    local required_dirs=("agents" "skills" "commands" "hooks" "rules" "tasks")
    for dir in "${required_dirs[@]}"; do
        if [[ -d ".claude/${dir}" ]]; then
            log_success ".claude/${dir}/ exists"
        else
            log_warning ".claude/${dir}/ missing"
            ((warnings++))
        fi
    done

    # Check settings.json
    if [[ -f ".claude/settings.json" ]]; then
        if jq empty .claude/settings.json 2>/dev/null; then
            log_success "settings.json is valid JSON"

            # Verify required fields
            local required_fields=("project.name" "project.type" "workflow.git" "workflow.tdd")
            for field in "${required_fields[@]}"; do
                if jq -e ".${field}" .claude/settings.json > /dev/null 2>&1; then
                    log_success "settings.json has ${field}"
                else
                    log_warning "settings.json missing ${field}"
                    ((warnings++))
                fi
            done
        else
            log_error "settings.json is invalid JSON"
            ((errors++))
        fi
    else
        log_error "settings.json missing"
        ((errors++))
    fi

    # Check CLAUDE.md
    if [[ -f "CLAUDE.md" ]]; then
        log_success "CLAUDE.md exists"

        # Check CLAUDE.md has content
        local claude_lines
        claude_lines=$(wc -l < "CLAUDE.md" | tr -d ' ')
        if [[ "$claude_lines" -gt 10 ]]; then
            log_success "CLAUDE.md has content (${claude_lines} lines)"
        else
            log_warning "CLAUDE.md may be too minimal (${claude_lines} lines)"
            ((warnings++))
        fi
    else
        log_error "CLAUDE.md missing"
        ((errors++))
    fi

    echo ""
    echo -e "${BOLD}Hook Verification:${NC}"

    # Check hooks exist and are executable
    if [[ -f ".claude/hooks/session-start.sh" ]]; then
        log_success "Session start hook exists"

        # Test hook execution (in dry run mode)
        if test_hook_execution ".claude/hooks/session-start.sh"; then
            log_success "Session start hook executes successfully"
        else
            log_warning "Session start hook may have issues"
            ((warnings++))
        fi
    else
        log_warning "Session start hook missing"
        ((warnings++))
    fi

    # Check global hooks connectivity (if Jarvis root exists)
    echo ""
    echo -e "${BOLD}Global Integration:${NC}"

    local jarvis_root="${JARVIS_ROOT:-$HOME/.jarvis}"
    if [[ -d "$jarvis_root" ]]; then
        log_success "Jarvis root found at $jarvis_root"

        # Verify global hooks exist
        if [[ -d "${jarvis_root}/global/hooks" ]]; then
            local hook_count
            hook_count=$(find "${jarvis_root}/global/hooks" -name "*.sh" -type f 2>/dev/null | wc -l | tr -d ' ')
            log_success "Global hooks directory has ${hook_count} hooks"
        else
            log_warning "Global hooks directory not found"
            ((warnings++))
        fi

        # Test a critical global hook
        if [[ -f "${jarvis_root}/global/hooks/session-start.sh" ]]; then
            if test_hook_execution "${jarvis_root}/global/hooks/session-start.sh"; then
                log_success "Global session-start hook executes successfully"
            else
                log_warning "Global session-start hook may have issues"
                ((warnings++))
            fi
        fi
    else
        log_info "Jarvis root not installed (standalone mode)"
    fi

    # Check tasks
    if [[ -f ".claude/tasks/session-current.md" ]]; then
        log_success "Initial session file exists"
    else
        log_warning "Initial session file missing"
        ((warnings++))
    fi

    echo ""
    echo -e "${BOLD}Component Integrity Check:${NC}"

    # Verify file permissions
    verify_permissions

    # Check for common issues
    check_common_issues

    # Summary
    echo ""
    echo -e "${BOLD}Verification Summary:${NC}"

    if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
        echo -e "${GREEN}✅ All checks passed${NC}"
        return 0
    elif [[ $errors -eq 0 ]]; then
        echo -e "${YELLOW}⚠️ Passed with ${warnings} warning(s)${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed with ${errors} error(s) and ${warnings} warning(s)${NC}"
        return 1
    fi
}

# Test if a hook script can execute without errors
test_hook_execution() {
    local hook_path="$1"

    # Check if file exists and is executable
    if [[ ! -f "$hook_path" ]]; then
        return 1
    fi

    # Make executable if not already
    if [[ ! -x "$hook_path" ]]; then
        chmod +x "$hook_path" 2>/dev/null || return 1
    fi

    # Test syntax by running bash -n (syntax check only)
    if ! bash -n "$hook_path" 2>/dev/null; then
        return 1
    fi

    # Dry run with /dev/null input and limited execution
    # Using timeout to prevent hanging scripts
    if command -v timeout &> /dev/null; then
        timeout 2s bash "$hook_path" < /dev/null > /dev/null 2>&1 || true
    else
        # macOS doesn't have timeout by default
        bash "$hook_path" < /dev/null > /dev/null 2>&1 &
        local pid=$!
        sleep 2
        kill -0 $pid 2>/dev/null && kill $pid 2>/dev/null
        wait $pid 2>/dev/null || true
    fi

    return 0
}

# Verify file permissions are correct
verify_permissions() {
    local perm_issues=0

    # Check all shell scripts are executable
    while IFS= read -r -d '' script; do
        if [[ ! -x "$script" ]]; then
            log_warning "Not executable: ${script}"
            chmod +x "$script" 2>/dev/null && log_info "Fixed permissions for ${script}"
            ((perm_issues++))
        fi
    done < <(find .claude -name "*.sh" -type f -print0 2>/dev/null)

    if [[ $perm_issues -eq 0 ]]; then
        log_success "All scripts have correct permissions"
    fi
}

# Check for common configuration issues
check_common_issues() {
    local issues=0

    # Check for duplicate entries in settings.json arrays
    if [[ -f ".claude/settings.json" ]]; then
        # Check for null/undefined values
        local null_values
        null_values=$(jq -r '.. | select(. == null)' .claude/settings.json 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$null_values" -gt 0 ]]; then
            log_warning "settings.json contains ${null_values} null value(s)"
            ((issues++))
        fi
    fi

    # Check CLAUDE.md for common issues
    if [[ -f "CLAUDE.md" ]]; then
        # Check for placeholder text
        if grep -q "TODO\|FIXME\|XXX\|PLACEHOLDER" "CLAUDE.md" 2>/dev/null; then
            log_info "CLAUDE.md contains placeholder text (review and update)"
        fi

        # Check for broken links (basic check)
        if grep -oE '\[.*\]\([^)]+\)' "CLAUDE.md" 2>/dev/null | grep -q "example.com\|localhost"; then
            log_warning "CLAUDE.md may contain example/placeholder links"
            ((issues++))
        fi
    fi

    if [[ $issues -eq 0 ]]; then
        log_success "No common issues detected"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    local template=""
    local refresh=false
    local claude_md_only=false
    local project_dir="."

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --template)
                template="$2"
                shift 2
                ;;
            --refresh)
                refresh=true
                shift
                ;;
            --claude-md-only)
                claude_md_only=true
                shift
                ;;
            --dir)
                project_dir="$2"
                shift 2
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                print_usage
                exit 2
                ;;
        esac
    done

    # Change to project directory
    cd "$project_dir" || exit 1

    print_banner

    # Check for jq dependency
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed"
        log_info "Install with: brew install jq"
        exit 1
    fi

    # Phase 1: Detection
    local detection_result
    detection_result=$(run_detection "$(pwd)")

    if [[ $? -ne 0 ]]; then
        log_error "Detection phase failed"
        exit 3
    fi

    # Handle claude-md-only mode
    if [[ "$claude_md_only" == "true" ]]; then
        log_info "Generating CLAUDE.md only"
        local answers
        answers=$(generate_default_answers "$detection_result")
        generate_claude_md "$answers"
        exit 0
    fi

    # Phase 2: Interview
    local skip_interview="false"
    if [[ -n "$template" ]]; then
        skip_interview="true"
        detection_result=$(echo "$detection_result" | jq --arg t "$template" '.suggested_template = $t')
    fi

    local answers
    answers=$(run_interview "$detection_result" "$skip_interview")

    # Phase 3: Template Selection
    local selected_template
    selected_template=$(select_template "$answers")

    # Phase 4: Generation
    generate_structure "$answers" "$selected_template"

    # Phase 5: Validation
    if validate_setup; then
        echo ""
        log_success "Jarvis initialization complete!"
        echo ""
        echo -e "${BOLD}Next steps:${NC}"
        echo "  1. Review CLAUDE.md and customize as needed"
        echo "  2. Review .claude/settings.json"
        echo "  3. Start a new Claude session"
        echo ""
    else
        log_error "Initialization completed with errors"
        exit 1
    fi
}

print_usage() {
    cat << EOF
Usage: jarvis init [OPTIONS]

Initialize Jarvis in a project directory.

Options:
  --template NAME    Use specific template (skip interview)
  --refresh          Re-initialize preserving customizations
  --claude-md-only   Generate missing CLAUDE.md files only
  --dir PATH         Project directory (default: current)
  -h, --help         Show this help message

Templates:
  web-fullstack     Next.js, Supabase, Tailwind
  mobile-flutter    Flutter cross-platform
  mobile-ios        Swift iOS app
  backend-api       Node/Python backend
  minimal           Basic setup for any project

Examples:
  jarvis init                           # Interactive initialization
  jarvis init --template web-fullstack  # Quick init with template
  jarvis init --refresh                 # Update existing setup
EOF
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
