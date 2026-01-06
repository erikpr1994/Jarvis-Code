# Hook Tests

This directory contains tests for Jarvis hooks.

## Test File Naming

All hook test files should follow the naming convention:

```
test-<hook-name>.sh
```

For example:
- `test-session-start.sh`
- `test-skill-activation.sh`
- `test-pre-commit.sh`
- `test-block-direct-submit.sh`

## Hook Events Reference

| Event | When Triggered | Input Data |
|-------|----------------|------------|
| `SessionStart` | Claude Code session begins | `{cwd, session_id}` |
| `UserPromptSubmit` | User submits a prompt | `{prompt, session_id}` |
| `PreToolUse` | Before tool execution | `{tool_name, tool_input, session_id}` |
| `PostToolUse` | After tool execution | `{tool_name, tool_output, session_id}` |

## Writing a Hook Test

### Basic Template

```bash
#!/usr/bin/env bash
# Test: <hook-name>
# Purpose: Verify <hook-name> hook behaves correctly

set -euo pipefail

# Get test framework directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
HOOKS_DIR="${SCRIPT_DIR}/../../../global/hooks"

# Source test helpers
source "${LIB_DIR}/test-helpers.sh"

# ============================================================================
# SETUP
# ============================================================================

test_setup

HOOK_PATH="${HOOKS_DIR}/<hook-name>.sh"

# ============================================================================
# TESTS
# ============================================================================

# Test 1: Hook file exists and is executable
test_hook_exists() {
    assert_file_exists "$HOOK_PATH" "Hook file exists"
}

# Test 2: Hook runs without error on valid input
test_hook_valid_input() {
    local input
    input=$(mock_prompt_input "Hello world")

    local output
    local exit_code
    output=$(run_hook_with_exit_code "$HOOK_PATH" "$input") && exit_code=0 || exit_code=$?

    assert_exit_code 0 $exit_code "Hook should succeed on valid input"
}

# Test 3: Hook handles empty input gracefully
test_hook_empty_input() {
    local output
    local exit_code
    output=$(run_hook_with_exit_code "$HOOK_PATH" "") && exit_code=0 || exit_code=$?

    # Should exit 0 (gracefully skip) or produce valid output
    assert_true "1" "Hook should handle empty input"
}

# Test 4: Hook produces expected output format
test_hook_output_format() {
    local input
    input=$(mock_prompt_input "test prompt")

    local output
    output=$(run_hook "$HOOK_PATH" "$input")

    # Verify JSON output structure if expected
    # assert_contains "hookSpecificOutput" "$output" "Output should be JSON"
}

# ============================================================================
# RUN TESTS
# ============================================================================

test_hook_exists
test_hook_valid_input
test_hook_empty_input
test_hook_output_format

# ============================================================================
# CLEANUP
# ============================================================================

test_teardown
```

## Test Categories for Hooks

### 1. Existence Tests
Verify the hook file exists and is properly configured.

```bash
test_hook_exists() {
    assert_file_exists "$HOOK_PATH" "Hook file exists"
}
```

### 2. Valid Input Tests
Verify the hook processes valid input correctly.

```bash
test_valid_input() {
    local input=$(mock_tool_input "Write" '{"file_path": "/test.txt"}')
    local output=$(run_hook "$HOOK_PATH" "$input")
    assert_exit_code 0 $? "Hook should succeed"
}
```

### 3. Invalid Input Tests
Verify the hook handles malformed input gracefully.

```bash
test_invalid_input() {
    local output=$(run_hook "$HOOK_PATH" "not valid json")
    # Should not crash
    assert_true "1" "Hook should handle invalid input"
}
```

### 4. Decision Tests (for PreToolUse hooks)
Verify hooks make correct block/allow decisions.

```bash
test_block_decision() {
    local input=$(mock_tool_input "Write" '{"file_path": "/.env"}')
    local output=$(run_hook "$HOOK_PATH" "$input")
    assert_contains "block" "$output" "Should block .env writes"
}
```

### 5. Context Injection Tests (for SessionStart hooks)
Verify hooks inject proper context.

```bash
test_context_injection() {
    local input=$(mock_session_start)
    local output=$(run_hook "$HOOK_PATH" "$input")
    assert_contains "additionalContext" "$output" "Should inject context"
}
```

## Mock Input Helpers

### PreToolUse Input

```bash
# Generate mock tool input
local input=$(mock_tool_input "Write" '{"file_path": "/test.txt", "content": "hello"}')
```

### UserPromptSubmit Input

```bash
# Generate mock prompt input
local input=$(mock_prompt_input "Implement a feature")
```

### SessionStart Input

```bash
# Generate mock session start
local input=$(mock_session_start "/path/to/project")
```

## Running Hook Tests

```bash
# Run all hook tests
../test-jarvis.sh hooks

# Run specific hook test
../test-jarvis.sh hook:session-start

# Run from project root
./tests/jarvis/test-jarvis.sh hooks
```

## Hook Output Formats

### Block Decision (PreToolUse)

```json
{"decision": "block", "reason": "Reason for blocking"}
```

### Allow (no output or empty)

```
(no output means allow)
```

### Context Injection (SessionStart)

```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Context string to inject"
  }
}
```

## Best Practices

1. **Test the happy path first** - Valid input, expected behavior

2. **Test edge cases** - Empty input, malformed JSON, missing fields

3. **Test isolation** - Each test should be independent

4. **Mock external dependencies** - Don't rely on actual files/git state

5. **Verify both output and exit code** - Hooks communicate via both

6. **Test timing** - Hooks should complete quickly (< 1 second)

7. **Clean up** - Remove any temp files/state created during tests
