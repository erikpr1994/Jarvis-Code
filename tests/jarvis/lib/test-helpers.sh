#!/usr/bin/env bash
# Jarvis Testing Framework - Shared Test Utilities
# Purpose: Common assertion and helper functions for all tests
#
# Usage: source this file in test scripts
#   source "${LIB_DIR}/test-helpers.sh"

# ============================================================================
# CONFIGURATION
# ============================================================================

# Test mode indicator
export JARVIS_TEST_MODE="${JARVIS_TEST_MODE:-1}"

# Track assertion results within a test
_ASSERTION_COUNT=0
_ASSERTION_FAILURES=0

# Temp directory for test artifacts
TEST_TMP_DIR="${TMPDIR:-/tmp}/jarvis-test-$$"
mkdir -p "$TEST_TMP_DIR" 2>/dev/null || true

# Cleanup on exit
trap 'rm -rf "$TEST_TMP_DIR" 2>/dev/null' EXIT

# ============================================================================
# ASSERTION FUNCTIONS
# ============================================================================

# Assert two values are equal
# Usage: assert_equals "expected" "actual" "description"
# Note: Returns 0 always to work with set -e, tracks failures internally
assert_equals() {
    local expected="$1"
    local actual="$2"
    local description="${3:-Equality check}"

    ((_ASSERTION_COUNT++)) || true

    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        ((_ASSERTION_FAILURES++)) || true
        echo "ASSERTION FAILED: $description"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        return 0  # Don't exit with set -e, track failures internally
    fi
}

# Assert actual value contains expected substring
# Usage: assert_contains "expected_substring" "actual_string" "description"
assert_contains() {
    local expected="$1"
    local actual="$2"
    local description="${3:-Contains check}"

    ((_ASSERTION_COUNT++)) || true

    if [[ "$actual" == *"$expected"* ]]; then
        return 0
    else
        ((_ASSERTION_FAILURES++)) || true
        echo "ASSERTION FAILED: $description"
        echo "  Expected to contain: '$expected'"
        echo "  Actual: '$actual'"
        return 0
    fi
}

# Assert actual value does NOT contain expected substring
# Usage: assert_not_contains "unwanted_substring" "actual_string" "description"
assert_not_contains() {
    local unwanted="$1"
    local actual="$2"
    local description="${3:-Not contains check}"

    ((_ASSERTION_COUNT++)) || true

    if [[ "$actual" != *"$unwanted"* ]]; then
        return 0
    else
        ((_ASSERTION_FAILURES++)) || true
        echo "ASSERTION FAILED: $description"
        echo "  Should NOT contain: '$unwanted'"
        echo "  Actual: '$actual'"
        return 0
    fi
}

# Assert file exists
# Usage: assert_file_exists "/path/to/file" "description"
assert_file_exists() {
    local file_path="$1"
    local description="${2:-File exists check}"

    ((_ASSERTION_COUNT++)) || true

    if [[ -f "$file_path" ]]; then
        return 0
    else
        ((_ASSERTION_FAILURES++)) || true
        echo "ASSERTION FAILED: $description"
        echo "  File does not exist: '$file_path'"
        return 0
    fi
}

# Assert file does NOT exist
# Usage: assert_file_not_exists "/path/to/file" "description"
assert_file_not_exists() {
    local file_path="$1"
    local description="${2:-File not exists check}"

    ((_ASSERTION_COUNT++)) || true

    if [[ ! -f "$file_path" ]]; then
        return 0
    else
        ((_ASSERTION_FAILURES++)) || true
        echo "ASSERTION FAILED: $description"
        echo "  File should not exist: '$file_path'"
        return 0
    fi
}

# Assert directory exists
# Usage: assert_dir_exists "/path/to/dir" "description"
assert_dir_exists() {
    local dir_path="$1"
    local description="${2:-Directory exists check}"

    ((_ASSERTION_COUNT++)) || true

    if [[ -d "$dir_path" ]]; then
        return 0
    else
        ((_ASSERTION_FAILURES++)) || true
        echo "ASSERTION FAILED: $description"
        echo "  Directory does not exist: '$dir_path'"
        return 0
    fi
}

# Assert exit code equals expected
# Usage: assert_exit_code 0 $? "description"
assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local description="${3:-Exit code check}"

    ((_ASSERTION_COUNT++)) || true

    if [[ "$expected" -eq "$actual" ]]; then
        return 0
    else
        ((_ASSERTION_FAILURES++)) || true
        echo "ASSERTION FAILED: $description"
        echo "  Expected exit code: $expected"
        echo "  Actual exit code: $actual"
        return 0
    fi
}

# Assert value is true (non-empty and not "false" or "0")
# Usage: assert_true "$result" "description"
assert_true() {
    local value="$1"
    local description="${2:-True check}"

    ((_ASSERTION_COUNT++)) || true

    if [[ -n "$value" && "$value" != "false" && "$value" != "0" ]]; then
        return 0
    else
        ((_ASSERTION_FAILURES++)) || true
        echo "ASSERTION FAILED: $description"
        echo "  Expected truthy value, got: '$value'"
        return 0
    fi
}

# Assert value is false (empty, "false", or "0")
# Usage: assert_false "$result" "description"
assert_false() {
    local value="$1"
    local description="${2:-False check}"

    ((_ASSERTION_COUNT++)) || true

    if [[ -z "$value" || "$value" == "false" || "$value" == "0" ]]; then
        return 0
    else
        ((_ASSERTION_FAILURES++)) || true
        echo "ASSERTION FAILED: $description"
        echo "  Expected falsy value, got: '$value'"
        return 0
    fi
}

# Assert JSON contains expected key-value pair
# Usage: assert_json_contains "key" "expected_value" "$json" "description"
assert_json_contains() {
    local key="$1"
    local expected_value="$2"
    local json="$3"
    local description="${4:-JSON contains check}"

    ((_ASSERTION_COUNT++)) || true

    # Simple pattern matching for JSON (no jq dependency)
    local pattern="\"${key}\"[[:space:]]*:[[:space:]]*\"${expected_value}\""

    if echo "$json" | grep -qE "$pattern"; then
        return 0
    else
        ((_ASSERTION_FAILURES++)) || true
        echo "ASSERTION FAILED: $description"
        echo "  Expected JSON to contain: $key = '$expected_value'"
        echo "  JSON: $json"
        return 0
    fi
}

# ============================================================================
# HOOK TESTING HELPERS
# ============================================================================

# Run a hook script with test input
# Usage: run_hook "/path/to/hook.sh" "$input_json"
run_hook() {
    local hook_path="$1"
    local input="${2:-}"

    if [[ ! -f "$hook_path" ]]; then
        echo "ERROR: Hook not found: $hook_path"
        return 1
    fi

    if [[ ! -x "$hook_path" ]]; then
        chmod +x "$hook_path" 2>/dev/null || true
    fi

    # Run hook with input piped to stdin
    echo "$input" | bash "$hook_path" 2>&1
}

# Run a hook and capture both output and exit code
# Usage: run_hook_with_exit_code "/path/to/hook.sh" "$input_json"
# Returns: output in stdout, exit code in $?
run_hook_with_exit_code() {
    local hook_path="$1"
    local input="${2:-}"
    local output
    local exit_code

    output=$(run_hook "$hook_path" "$input") && exit_code=0 || exit_code=$?

    echo "$output"
    return $exit_code
}

# Generate mock tool input JSON for PreToolUse hooks
# Usage: mock_tool_input "Write" '{"file_path": "/test.txt", "content": "hello"}'
mock_tool_input() {
    local tool_name="$1"
    local tool_params="${2:-{}}"

    cat << EOF
{
  "tool_name": "$tool_name",
  "tool_input": $tool_params,
  "session_id": "test-session-$(date +%s)"
}
EOF
}

# Generate mock prompt input JSON for UserPromptSubmit hooks
# Usage: mock_prompt_input "Implement a new feature for testing"
mock_prompt_input() {
    local prompt="$1"
    local session_id="${2:-test-session-$(date +%s)}"

    # Escape the prompt for JSON
    local escaped_prompt
    escaped_prompt=$(echo "$prompt" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n' | sed 's/\\n$//')

    cat << EOF
{
  "prompt": "$escaped_prompt",
  "session_id": "$session_id"
}
EOF
}

# Generate mock session start input
# Usage: mock_session_start
mock_session_start() {
    local cwd="${1:-$(pwd)}"

    cat << EOF
{
  "event": "SessionStart",
  "cwd": "$cwd",
  "session_id": "test-session-$(date +%s)"
}
EOF
}

# ============================================================================
# SKILL TESTING HELPERS
# ============================================================================

# Check if a skill file exists in the expected location
# Usage: skill_exists "skill-name"
skill_exists() {
    local skill_name="$1"
    local jarvis_root="${JARVIS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)}"

    local skill_file="${jarvis_root}/global/skills/domain/${skill_name}/SKILL.md"

    if [[ ! -f "$skill_file" ]]; then
        skill_file="${jarvis_root}/global/skills/process/${skill_name}/SKILL.md"
    fi

    if [[ ! -f "$skill_file" ]]; then
        skill_file="${jarvis_root}/global/skills/meta/${skill_name}/SKILL.md"
    fi

    [[ -f "$skill_file" ]]
}

# Get skill file path
# Usage: get_skill_path "skill-name"
get_skill_path() {
    local skill_name="$1"
    local jarvis_root="${JARVIS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)}"

    for category in domain process meta execution; do
        local skill_file="${jarvis_root}/global/skills/${category}/${skill_name}/SKILL.md"
        if [[ -f "$skill_file" ]]; then
            echo "$skill_file"
            return 0
        fi
    done

    return 1
}

# Check if prompt would trigger a skill (based on keyword matching)
# Usage: prompt_triggers_skill "implement a feature" "test-driven-development"
prompt_triggers_skill() {
    local prompt="$1"
    local skill_name="$2"

    # This is a simplified check - real implementation would use skill-activation.sh logic
    local jarvis_root="${JARVIS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)}"
    local rules_file="${jarvis_root}/global/skills/skill-rules.json"

    if [[ ! -f "$rules_file" ]]; then
        return 1
    fi

    # Extract keywords for the skill (simplified parsing)
    local keywords
    keywords=$(grep -A 20 "\"$skill_name\"" "$rules_file" | grep "keywords" | head -1 | grep -oP '\[.*?\]' | tr -d '[]"' | tr ',' ' ')

    if [[ -z "$keywords" ]]; then
        return 1
    fi

    local prompt_lower
    prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

    for keyword in $keywords; do
        if echo "$prompt_lower" | grep -qi "\b$keyword\b" 2>/dev/null; then
            return 0
        fi
    done

    return 1
}

# ============================================================================
# TEST LIFECYCLE HELPERS
# ============================================================================

# Setup function to run before each test (call in test files)
# Usage: test_setup
test_setup() {
    _ASSERTION_COUNT=0
    _ASSERTION_FAILURES=0

    # Create fresh temp directory for this test
    rm -rf "$TEST_TMP_DIR" 2>/dev/null || true
    mkdir -p "$TEST_TMP_DIR"

    # Set test environment variables
    export JARVIS_TEST_MODE=1
    export JARVIS_LOG_LEVEL=3  # ERROR only
}

# Teardown function to run after each test (call in test files)
# Usage: test_teardown
test_teardown() {
    # Cleanup temp directory
    rm -rf "$TEST_TMP_DIR" 2>/dev/null || true

    # Return appropriate exit code based on assertions
    if [[ ${_ASSERTION_FAILURES:-0} -gt 0 ]]; then
        echo "Test completed with ${_ASSERTION_FAILURES} failure(s) out of ${_ASSERTION_COUNT} assertions"
        exit 1
    fi
    exit 0
}

# Get test results summary
# Usage: test_summary
test_summary() {
    echo "Assertions: $_ASSERTION_COUNT total, $_ASSERTION_FAILURES failed"

    if [[ $_ASSERTION_FAILURES -gt 0 ]]; then
        return 1
    fi
    return 0
}

# ============================================================================
# ISOLATION HELPERS
# ============================================================================

# Create an isolated test directory with basic structure
# Usage: create_test_project "project-name"
create_test_project() {
    local project_name="${1:-test-project}"
    local project_dir="${TEST_TMP_DIR}/${project_name}"

    mkdir -p "$project_dir"
    cd "$project_dir"

    # Initialize basic structure
    mkdir -p .claude
    echo "# Test Project" > README.md

    echo "$project_dir"
}

# Create a mock .claude directory structure
# Usage: create_mock_claude_dir "/path/to/project"
create_mock_claude_dir() {
    local project_dir="$1"

    mkdir -p "${project_dir}/.claude/skills"
    mkdir -p "${project_dir}/.claude/tasks"
    echo "# Project CLAUDE.md" > "${project_dir}/CLAUDE.md"
}

# Initialize a test git repository
# Usage: init_test_git_repo "/path/to/project"
init_test_git_repo() {
    local project_dir="$1"

    cd "$project_dir"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test User"
    echo "# Test" > README.md
    git add README.md
    git commit -q -m "Initial commit"
}
