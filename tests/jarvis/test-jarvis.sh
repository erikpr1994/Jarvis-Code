#!/usr/bin/env bash
# Jarvis Testing Framework - Main Test Runner
# Usage: ./test-jarvis.sh [skills|hooks|all] [component-name]
#
# Examples:
#   ./test-jarvis.sh                    # Run all tests
#   ./test-jarvis.sh skills             # Test all skills
#   ./test-jarvis.sh hooks              # Test all hooks
#   ./test-jarvis.sh skill:git-expert   # Test specific skill
#   ./test-jarvis.sh hook:session-start # Test specific hook
#   ./test-jarvis.sh --changed          # Test only changed components

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JARVIS_ROOT="$(cd "${SCRIPT_DIR}/../../" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"
SKILLS_TEST_DIR="${SCRIPT_DIR}/skills"
HOOKS_TEST_DIR="${SCRIPT_DIR}/hooks"
INSTALL_TEST_DIR="${SCRIPT_DIR}/install"
INTEGRATION_TEST_DIR="${SCRIPT_DIR}/integration"
SCENARIOS_DIR="${SCRIPT_DIR}/scenarios"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Source test helpers
if [[ -f "${LIB_DIR}/test-helpers.sh" ]]; then
    source "${LIB_DIR}/test-helpers.sh"
else
    echo -e "${RED}ERROR: test-helpers.sh not found at ${LIB_DIR}/test-helpers.sh${NC}"
    exit 1
fi

# ============================================================================
# OUTPUT FUNCTIONS
# ============================================================================

print_header() {
    echo -e "\n${BLUE}============================================${NC}"
    echo -e "${BLUE}  Jarvis Testing Framework${NC}"
    echo -e "${BLUE}============================================${NC}\n"
}

print_section() {
    local title="$1"
    echo -e "\n${YELLOW}--- $title ---${NC}\n"
}

print_test_result() {
    local name="$1"
    local status="$2"
    local details="${3:-}"

    case "$status" in
        "pass")
            echo -e "  ${GREEN}[PASS]${NC} $name"
            ;;
        "fail")
            echo -e "  ${RED}[FAIL]${NC} $name"
            if [[ -n "$details" ]]; then
                echo -e "         ${RED}$details${NC}"
            fi
            ;;
        "skip")
            echo -e "  ${YELLOW}[SKIP]${NC} $name"
            if [[ -n "$details" ]]; then
                echo -e "         ${YELLOW}$details${NC}"
            fi
            ;;
    esac
}

print_summary() {
    echo -e "\n${BLUE}============================================${NC}"
    echo -e "${BLUE}  Test Summary${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo -e "  Total:   $TESTS_RUN"
    echo -e "  ${GREEN}Passed:  $TESTS_PASSED${NC}"
    echo -e "  ${RED}Failed:  $TESTS_FAILED${NC}"
    echo -e "  ${YELLOW}Skipped: $TESTS_SKIPPED${NC}"
    echo -e "${BLUE}============================================${NC}\n"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}Some tests failed. See output above for details.${NC}"
        return 1
    else
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    fi
}

# ============================================================================
# TEST DISCOVERY & EXECUTION
# ============================================================================

# Find all test scripts in a directory
discover_tests() {
    local dir="$1"
    local pattern="${2:-test-*.sh}"

    if [[ -d "$dir" ]]; then
        find "$dir" -maxdepth 1 -name "$pattern" -type f 2>/dev/null | sort
    fi
}

# Run a single test file
run_test_file() {
    local test_file="$1"
    local test_name
    test_name=$(basename "$test_file" .sh)

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ ! -x "$test_file" ]]; then
        chmod +x "$test_file" 2>/dev/null || true
    fi

    # Create isolated test environment
    local test_output
    local test_exit_code

    # Run test in subshell to isolate environment
    test_output=$(
        export JARVIS_TEST_MODE=1
        export JARVIS_ROOT="$JARVIS_ROOT"
        export JARVIS_LOG_LEVEL=3  # ERROR only during tests
        bash "$test_file" 2>&1
    ) && test_exit_code=0 || test_exit_code=$?

    if [[ $test_exit_code -eq 0 ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        print_test_result "$test_name" "pass"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        print_test_result "$test_name" "fail" "$test_output"
    fi
}

# Run all skill tests
test_skills() {
    local specific_skill="${1:-}"

    print_section "Skill Tests"

    if [[ -n "$specific_skill" ]]; then
        # Test specific skill
        local test_file="${SKILLS_TEST_DIR}/test-${specific_skill}.sh"
        if [[ -f "$test_file" ]]; then
            run_test_file "$test_file"
        else
            # Check for scenario-based test
            local scenario_dir="${SCENARIOS_DIR}/${specific_skill}"
            if [[ -d "$scenario_dir" ]]; then
                run_scenario_test "$specific_skill"
            else
                TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
                print_test_result "$specific_skill" "skip" "No test file or scenario found"
            fi
        fi
    else
        # Run all skill tests
        local test_files
        test_files=$(discover_tests "$SKILLS_TEST_DIR")

        if [[ -z "$test_files" ]]; then
            echo "  No skill tests found in ${SKILLS_TEST_DIR}"
            return 0
        fi

        for test_file in $test_files; do
            run_test_file "$test_file"
        done

        # Also run scenario-based tests
        if [[ -d "$SCENARIOS_DIR" ]]; then
            for scenario_dir in "$SCENARIOS_DIR"/*/; do
                if [[ -d "$scenario_dir" ]]; then
                    local skill_name
                    skill_name=$(basename "$scenario_dir")
                    run_scenario_test "$skill_name"
                fi
            done
        fi
    fi
}

# Run all hook tests
test_hooks() {
    local specific_hook="${1:-}"

    print_section "Hook Tests"

    if [[ -n "$specific_hook" ]]; then
        # Test specific hook
        local test_file="${HOOKS_TEST_DIR}/test-${specific_hook}.sh"
        if [[ -f "$test_file" ]]; then
            run_test_file "$test_file"
        else
            TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
            print_test_result "$specific_hook" "skip" "No test file found"
        fi
    else
        # Run all hook tests
        local test_files
        test_files=$(discover_tests "$HOOKS_TEST_DIR")

        if [[ -z "$test_files" ]]; then
            echo "  No hook tests found in ${HOOKS_TEST_DIR}"
            return 0
        fi

        for test_file in $test_files; do
            run_test_file "$test_file"
        done
    fi
}

# Run all install tests
test_install() {
    print_section "Install Tests"

    local test_files
    test_files=$(discover_tests "$INSTALL_TEST_DIR")

    if [[ -z "$test_files" ]]; then
        echo "  No install tests found in ${INSTALL_TEST_DIR}"
        return 0
    fi

    for test_file in $test_files; do
        run_test_file "$test_file"
    done
}

# Run all integration tests
test_integration() {
    print_section "Integration Tests"

    local test_files
    test_files=$(discover_tests "$INTEGRATION_TEST_DIR")

    if [[ -z "$test_files" ]]; then
        echo "  No integration tests found in ${INTEGRATION_TEST_DIR}"
        return 0
    fi

    for test_file in $test_files; do
        run_test_file "$test_file"
    done
}

# Run scenario-based test for a skill
run_scenario_test() {
    local skill_name="$1"
    local scenario_dir="${SCENARIOS_DIR}/${skill_name}"

    if [[ ! -d "$scenario_dir" ]]; then
        return 0
    fi

    TESTS_RUN=$((TESTS_RUN + 1))

    local baseline_file="${scenario_dir}/baseline.md"
    local with_skill_file="${scenario_dir}/with-skill.md"
    local prompts_dir="${scenario_dir}/prompts"

    # Check required files exist
    if [[ ! -f "$baseline_file" ]] || [[ ! -f "$with_skill_file" ]]; then
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
        print_test_result "scenario:${skill_name}" "skip" "Missing baseline.md or with-skill.md"
        return 0
    fi

    # Run scenario validation
    local scenario_valid=true
    local error_msg=""

    # Check prompts directory has at least one trigger
    if [[ -d "$prompts_dir" ]]; then
        local trigger_count
        trigger_count=$(find "$prompts_dir" -name "trigger-*.txt" 2>/dev/null | wc -l | tr -d ' ')
        if [[ $trigger_count -eq 0 ]]; then
            scenario_valid=false
            error_msg="No trigger prompts found in prompts/"
        fi
    else
        scenario_valid=false
        error_msg="No prompts/ directory"
    fi

    if $scenario_valid; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        print_test_result "scenario:${skill_name}" "pass"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        print_test_result "scenario:${skill_name}" "fail" "$error_msg"
    fi
}

# Test only changed components (based on git diff)
test_changed() {
    local changed_files="${1:-}"

    if [[ -z "$changed_files" ]]; then
        # Get changed files from git
        changed_files=$(git diff --name-only HEAD~1 2>/dev/null | grep -E "^(\.claude/|global/)" || echo "")
    fi

    if [[ -z "$changed_files" ]]; then
        echo "No Jarvis components changed."
        return 0
    fi

    print_section "Testing Changed Components"

    for file in $changed_files; do
        # Determine component type from path
        if [[ "$file" == *"/skills/"* ]]; then
            local skill_name
            skill_name=$(echo "$file" | grep -oP 'skills/\K[^/]+' || echo "")
            if [[ -n "$skill_name" && "$skill_name" != "skill-rules.json" ]]; then
                test_skills "$skill_name"
            fi
        elif [[ "$file" == *"/hooks/"* ]]; then
            local hook_name
            hook_name=$(basename "$file" .sh)
            if [[ "$hook_name" != "lib" && "$hook_name" != "hooks" ]]; then
                test_hooks "$hook_name"
            fi
        fi
    done
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    local mode="${1:-all}"
    local component="${2:-}"

    print_header

    case "$mode" in
        "skills")
            test_skills "$component"
            ;;
        "hooks")
            test_hooks "$component"
            ;;
        "install")
            test_install
            ;;
        "integration")
            test_integration
            ;;
        "skill:"*)
            local skill_name="${mode#skill:}"
            test_skills "$skill_name"
            ;;
        "hook:"*)
            local hook_name="${mode#hook:}"
            test_hooks "$hook_name"
            ;;
        "--changed"|"changed")
            test_changed "$component"
            ;;
        "all"|*)
            test_install
            test_skills
            test_hooks
            test_integration
            ;;
    esac

    print_summary
}

# Run main function with all arguments
main "$@"
