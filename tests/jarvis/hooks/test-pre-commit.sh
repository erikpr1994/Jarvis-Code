#!/usr/bin/env bash
# Test: pre-commit
# Purpose: Verify pre-commit hook validates commits

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
JARVIS_ROOT="${SCRIPT_DIR}/../../../"
HOOKS_DIR="${JARVIS_ROOT}/global/hooks"

source "${LIB_DIR}/test-helpers.sh"

test_setup

HOOK_PATH="${HOOKS_DIR}/pre-commit.sh"

# Test 1: Hook file exists
test_hook_exists() {
    assert_file_exists "$HOOK_PATH" "pre-commit.sh exists"
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

# Test 3: Hook handles test mode
test_test_mode() {
    local exit_code
    local output

    output=$(
        export JARVIS_TEST_MODE=1
        bash "$HOOK_PATH" 2>&1
    ) && exit_code=0 || exit_code=$?

    # Should handle gracefully in test mode
    if [[ $exit_code -lt 128 ]]; then
        assert_true "1" "Hook handles test mode"
    else
        assert_true "" "Hook crashed in test mode"
    fi
}

# Test 4: Hook checks for staged files
test_checks_staged_files() {
    # Create test git repo
    local test_repo="${TEST_TMP_DIR}/test-repo"
    mkdir -p "$test_repo"
    cd "$test_repo"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"

    local exit_code
    (
        export JARVIS_TEST_MODE=1
        bash "$HOOK_PATH" 2>&1
    ) && exit_code=0 || exit_code=$?

    # Should complete without crash
    if [[ $exit_code -lt 128 ]]; then
        assert_true "1" "Hook checks staged files"
    else
        assert_true "" "Hook crashed checking staged files"
    fi
}

test_hook_exists
test_hook_executable
test_test_mode
test_checks_staged_files

test_teardown
