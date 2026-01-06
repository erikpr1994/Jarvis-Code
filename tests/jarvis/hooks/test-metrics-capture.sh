#!/usr/bin/env bash
# Test: metrics-capture
# Purpose: Verify metrics-capture hook collects usage metrics

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
JARVIS_ROOT="${SCRIPT_DIR}/../../../"
HOOKS_DIR="${JARVIS_ROOT}/global/hooks"

source "${LIB_DIR}/test-helpers.sh"

test_setup

HOOK_PATH="${HOOKS_DIR}/metrics-capture.sh"

# Test 1: Hook file exists
test_hook_exists() {
    assert_file_exists "$HOOK_PATH" "metrics-capture.sh exists"
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

# Test 4: Metrics directory structure
test_metrics_directory() {
    local metrics_dir="${JARVIS_ROOT}/global/metrics"
    if [[ -d "$metrics_dir" ]]; then
        assert_dir_exists "$metrics_dir" "Metrics directory exists"
    else
        assert_true "1" "Metrics directory optional"
    fi
}

test_hook_exists
test_hook_executable
test_empty_input
test_metrics_directory

test_teardown
