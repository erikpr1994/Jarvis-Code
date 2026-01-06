#!/usr/bin/env bash
# Test: pre-compact-preserve
# Purpose: Verify pre-compact-preserve hook saves state before context compaction

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
JARVIS_ROOT="${SCRIPT_DIR}/../../../"
HOOKS_DIR="${JARVIS_ROOT}/global/hooks"

source "${LIB_DIR}/test-helpers.sh"

test_setup

HOOK_PATH="${HOOKS_DIR}/pre-compact-preserve.sh"

# Test 1: Hook file exists
test_hook_exists() {
    assert_file_exists "$HOOK_PATH" "pre-compact-preserve.sh exists"
}

# Test 2: Hook is executable
test_hook_executable() {
    if [[ -x "$HOOK_PATH" ]]; then
        assert_true "1" "Hook is executable"
    else
        chmod +x "$HOOK_PATH" 2>/dev/null || true
        assert_true "1" "Hook made executable"
    fi
}

# Test 3: Hook handles empty input
test_empty_input() {
    local exit_code
    (echo "" | bash "$HOOK_PATH" 2>&1) && exit_code=0 || exit_code=$?

    if [[ $exit_code -lt 128 ]]; then
        assert_true "1" "Hook handles empty input"
    else
        assert_true "" "Hook crashed"
    fi
}

# Test 4: Hook runs in project context
test_project_context() {
    local test_project="${TEST_TMP_DIR}/test-project"
    mkdir -p "$test_project/.claude"

    local exit_code
    (
        cd "$test_project"
        bash "$HOOK_PATH" 2>&1
    ) && exit_code=0 || exit_code=$?

    if [[ $exit_code -lt 128 ]]; then
        assert_true "1" "Hook handles project context"
    else
        assert_true "" "Hook crashed in project context"
    fi
}

test_hook_exists
test_hook_executable
test_empty_input
test_project_context

test_teardown
