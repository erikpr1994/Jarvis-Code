#!/usr/bin/env bash
#
# Jarvis Verification Pipeline
# =============================
# Multi-stage verification pipeline with configurable depth.
#
# Usage:
#   ./pipeline.sh [level] [options]
#
# Levels:
#   quick     - Lint, types, formatting (default)
#   standard  - + Unit tests
#   full      - + Integration, E2E, build, review agents
#   release   - + Performance, security audit, bundle analysis
#
# Options:
#   --path PATH      - Check specific path only
#   --parallel       - Run checks in parallel where possible
#   --json           - Output results as JSON
#   --fail-fast      - Stop on first failure
#   --no-agents      - Skip agent reviews
#   --timeout MIN    - Timeout in minutes (default: 10)
#
# Exit Codes:
#   0 - All checks passed
#   1 - Required check failed
#   2 - Warning (optional check failed)
#   3 - Timeout
#   4 - Configuration error

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JARVIS_ROOT="${JARVIS_ROOT:-$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Default settings
LEVEL="${1:-quick}"
TARGET_PATH="."
PARALLEL=false
JSON_OUTPUT=false
FAIL_FAST=false
SKIP_AGENTS=false
TIMEOUT_MINUTES=10
STARTED_AT=$(date +%s)

# Results tracking (Bash 3.2 compatible - using indexed arrays)
CHECK_NAMES=()
CHECK_STATUSES=()
CHECK_TIMES_LIST=()
TOTAL_WARNINGS=0
TOTAL_ERRORS=0

# Helper to record check result
record_check() {
    local name="$1"
    local status="$2"
    local time_ms="${3:-0}"
    CHECK_NAMES+=("$name")
    CHECK_STATUSES+=("$status")
    CHECK_TIMES_LIST+=("$time_ms")
}

# Helper to get check count
get_check_count() {
    echo "${#CHECK_NAMES[@]}"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_phase() {
    echo ""
    echo -e "${CYAN}${BOLD}━━━ $1 ━━━${NC}"
}

log_check() {
    echo -e "${BLUE}▸${NC} $1..."
}

log_pass() {
    local check_name="$1"
    local time_ms="$2"
    echo -e "${GREEN}✓${NC} $check_name ${DIM}(${time_ms}ms)${NC}"
    record_check "$check_name" "pass" "$time_ms"
}

log_fail() {
    local check_name="$1"
    local message="${2:-}"
    echo -e "${RED}✗${NC} $check_name"
    [[ -n "$message" ]] && echo -e "  ${DIM}$message${NC}"
    record_check "$check_name" "fail" "0"
    TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
}

log_warn() {
    local check_name="$1"
    local message="${2:-}"
    echo -e "${YELLOW}⚠${NC} $check_name"
    [[ -n "$message" ]] && echo -e "  ${DIM}$message${NC}"
    record_check "$check_name" "warn" "0"
    TOTAL_WARNINGS=$((TOTAL_WARNINGS + 1))
}

log_skip() {
    local check_name="$1"
    local reason="${2:-Not applicable}"
    echo -e "${DIM}○${NC} $check_name ${DIM}(skipped: $reason)${NC}"
    record_check "$check_name" "skip" "0"
}

measure_time() {
    local start_ms=$(($(date +%s%N)/1000000))
    "$@"
    local exit_code=$?
    local end_ms=$(($(date +%s%N)/1000000))
    echo $((end_ms - start_ms))
    return $exit_code
}

detect_package_manager() {
    if [[ -f "pnpm-lock.yaml" ]]; then
        echo "pnpm"
    elif [[ -f "yarn.lock" ]]; then
        echo "yarn"
    elif [[ -f "bun.lockb" ]]; then
        echo "bun"
    else
        echo "npm"
    fi
}

has_script() {
    local script="$1"
    if [[ -f "package.json" ]]; then
        jq -e ".scripts[\"$script\"]" package.json > /dev/null 2>&1
    else
        return 1
    fi
}

run_script() {
    local script="$1"
    local pm
    pm=$(detect_package_manager)
    $pm run "$script" 2>&1
}

# =============================================================================
# PHASE 1: QUICK CHECKS
# =============================================================================

run_quick_checks() {
    log_phase "Phase 1: Quick Checks"

    local phase_errors=0

    # TypeScript compilation
    if [[ -f "tsconfig.json" ]]; then
        log_check "TypeScript compilation"
        local start_time=$(($(date +%s%N)/1000000))

        if npx tsc --noEmit > /tmp/tsc-output.txt 2>&1; then
            local end_time=$(($(date +%s%N)/1000000))
            log_pass "TypeScript" "$((end_time - start_time))"
        else
            log_fail "TypeScript" "$(head -5 /tmp/tsc-output.txt)"
            $1=$(($1 + 1))
            [[ "$FAIL_FAST" == "true" ]] && return 1
        fi
    else
        log_skip "TypeScript" "No tsconfig.json"
    fi

    # Linting
    log_check "Linting"
    local start_time=$(($(date +%s%N)/1000000))

    if [[ -f "biome.json" ]]; then
        if npx @biomejs/biome check "$TARGET_PATH" > /tmp/lint-output.txt 2>&1; then
            local end_time=$(($(date +%s%N)/1000000))
            log_pass "Biome lint" "$((end_time - start_time))"
        else
            local warn_count=$(grep -c "warning" /tmp/lint-output.txt 2>/dev/null || echo "0")
            local err_count=$(grep -c "error" /tmp/lint-output.txt 2>/dev/null || echo "0")
            if [[ "$err_count" -gt 0 ]]; then
                log_fail "Biome lint" "$err_count errors, $warn_count warnings"
                $1=$(($1 + 1))
            else
                log_warn "Biome lint" "$warn_count warnings"
            fi
        fi
    elif has_script "lint"; then
        if run_script "lint" > /tmp/lint-output.txt 2>&1; then
            local end_time=$(($(date +%s%N)/1000000))
            log_pass "ESLint" "$((end_time - start_time))"
        else
            log_fail "ESLint" "$(tail -3 /tmp/lint-output.txt)"
            $1=$(($1 + 1))
        fi
    else
        log_skip "Linting" "No lint configuration"
    fi

    # Formatting
    log_check "Formatting"
    local start_time=$(($(date +%s%N)/1000000))

    if [[ -f ".prettierrc" ]] || [[ -f ".prettierrc.json" ]] || [[ -f "prettier.config.js" ]]; then
        if npx prettier --check "$TARGET_PATH" > /tmp/format-output.txt 2>&1; then
            local end_time=$(($(date +%s%N)/1000000))
            log_pass "Prettier" "$((end_time - start_time))"
        else
            local unformatted=$(grep -c "would change" /tmp/format-output.txt 2>/dev/null || echo "some")
            log_warn "Prettier" "$unformatted files need formatting"
        fi
    elif [[ -f "biome.json" ]]; then
        if npx @biomejs/biome format --check "$TARGET_PATH" > /tmp/format-output.txt 2>&1; then
            local end_time=$(($(date +%s%N)/1000000))
            log_pass "Biome format" "$((end_time - start_time))"
        else
            log_warn "Biome format" "Files need formatting"
        fi
    else
        log_skip "Formatting" "No formatter configured"
    fi

    return $phase_errors
}

# =============================================================================
# PHASE 2: STANDARD CHECKS
# =============================================================================

run_standard_checks() {
    log_phase "Phase 2: Standard Checks (Tests)"

    local phase_errors=0

    # Unit tests
    log_check "Unit tests"
    local start_time=$(($(date +%s%N)/1000000))

    if has_script "test"; then
        if run_script "test" > /tmp/test-output.txt 2>&1; then
            local end_time=$(($(date +%s%N)/1000000))

            # Try to extract test count
            local test_count=$(grep -oE "[0-9]+ passed" /tmp/test-output.txt | head -1 || echo "")
            if [[ -n "$test_count" ]]; then
                log_pass "Unit tests ($test_count)" "$((end_time - start_time))"
            else
                log_pass "Unit tests" "$((end_time - start_time))"
            fi
        else
            local failed=$(grep -oE "[0-9]+ failed" /tmp/test-output.txt | head -1 || echo "some")
            log_fail "Unit tests" "$failed tests failed"
            $1=$(($1 + 1))
            [[ "$FAIL_FAST" == "true" ]] && return 1
        fi
    elif [[ -f "vitest.config.ts" ]] || [[ -f "vitest.config.js" ]]; then
        if npx vitest run > /tmp/test-output.txt 2>&1; then
            local end_time=$(($(date +%s%N)/1000000))
            log_pass "Vitest" "$((end_time - start_time))"
        else
            log_fail "Vitest" "Tests failed"
            $1=$(($1 + 1))
        fi
    elif [[ -f "jest.config.js" ]] || [[ -f "jest.config.ts" ]]; then
        if npx jest --passWithNoTests > /tmp/test-output.txt 2>&1; then
            local end_time=$(($(date +%s%N)/1000000))
            log_pass "Jest" "$((end_time - start_time))"
        else
            log_fail "Jest" "Tests failed"
            $1=$(($1 + 1))
        fi
    else
        log_skip "Unit tests" "No test runner configured"
    fi

    return $phase_errors
}

# =============================================================================
# PHASE 3: FULL CHECKS
# =============================================================================

run_full_checks() {
    log_phase "Phase 3: Full Checks (Integration & Build)"

    local phase_errors=0

    # Integration tests
    log_check "Integration tests"
    if has_script "test:integration"; then
        local start_time=$(($(date +%s%N)/1000000))
        if run_script "test:integration" > /tmp/integration-output.txt 2>&1; then
            local end_time=$(($(date +%s%N)/1000000))
            log_pass "Integration tests" "$((end_time - start_time))"
        else
            log_fail "Integration tests" "Some tests failed"
            $1=$(($1 + 1))
            [[ "$FAIL_FAST" == "true" ]] && return 1
        fi
    else
        log_skip "Integration tests" "No test:integration script"
    fi

    # E2E tests
    log_check "E2E tests"
    if has_script "test:e2e"; then
        local start_time=$(($(date +%s%N)/1000000))
        if run_script "test:e2e" > /tmp/e2e-output.txt 2>&1; then
            local end_time=$(($(date +%s%N)/1000000))
            log_pass "E2E tests" "$((end_time - start_time))"
        else
            log_fail "E2E tests" "Some tests failed"
            $1=$(($1 + 1))
        fi
    elif [[ -f "playwright.config.ts" ]]; then
        local start_time=$(($(date +%s%N)/1000000))
        if npx playwright test > /tmp/e2e-output.txt 2>&1; then
            local end_time=$(($(date +%s%N)/1000000))
            log_pass "Playwright E2E" "$((end_time - start_time))"
        else
            log_fail "Playwright E2E" "Tests failed"
            $1=$(($1 + 1))
        fi
    else
        log_skip "E2E tests" "No E2E configuration"
    fi

    # Build verification
    log_check "Build verification"
    if has_script "build"; then
        local start_time=$(($(date +%s%N)/1000000))
        if run_script "build" > /tmp/build-output.txt 2>&1; then
            local end_time=$(($(date +%s%N)/1000000))
            log_pass "Build" "$((end_time - start_time))"
        else
            log_fail "Build" "Build failed"
            $1=$(($1 + 1))
        fi
    else
        log_skip "Build" "No build script"
    fi

    return $phase_errors
}

# =============================================================================
# PHASE 4: RELEASE CHECKS
# =============================================================================

run_release_checks() {
    log_phase "Phase 4: Release Checks (Security & Performance)"

    local phase_errors=0

    # Security audit
    log_check "Security audit"
    local start_time=$(($(date +%s%N)/1000000))

    if [[ -f "package.json" ]]; then
        local pm=$(detect_package_manager)
        if $pm audit --audit-level=high > /tmp/audit-output.txt 2>&1; then
            local end_time=$(($(date +%s%N)/1000000))
            log_pass "Security audit" "$((end_time - start_time))"
        else
            local vuln_count=$(grep -oE "[0-9]+ vulnerabilities" /tmp/audit-output.txt | head -1 || echo "vulnerabilities found")
            log_warn "Security audit" "$vuln_count"
        fi
    else
        log_skip "Security audit" "No package.json"
    fi

    # Bundle analysis
    log_check "Bundle analysis"
    if has_script "analyze"; then
        local start_time=$(($(date +%s%N)/1000000))
        if timeout 60 bash -c "$(declare -f run_script); run_script analyze" > /tmp/analyze-output.txt 2>&1; then
            local end_time=$(($(date +%s%N)/1000000))
            log_pass "Bundle analysis" "$((end_time - start_time))"
        else
            log_warn "Bundle analysis" "Could not complete analysis"
        fi
    else
        log_skip "Bundle analysis" "No analyze script"
    fi

    # Performance benchmarks
    log_check "Performance benchmarks"
    if has_script "bench"; then
        local start_time=$(($(date +%s%N)/1000000))
        if run_script "bench" > /tmp/bench-output.txt 2>&1; then
            local end_time=$(($(date +%s%N)/1000000))
            log_pass "Benchmarks" "$((end_time - start_time))"
        else
            log_warn "Benchmarks" "Some benchmarks failed"
        fi
    else
        log_skip "Performance benchmarks" "No bench script"
    fi

    # License check
    log_check "License compliance"
    if command -v license-checker &> /dev/null || [[ -f "node_modules/.bin/license-checker" ]]; then
        if npx license-checker --onlyAllow "MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC;0BSD" > /tmp/license-output.txt 2>&1; then
            log_pass "License check" "0"
        else
            log_warn "License compliance" "Review license output"
        fi
    else
        log_skip "License compliance" "No license-checker"
    fi

    return $phase_errors
}

# =============================================================================
# AGENT REVIEWS (Documentation Only - Triggered by Claude)
# =============================================================================

suggest_agent_reviews() {
    if [[ "$SKIP_AGENTS" == "true" ]]; then
        return 0
    fi

    log_phase "Agent Reviews (Suggested)"

    echo -e "${DIM}The following agent reviews are recommended:${NC}"
    echo ""

    # Always suggest core reviewers
    echo -e "${MAGENTA}Required:${NC}"
    echo "  • @code-reviewer - Code quality and patterns"
    echo "  • @spec-reviewer - Specification compliance"

    # Conditional reviewers based on changes
    echo ""
    echo -e "${MAGENTA}Conditional (based on changed files):${NC}"

    # Check for security-sensitive files
    if git diff --cached --name-only 2>/dev/null | grep -qE "(auth|security|password|token|secret|credential)" || \
       git diff --name-only HEAD~1 2>/dev/null | grep -qE "(auth|security|password|token|secret|credential)"; then
        echo "  • @security-reviewer - Security-sensitive changes detected"
    fi

    # Check for UI files
    if git diff --cached --name-only 2>/dev/null | grep -qE "\.(tsx|jsx|css|scss)$" || \
       git diff --name-only HEAD~1 2>/dev/null | grep -qE "\.(tsx|jsx|css|scss)$"; then
        echo "  • @accessibility-auditor - UI changes detected"
    fi

    # Check for performance-sensitive files
    if git diff --cached --name-only 2>/dev/null | grep -qE "(api|database|query|index)" || \
       git diff --name-only HEAD~1 2>/dev/null | grep -qE "(api|database|query|index)"; then
        echo "  • @performance-reviewer - Performance-sensitive changes"
    fi

    echo ""
    echo -e "${DIM}To run: /review with appropriate agent${NC}"
}

# =============================================================================
# RESULTS SUMMARY
# =============================================================================

print_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - STARTED_AT))

    echo ""
    echo -e "${CYAN}${BOLD}━━━ Verification Summary ━━━${NC}"
    echo ""

    # Overall status
    if [[ $TOTAL_ERRORS -eq 0 && $TOTAL_WARNINGS -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}✅ All checks passed${NC}"
    elif [[ $TOTAL_ERRORS -eq 0 ]]; then
        echo -e "${YELLOW}${BOLD}⚠️ Passed with warnings${NC}"
    else
        echo -e "${RED}${BOLD}❌ Verification failed${NC}"
    fi

    echo ""
    echo "Level: $LEVEL"
    echo "Duration: ${duration}s"
    echo "Errors: $TOTAL_ERRORS"
    echo "Warnings: $TOTAL_WARNINGS"

    # Results table
    echo ""
    echo -e "${BOLD}Results:${NC}"
    printf "%-25s %-10s %s\n" "Check" "Status" "Time"
    printf "%-25s %-10s %s\n" "-----" "------" "----"

    local i
    for i in "${!CHECK_NAMES[@]}"; do
        local check="${CHECK_NAMES[$i]}"
        local status="${CHECK_STATUSES[$i]}"
        local time="${CHECK_TIMES_LIST[$i]:-0}"
        local status_icon

        case "$status" in
            pass) status_icon="${GREEN}✓ Pass${NC}" ;;
            fail) status_icon="${RED}✗ Fail${NC}" ;;
            warn) status_icon="${YELLOW}⚠ Warn${NC}" ;;
            skip) status_icon="${DIM}○ Skip${NC}" ;;
        esac

        printf "%-25s %-10b %s\n" "$check" "$status_icon" "${time}ms"
    done

    # JSON output if requested
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        echo ""
        echo -e "${BOLD}JSON Output:${NC}"
        generate_json_output
    fi

    # Next steps
    echo ""
    echo -e "${BOLD}Next Steps:${NC}"
    if [[ $TOTAL_ERRORS -gt 0 ]]; then
        echo "  • Fix the failing checks above"
        echo "  • Run '/verify $LEVEL' again"
    elif [[ $TOTAL_WARNINGS -gt 0 ]]; then
        echo "  • Consider addressing warnings"
        echo "  • Ready for PR submission"
    else
        echo "  • Ready for PR submission"
        echo "  • Run '/verify release' before deploy"
    fi
}

generate_json_output() {
    local results="{"
    results+="\"level\":\"$LEVEL\","
    results+="\"status\":\"$([ $TOTAL_ERRORS -eq 0 ] && echo 'pass' || echo 'fail')\","
    results+="\"errors\":$TOTAL_ERRORS,"
    results+="\"warnings\":$TOTAL_WARNINGS,"
    results+="\"checks\":{"

    local first=true
    local i
    for i in "${!CHECK_NAMES[@]}"; do
        [[ "$first" != "true" ]] && results+=","
        first=false
        local check="${CHECK_NAMES[$i]}"
        local status="${CHECK_STATUSES[$i]}"
        local time="${CHECK_TIMES_LIST[$i]:-0}"
        results+="\"$check\":{\"status\":\"$status\",\"time\":$time}"
    done

    results+="}}"
    echo "$results" | jq '.'
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            quick|standard|full|release)
                LEVEL="$1"
                shift
                ;;
            --path)
                TARGET_PATH="$2"
                shift 2
                ;;
            --parallel)
                PARALLEL=true
                shift
                ;;
            --json)
                JSON_OUTPUT=true
                shift
                ;;
            --fail-fast)
                FAIL_FAST=true
                shift
                ;;
            --no-agents)
                SKIP_AGENTS=true
                shift
                ;;
            --timeout)
                TIMEOUT_MINUTES="$2"
                shift 2
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                print_usage
                exit 4
                ;;
        esac
    done
}

print_usage() {
    cat << EOF
Jarvis Verification Pipeline

Usage: $(basename "$0") [level] [options]

Levels:
  quick     Lint, types, formatting (default)
  standard  + Unit tests
  full      + Integration, E2E, build, agent reviews
  release   + Performance, security audit, bundle analysis

Options:
  --path PATH      Check specific path only
  --parallel       Run checks in parallel where possible
  --json           Output results as JSON
  --fail-fast      Stop on first failure
  --no-agents      Skip agent review suggestions
  --timeout MIN    Timeout in minutes (default: 10)
  -h, --help       Show this help

Examples:
  $(basename "$0") quick
  $(basename "$0") standard --fail-fast
  $(basename "$0") full --path src/
  $(basename "$0") release --json
EOF
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    parse_args "$@"

    echo -e "${CYAN}${BOLD}Jarvis Verification Pipeline${NC}"
    echo -e "Level: ${BOLD}$LEVEL${NC} | Path: ${BOLD}$TARGET_PATH${NC}"
    echo ""

    local exit_code=0

    # Phase 1: Quick (always run)
    if ! run_quick_checks; then
        exit_code=1
        [[ "$FAIL_FAST" == "true" ]] && { print_summary; exit $exit_code; }
    fi

    # Phase 2: Standard
    if [[ "$LEVEL" == "standard" || "$LEVEL" == "full" || "$LEVEL" == "release" ]]; then
        if ! run_standard_checks; then
            exit_code=1
            [[ "$FAIL_FAST" == "true" ]] && { print_summary; exit $exit_code; }
        fi
    fi

    # Phase 3: Full
    if [[ "$LEVEL" == "full" || "$LEVEL" == "release" ]]; then
        if ! run_full_checks; then
            exit_code=1
            [[ "$FAIL_FAST" == "true" ]] && { print_summary; exit $exit_code; }
        fi

        # Agent review suggestions
        suggest_agent_reviews
    fi

    # Phase 4: Release
    if [[ "$LEVEL" == "release" ]]; then
        if ! run_release_checks; then
            exit_code=1
        fi
    fi

    print_summary

    # Set exit code based on results
    if [[ $TOTAL_ERRORS -gt 0 ]]; then
        exit 1
    elif [[ $TOTAL_WARNINGS -gt 0 ]]; then
        exit 2
    else
        exit 0
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
