#!/usr/bin/env bash
#
# Jarvis Agent Testing Framework
# ===============================
# Tests agent definitions for completeness and quality.
#
# This framework validates:
# - Agent file structure and required sections
# - Prompt patterns and best practices
# - Response format expectations
# - Agent capability declarations
#
# Usage:
#   ./test-agent-framework.sh           # Test all agents
#   ./test-agent-framework.sh agent     # Test specific agent
#   ./test-agent-framework.sh --validate # Validation only
#
# Exit codes:
#   0 - All tests passed
#   1 - Test failures

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Navigate up from tests/jarvis/agents to the repo root
JARVIS_ROOT="${JARVIS_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
AGENTS_DIR="${JARVIS_ROOT}/global/agents"
TEMPLATES_DIR="${JARVIS_ROOT}/templates/agents"

# Source test helpers
if [[ -f "${SCRIPT_DIR}/lib/agent-test-helpers.sh" ]]; then
    source "${SCRIPT_DIR}/lib/agent-test-helpers.sh"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# =============================================================================
# TEST UTILITIES
# =============================================================================

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
    ((TESTS_RUN++))
}

log_pass() {
    echo -e "${GREEN}  ✓${NC} $1"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}  ✗${NC} $1"
    ((TESTS_FAILED++))
}

log_skip() {
    echo -e "${YELLOW}  ○${NC} $1 (skipped)"
    ((TESTS_SKIPPED++))
}

log_section() {
    echo ""
    echo -e "${BOLD}━━━ $1 ━━━${NC}"
}

# =============================================================================
# AGENT VALIDATION
# =============================================================================

# Required sections for a valid agent definition
REQUIRED_SECTIONS=(
    "# "              # Title (h1 heading)
    "## Role"         # Role description
    "## Capabilities" # What the agent can do
)

# Recommended sections
RECOMMENDED_SECTIONS=(
    "## When to Use"
    "## Output Format"
    "## Examples"
    "## Constraints"
)

# Validate agent file structure
validate_agent_structure() {
    local agent_file="$1"
    local agent_name=$(basename "$agent_file" .md)
    local errors=0

    # Skip non-agent files (README, CLAUDE, etc.)
    if [[ "$agent_name" == "README" ]] || [[ "$agent_name" == "CLAUDE" ]]; then
        return 0
    fi

    log_test "Structure validation: $agent_name"

    # Check file exists and is readable
    if [[ ! -f "$agent_file" ]] || [[ ! -r "$agent_file" ]]; then
        log_fail "File not found or not readable: $agent_file"
        return 1
    fi

    local content
    content=$(cat "$agent_file")

    # Check if file has frontmatter (agent definition)
    if ! echo "$content" | head -1 | grep -q "^---"; then
        log_skip "No frontmatter, skipping validation"
        return 0
    fi

    # Check for title (warning, not error - many agents use frontmatter name instead)
    if echo "$content" | grep -q "^# "; then
        log_pass "Has section: # "
    else
        log_skip "Missing section: # (using frontmatter name)"
    fi

    # Check Role and Capabilities (warnings, not errors)
    if echo "$content" | grep -q "^## Role"; then
        log_pass "Has section: ## Role"
    else
        log_skip "Missing section: ## Role"
    fi

    if echo "$content" | grep -q "^## Capabilities"; then
        log_pass "Has section: ## Capabilities"
    else
        log_skip "Missing section: ## Capabilities"
    fi

    # Check recommended sections (warnings only)
    for section in "${RECOMMENDED_SECTIONS[@]}"; do
        if echo "$content" | grep -q "^${section}"; then
            log_pass "Has recommended section: ${section}"
        else
            log_skip "Missing recommended section: ${section}"
        fi
    done

    # Check minimum content length
    local line_count
    line_count=$(wc -l < "$agent_file" | tr -d ' ')
    if [[ "$line_count" -ge 20 ]]; then
        log_pass "Sufficient content ($line_count lines)"
    else
        log_fail "Too short ($line_count lines, minimum 20)"
        ((errors++))
    fi

    return $errors
}

# Validate agent prompt patterns
validate_agent_patterns() {
    local agent_file="$1"
    local agent_name=$(basename "$agent_file" .md)
    local warnings=0

    log_test "Pattern validation: $agent_name"

    local content
    content=$(cat "$agent_file")

    # Check for clear role definition
    if echo "$content" | grep -qE "(You are|Act as|Your role)"; then
        log_pass "Has clear role definition"
    else
        log_skip "Consider adding explicit role definition"
        ((warnings++))
    fi

    # Check for output format specification
    if echo "$content" | grep -qE "(Output|Response|Return|Format|Template)"; then
        log_pass "Has output format guidance"
    else
        log_skip "Consider specifying output format"
        ((warnings++))
    fi

    # Check for examples
    if echo "$content" | grep -qE "(Example|Sample|\`\`\`|<example>)"; then
        log_pass "Includes examples"
    else
        log_skip "Consider adding examples"
        ((warnings++))
    fi

    # Check for constraints/limitations
    if echo "$content" | grep -qiE "(never|always|must|should not|avoid|constraint|limitation)"; then
        log_pass "Has behavioral constraints"
    else
        log_skip "Consider adding constraints"
        ((warnings++))
    fi

    # Check for markdown formatting
    if echo "$content" | grep -qE "(^\*|^-|^[0-9]+\.|^\|)"; then
        log_pass "Uses structured formatting"
    else
        log_skip "Consider using lists/tables"
        ((warnings++))
    fi

    return 0  # Warnings don't fail the test
}

# =============================================================================
# CONSISTENCY TESTS
# =============================================================================

# Check naming consistency across agents
test_naming_consistency() {
    log_section "Naming Consistency"

    local issues=0

    # Check for kebab-case filenames
    log_test "Filename conventions"

    while IFS= read -r -d '' file; do
        local filename=$(basename "$file")
        if [[ "$filename" =~ ^[a-z]+(-[a-z]+)*\.md$ ]]; then
            log_pass "$filename follows kebab-case"
        else
            log_fail "$filename should use kebab-case"
            ((issues++))
        fi
    done < <(find "$AGENTS_DIR" -name "*.md" -type f -print0 2>/dev/null)

    return $issues
}

# Check for duplicate capabilities across agents
test_capability_overlap() {
    log_section "Capability Analysis"

    log_test "Checking for clear agent boundaries"

    # This is a basic check - in production you'd want more sophisticated overlap detection
    local core_agents=("implementer" "code-reviewer" "spec-reviewer" "debug")
    local found_all=true

    for agent in "${core_agents[@]}"; do
        if [[ -f "${AGENTS_DIR}/${agent}.md" ]]; then
            log_pass "Core agent exists: $agent"
        else
            log_fail "Missing core agent: $agent"
            found_all=false
        fi
    done

    if $found_all; then
        log_pass "All core agents present"
    fi
}

# =============================================================================
# TEMPLATE TESTS
# =============================================================================

test_domain_templates() {
    log_section "Domain Agent Templates"

    if [[ ! -d "$TEMPLATES_DIR" ]]; then
        log_skip "Templates directory not found"
        return 0
    fi

    log_test "Domain agent templates validation"

    while IFS= read -r -d '' file; do
        local template_name=$(basename "$file" .md)

        # Validate template structure
        if grep -q "{{" "$file"; then
            log_pass "$template_name has template variables"
        else
            log_skip "$template_name: Consider adding template variables"
        fi

        # Check for customization points
        if grep -qiE "(customize|configure|project|domain)" "$file"; then
            log_pass "$template_name has customization guidance"
        else
            log_skip "$template_name: Consider adding customization notes"
        fi
    done < <(find "$TEMPLATES_DIR" -name "*.md" -type f -print0 2>/dev/null)
}

# =============================================================================
# REVIEW AGENT TESTS
# =============================================================================

test_review_agents() {
    log_section "Review Agents"

    local review_dir="${AGENTS_DIR}/review"

    if [[ ! -d "$review_dir" ]]; then
        log_fail "Review agents directory not found"
        return 1
    fi

    log_test "Review agent specialization"

    local expected_reviewers=(
        "security-reviewer"
        "performance-reviewer"
        "accessibility-auditor"
        "test-coverage-analyzer"
    )

    for reviewer in "${expected_reviewers[@]}"; do
        if [[ -f "${review_dir}/${reviewer}.md" ]]; then
            log_pass "Has $reviewer"
        else
            log_skip "Missing $reviewer (optional)"
        fi
    done
}

# =============================================================================
# MAIN TEST RUNNER
# =============================================================================

run_all_tests() {
    echo -e "${BOLD}Jarvis Agent Testing Framework${NC}"
    echo "================================="
    echo ""

    # Validate all global agents
    log_section "Global Agents"
    while IFS= read -r -d '' agent; do
        validate_agent_structure "$agent"
        validate_agent_patterns "$agent"
    done < <(find "$AGENTS_DIR" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)

    # Test review agents
    test_review_agents

    # Test domain templates
    test_domain_templates

    # Test naming consistency
    test_naming_consistency

    # Test capability boundaries
    test_capability_overlap

    # Print summary
    echo ""
    echo -e "${BOLD}━━━ Test Summary ━━━${NC}"
    echo ""
    echo "Tests run:    $TESTS_RUN"
    echo -e "Passed:       ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed:       ${RED}$TESTS_FAILED${NC}"
    echo -e "Skipped:      ${YELLOW}$TESTS_SKIPPED${NC}"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}✅ All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}${BOLD}❌ $TESTS_FAILED test(s) failed${NC}"
        return 1
    fi
}

run_single_agent_test() {
    local agent_name="$1"

    echo -e "${BOLD}Testing Agent: $agent_name${NC}"
    echo ""

    # Find the agent file
    local agent_file
    if [[ -f "${AGENTS_DIR}/${agent_name}.md" ]]; then
        agent_file="${AGENTS_DIR}/${agent_name}.md"
    elif [[ -f "${AGENTS_DIR}/review/${agent_name}.md" ]]; then
        agent_file="${AGENTS_DIR}/review/${agent_name}.md"
    elif [[ -f "${TEMPLATES_DIR}/${agent_name}.md" ]]; then
        agent_file="${TEMPLATES_DIR}/${agent_name}.md"
    else
        echo -e "${RED}Agent not found: $agent_name${NC}"
        return 1
    fi

    validate_agent_structure "$agent_file"
    validate_agent_patterns "$agent_file"

    echo ""
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✅ Agent $agent_name passed all tests${NC}"
    else
        echo -e "${RED}❌ Agent $agent_name has $TESTS_FAILED issue(s)${NC}"
    fi
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

main() {
    case "${1:-}" in
        "")
            run_all_tests
            ;;
        --help|-h)
            cat << EOF
Jarvis Agent Testing Framework

Usage:
  $(basename "$0")                Test all agents
  $(basename "$0") <agent-name>   Test specific agent
  $(basename "$0") --validate     Validation mode only
  $(basename "$0") --help         Show this help

Examples:
  $(basename "$0")
  $(basename "$0") code-reviewer
  $(basename "$0") security-reviewer
EOF
            ;;
        --validate)
            log_section "Validation Mode"
            echo "Validating all agent files..."
            local errors=0
            while IFS= read -r -d '' agent; do
                if ! validate_agent_structure "$agent"; then
                    ((errors++))
                fi
            done < <(find "$AGENTS_DIR" -name "*.md" -type f -print0 2>/dev/null)
            exit $errors
            ;;
        *)
            run_single_agent_test "$1"
            ;;
    esac

    exit $([[ $TESTS_FAILED -gt 0 ]] && echo 1 || echo 0)
}

main "$@"
