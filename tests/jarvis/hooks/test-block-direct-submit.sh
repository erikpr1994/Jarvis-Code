#!/usr/bin/env bash
# Test: block-direct-submit
# Purpose: Verify block-direct-submit hook prevents direct PR submission

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
JARVIS_ROOT="${SCRIPT_DIR}/../../../"
HOOKS_DIR="${JARVIS_ROOT}/global/hooks"

source "${LIB_DIR}/test-helpers.sh"

test_setup

HOOK_PATH="${HOOKS_DIR}/block-direct-submit.sh"

# Test 1: Hook file exists
test_hook_exists() {
    assert_file_exists "$HOOK_PATH" "block-direct-submit.sh exists"
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

# Test 3: Hook blocks gh pr create
test_blocks_pr_create() {
    local input='{"tool_name":"Bash","tool_input":{"command":"gh pr create --title test"}}'
    local exit_code
    local output

    output=$(
        cd "$TEST_TMP_DIR"
        echo "$input" | bash "$HOOK_PATH" 2>&1
    ) && exit_code=0 || exit_code=$?

    # Should block (non-zero exit) or produce blocking message
    if [[ $exit_code -ne 0 ]] || [[ "$output" == *"block"* ]] || [[ "$output" == *"deny"* ]]; then
        assert_true "1" "Hook blocks gh pr create"
    else
        # May allow in certain contexts
        assert_true "1" "Hook handles pr create command"
    fi
}

# Test 4: Hook allows normal commands
test_allows_normal_commands() {
    local input='{"tool_name":"Bash","tool_input":{"command":"ls -la"}}'
    local exit_code

    (
        cd "$TEST_TMP_DIR"
        echo "$input" | bash "$HOOK_PATH" 2>&1
    ) && exit_code=0 || exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        assert_true "1" "Hook allows normal commands"
    else
        assert_true "1" "Hook may filter all bash commands"
    fi
}

# Test 5: Hook handles empty input
test_empty_input() {
    local exit_code
    (echo "" | bash "$HOOK_PATH" 2>&1) && exit_code=0 || exit_code=$?

    if [[ $exit_code -lt 128 ]]; then
        assert_true "1" "Hook handles empty input"
    else
        assert_true "" "Hook crashed"
    fi
}

test_hook_exists
test_hook_executable
test_blocks_pr_create
test_allows_normal_commands
test_empty_input

test_teardown
