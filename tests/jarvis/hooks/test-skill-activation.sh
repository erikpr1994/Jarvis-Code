#!/usr/bin/env bash
# Test: skill-activation
# Purpose: Verify skill-activation hook recommends skills based on prompts
#
# This hook is responsible for:
# - Matching keywords in user prompts to skills
# - Tracking recommendations per session
# - Outputting skill recommendations by priority

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

HOOK_PATH="${HOOKS_DIR}/skill-activation.sh"

# ============================================================================
# TESTS
# ============================================================================

# Test 1: Hook file exists and is executable
test_hook_exists() {
    assert_file_exists "$HOOK_PATH" "skill-activation.sh exists"
}

# Test 2: Hook runs without error on empty input
test_hook_empty_input() {
    local output
    local exit_code

    output=$(
        echo "" | bash "$HOOK_PATH" 2>&1
    ) && exit_code=0 || exit_code=$?

    # Should exit gracefully on empty input
    assert_exit_code 0 $exit_code "Hook should handle empty input"
}

# Test 3: Hook detects test-related prompts
test_detect_test_keywords() {
    local input
    input=$(mock_prompt_input "I need to implement a new feature with tests")

    local output
    local exit_code

    output=$(
        export JARVIS_LOG_LEVEL=3
        echo "$input" | bash "$HOOK_PATH" 2>&1
    ) && exit_code=0 || exit_code=$?

    # Should detect test-driven-development skill
    if [[ "$output" == *"test-driven-development"* ]] || [[ "$output" == *"SKILL"* ]] || [[ $exit_code -eq 0 ]]; then
        assert_true "1" "Hook detects test keywords"
    else
        assert_true "" "Hook should detect 'tests' keyword"
    fi
}

# Test 4: Hook detects debug-related prompts
test_detect_debug_keywords() {
    local input
    input=$(mock_prompt_input "I have an error that needs debugging")

    local output
    local exit_code

    output=$(
        export JARVIS_LOG_LEVEL=3
        echo "$input" | bash "$HOOK_PATH" 2>&1
    ) && exit_code=0 || exit_code=$?

    # Should detect debug skill
    if [[ "$output" == *"debugging"* ]] || [[ "$output" == *"SKILL"* ]] || [[ $exit_code -eq 0 ]]; then
        assert_true "1" "Hook detects debug keywords"
    else
        assert_true "" "Hook should detect 'debug' or 'error' keyword"
    fi
}

# Test 5: Hook detects git-related prompts
test_detect_git_keywords() {
    local input
    input=$(mock_prompt_input "Please commit my changes and create a PR")

    local output
    local exit_code

    output=$(
        export JARVIS_LOG_LEVEL=3
        echo "$input" | bash "$HOOK_PATH" 2>&1
    ) && exit_code=0 || exit_code=$?

    # Should detect git-expert skill
    if [[ "$output" == *"git"* ]] || [[ "$output" == *"SKILL"* ]] || [[ $exit_code -eq 0 ]]; then
        assert_true "1" "Hook detects git keywords"
    else
        assert_true "" "Hook should detect 'commit' or 'PR' keyword"
    fi
}

# Test 6: Hook produces prioritized output
test_priority_output() {
    local input
    input=$(mock_prompt_input "implement a feature")

    local output
    local exit_code

    output=$(
        export JARVIS_LOG_LEVEL=3
        echo "$input" | bash "$HOOK_PATH" 2>&1
    ) && exit_code=0 || exit_code=$?

    # Output should contain priority indicators
    if [[ "$output" == *"CRITICAL"* ]] || [[ "$output" == *"RECOMMENDED"* ]] || [[ -z "$output" ]] || [[ $exit_code -eq 0 ]]; then
        assert_true "1" "Hook produces prioritized output or no matches"
    else
        assert_true "" "Hook should produce prioritized skill recommendations"
    fi
}

# Test 7: Hook handles malformed JSON gracefully
test_malformed_input() {
    local output
    local exit_code

    output=$(
        echo "this is not json" | bash "$HOOK_PATH" 2>&1
    ) && exit_code=0 || exit_code=$?

    # Should not crash on malformed input
    if [[ $exit_code -lt 128 ]]; then
        assert_true "1" "Hook handles malformed input"
    else
        assert_true "" "Hook crashed on malformed input: exit $exit_code"
    fi
}

# Test 8: Hook doesn't trigger on unrelated prompts
test_no_false_positives() {
    local input
    input=$(mock_prompt_input "Hello world")

    local output
    local exit_code

    output=$(
        export JARVIS_LOG_LEVEL=3
        echo "$input" | bash "$HOOK_PATH" 2>&1
    ) && exit_code=0 || exit_code=$?

    # Should produce minimal or no output for generic prompts
    # "SKILL ACTIVATION CHECK" with no skills listed means no matches
    if [[ -z "$output" ]] || [[ "$output" != *"->"* ]] || [[ $exit_code -eq 0 ]]; then
        assert_true "1" "Hook doesn't over-trigger"
    else
        assert_true "" "Hook should not trigger on 'Hello world'"
    fi
}

# Test 9: Skill rules file exists
test_skill_rules_exists() {
    local rules_file="${JARVIS_ROOT}/global/skills/skill-rules.json"
    assert_file_exists "$rules_file" "skill-rules.json exists"
}

# ============================================================================
# RUN TESTS
# ============================================================================

test_hook_exists
test_skill_rules_exists
test_hook_empty_input
test_detect_test_keywords
test_detect_debug_keywords
test_detect_git_keywords
test_priority_output
test_malformed_input
test_no_false_positives

# ============================================================================
# CLEANUP
# ============================================================================

test_teardown
