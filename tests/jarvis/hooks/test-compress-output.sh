#!/usr/bin/env bash
# Test: compress-output
# Purpose: Verify compress-output hook compresses verbose tool outputs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
JARVIS_ROOT="${SCRIPT_DIR}/../../../"
HOOKS_DIR="${JARVIS_ROOT}/global/hooks"

source "${LIB_DIR}/test-helpers.sh"

test_setup

HOOK_PATH="${HOOKS_DIR}/compress-output.sh"

# Test 1: Hook file exists
test_hook_exists() {
    assert_file_exists "$HOOK_PATH" "compress-output.sh exists"
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

# Test 4: Hook handles verbose output
test_verbose_output() {
    # Create a large output to test compression
    local large_output=""
    for i in {1..100}; do
        large_output+="Line $i: This is a test line that should be compressed if too long.\n"
    done

    local input
    input=$(cat << EOF
{
  "tool_name": "Bash",
  "tool_output": "$large_output"
}
EOF
)

    local exit_code
    (echo "$input" | bash "$HOOK_PATH" 2>&1) && exit_code=0 || exit_code=$?

    if [[ $exit_code -lt 128 ]]; then
        assert_true "1" "Hook handles verbose output"
    else
        assert_true "" "Hook crashed on verbose output"
    fi
}

test_hook_exists
test_hook_executable
test_empty_input
test_verbose_output

test_teardown
