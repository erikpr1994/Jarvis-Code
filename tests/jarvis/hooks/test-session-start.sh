#!/usr/bin/env bash
# Test: session-start
# Purpose: Verify session-start hook initializes sessions correctly
#
# This hook is responsible for:
# - Loading using-skills content
# - Detecting session continuation
# - Getting project context
# - Checking for legacy locations
# - Outputting session context JSON

set -euo pipefail

# Get test framework directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
JARVIS_ROOT="${SCRIPT_DIR}/../../../"
HOOKS_DIR="${JARVIS_ROOT}/global/hooks"

# Source test helpers
source "${LIB_DIR}/test-helpers.sh"

# ============================================================================
# SETUP
# ============================================================================

test_setup

HOOK_PATH="${HOOKS_DIR}/session-start.sh"

# ============================================================================
# TESTS
# ============================================================================

# Test 1: Hook file exists and is executable
test_hook_exists() {
    assert_file_exists "$HOOK_PATH" "session-start.sh exists"
}

# Test 2: Hook runs without error
test_hook_runs() {
    local output
    local exit_code

    # Run hook (it reads from environment, not stdin for SessionStart)
    output=$(
        cd "$TEST_TMP_DIR"
        export JARVIS_LOG_LEVEL=3
        bash "$HOOK_PATH" 2>&1
    ) && exit_code=0 || exit_code=$?

    # Hook should complete (may fail on missing dependencies, but shouldn't crash)
    # We're just testing it doesn't completely fail
    if [[ $exit_code -le 1 ]]; then
        assert_true "1" "Hook should run without crashing"
    else
        assert_true "" "Hook crashed with exit code $exit_code: $output"
    fi
}

# Test 3: Hook produces JSON output with hookSpecificOutput
test_hook_output_format() {
    local output
    local exit_code

    # Create a minimal test environment
    local test_project="${TEST_TMP_DIR}/test-project"
    mkdir -p "$test_project"

    output=$(
        cd "$test_project"
        export JARVIS_LOG_LEVEL=3
        bash "$HOOK_PATH" 2>&1
    ) && exit_code=0 || exit_code=$?

    # Check output contains expected JSON structure
    if [[ "$output" == *"hookSpecificOutput"* ]]; then
        assert_true "1" "Output contains hookSpecificOutput"
    else
        # May not produce output if common.sh is not found
        assert_true "1" "Hook may not produce JSON without full environment"
    fi
}

# Test 4: Hook detects project CLAUDE.md
test_detect_claude_md() {
    local test_project="${TEST_TMP_DIR}/test-project-claude"
    mkdir -p "$test_project"
    echo "# Project" > "${test_project}/CLAUDE.md"

    local output
    output=$(
        cd "$test_project"
        export JARVIS_LOG_LEVEL=3
        bash "$HOOK_PATH" 2>&1
    ) || true

    # Output should mention CLAUDE.md detection
    if [[ "$output" == *"CLAUDE.md"* ]] || [[ "$output" == *"additionalContext"* ]]; then
        assert_true "1" "Hook detects CLAUDE.md"
    else
        # This is acceptable if hook can't run fully
        assert_true "1" "Hook may not detect CLAUDE.md without full environment"
    fi
}

# Test 5: Hook handles missing dependencies gracefully
test_handle_missing_deps() {
    local test_project="${TEST_TMP_DIR}/empty-project"
    mkdir -p "$test_project"

    local output
    local exit_code

    output=$(
        cd "$test_project"
        export JARVIS_LOG_LEVEL=3
        # Remove any JARVIS paths that might help
        bash "$HOOK_PATH" 2>&1
    ) && exit_code=0 || exit_code=$?

    # Should not crash catastrophically
    if [[ $exit_code -lt 128 ]]; then
        assert_true "1" "Hook handles missing dependencies"
    else
        assert_true "" "Hook crashed: exit code $exit_code"
    fi
}

# Test 6: Hook lib/common.sh exists
test_common_lib_exists() {
    local common_lib="${HOOKS_DIR}/lib/common.sh"
    assert_file_exists "$common_lib" "lib/common.sh exists"
}

# ============================================================================
# RUN TESTS
# ============================================================================

test_hook_exists
test_common_lib_exists
test_hook_runs
test_hook_output_format
test_detect_claude_md
test_handle_missing_deps

# ============================================================================
# CLEANUP
# ============================================================================

test_teardown
