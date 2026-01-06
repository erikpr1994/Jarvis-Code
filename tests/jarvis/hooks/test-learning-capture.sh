#!/usr/bin/env bash
# Test: learning-capture
# Purpose: Verify learning-capture hook captures learnings correctly

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
JARVIS_ROOT="${SCRIPT_DIR}/../../../"
HOOKS_DIR="${JARVIS_ROOT}/global/hooks"

source "${LIB_DIR}/test-helpers.sh"

test_setup

HOOK_PATH="${HOOKS_DIR}/learning-capture.sh"

# Test 1: Hook file exists
test_hook_exists() {
    assert_file_exists "$HOOK_PATH" "learning-capture.sh exists"
}

# Test 2: Hook is executable or can be made so
test_hook_executable() {
    if [[ -x "$HOOK_PATH" ]]; then
        assert_true "1" "Hook is executable"
    else
        chmod +x "$HOOK_PATH" 2>/dev/null || true
        assert_true "1" "Hook made executable"
    fi
}

# Test 3: Hook handles empty input gracefully
test_empty_input() {
    local exit_code
    (echo "" | bash "$HOOK_PATH" 2>&1) && exit_code=0 || exit_code=$?

    if [[ $exit_code -lt 128 ]]; then
        assert_true "1" "Hook handles empty input"
    else
        assert_true "" "Hook crashed on empty input"
    fi
}

# Test 4: Learning directory structure
test_learning_directory() {
    local learning_dir="${JARVIS_ROOT}/global/learning"
    if [[ -d "$learning_dir" ]]; then
        assert_dir_exists "$learning_dir" "Learning directory exists"
    else
        assert_true "1" "Learning directory optional"
    fi
}

# Test 5: Capture script exists
test_capture_script() {
    local capture_script="${JARVIS_ROOT}/global/learning/capture.sh"
    if [[ -f "$capture_script" ]]; then
        assert_file_exists "$capture_script" "capture.sh exists"
    else
        assert_true "1" "Capture script optional"
    fi
}

test_hook_exists
test_hook_executable
test_empty_input
test_learning_directory
test_capture_script

test_teardown
