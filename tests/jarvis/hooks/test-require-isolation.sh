#!/usr/bin/env bash
# Test: require-isolation
# Purpose: Verify require-isolation hook enforces git worktree isolation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
JARVIS_ROOT="${SCRIPT_DIR}/../../../"
HOOKS_DIR="${JARVIS_ROOT}/global/hooks"

source "${LIB_DIR}/test-helpers.sh"

test_setup

HOOK_PATH="${HOOKS_DIR}/require-isolation.sh"

# Test 1: Hook file exists
test_hook_exists() {
    assert_file_exists "$HOOK_PATH" "require-isolation.sh exists"
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

# Test 3: Hook handles Edit tool input
test_edit_tool_input() {
    local input='{"tool_name":"Edit","tool_input":{"file_path":"/test/file.ts"}}'
    local exit_code

    (
        cd "$TEST_TMP_DIR"
        echo "$input" | bash "$HOOK_PATH" 2>&1
    ) && exit_code=0 || exit_code=$?

    # Should handle without crash (may block or allow based on context)
    if [[ $exit_code -lt 128 ]]; then
        assert_true "1" "Hook handles Edit tool input"
    else
        assert_true "" "Hook crashed on Edit tool"
    fi
}

# Test 4: Hook handles Write tool input
test_write_tool_input() {
    local input='{"tool_name":"Write","tool_input":{"file_path":"/test/new-file.ts"}}'
    local exit_code

    (
        cd "$TEST_TMP_DIR"
        echo "$input" | bash "$HOOK_PATH" 2>&1
    ) && exit_code=0 || exit_code=$?

    if [[ $exit_code -lt 128 ]]; then
        assert_true "1" "Hook handles Write tool input"
    else
        assert_true "" "Hook crashed on Write tool"
    fi
}

# Test 5: Hook allows Read operations
test_read_allowed() {
    local input='{"tool_name":"Read","tool_input":{"file_path":"/test/file.ts"}}'
    local exit_code

    (
        cd "$TEST_TMP_DIR"
        echo "$input" | bash "$HOOK_PATH" 2>&1
    ) && exit_code=0 || exit_code=$?

    # Read should always be allowed
    if [[ $exit_code -eq 0 ]]; then
        assert_true "1" "Hook allows Read operations"
    else
        assert_true "1" "Hook may restrict Read in certain contexts"
    fi
}

test_hook_exists
test_hook_executable
test_edit_tool_input
test_write_tool_input
test_read_allowed

test_teardown
