# Jarvis Testing Framework

Test infrastructure for validating Jarvis components (skills, hooks, agents, rules).

## Philosophy: TDD for the System

Just as we enforce TDD for code, Jarvis components must be tested before deployment. This ensures:

1. **Skills work as intended** under various conditions
2. **Hooks don't break workflows** when edge cases occur
3. **Agents produce consistent quality** across different prompts
4. **Rules don't create false positives** that annoy users

## Directory Structure

```
tests/jarvis/
├── README.md                 # This file
├── test-jarvis.sh            # Main test runner
├── lib/
│   └── test-helpers.sh       # Shared test utilities
├── skills/
│   ├── README.md             # How to add skill tests
│   └── test-*.sh             # Individual skill tests
├── hooks/
│   ├── README.md             # How to add hook tests
│   └── test-*.sh             # Individual hook tests
└── scenarios/
    ├── README.md             # Scenario format documentation
    └── <skill-name>/         # Scenario-based skill tests
        ├── baseline.md       # Expected behavior WITHOUT skill
        ├── with-skill.md     # Expected behavior WITH skill
        ├── prompts/
        │   ├── trigger-1.txt # Prompt that should trigger skill
        │   └── no-trigger.txt# Prompt that should NOT trigger
        └── expected/
            └── trigger-1.txt # Expected output for trigger-1
```

## Usage

### Run All Tests

```bash
./test-jarvis.sh
# or
./test-jarvis.sh all
```

### Run Category Tests

```bash
./test-jarvis.sh skills    # Test all skills
./test-jarvis.sh hooks     # Test all hooks
```

### Run Specific Component Test

```bash
./test-jarvis.sh skill:git-expert       # Test specific skill
./test-jarvis.sh hook:session-start     # Test specific hook
```

### Run Only Changed Components

```bash
./test-jarvis.sh --changed              # Test only changed components (git-based)
```

## Test Categories

| Category | What It Tests | How |
|----------|---------------|-----|
| **Baseline** | Behavior WITHOUT the component | Run scenario, capture behavior |
| **Activation** | Component triggers correctly | Verify keywords/conditions work |
| **Effectiveness** | Component improves outcome | Compare baseline vs with-component |
| **Edge Cases** | Unusual inputs/conditions | Test boundary conditions |
| **Regression** | Existing behavior preserved | Run against known-good outputs |

## RED-GREEN-REFACTOR Pattern

### RED: Baseline Test
1. Run prompt WITHOUT skill loaded
2. Capture output
3. Identify deficiencies (what the skill should fix)

### GREEN: Skill Test
1. Run same prompt WITH skill loaded
2. Capture output
3. Verify deficiencies are addressed
4. Verify no regressions

### REFACTOR: Bulletproofing
1. Test edge cases (malformed input, missing context)
2. Test pressure scenarios (time pressure, conflicting guidance)
3. Close loopholes in skill wording
4. Document rationalizations and counter them

## Writing Tests

### Test File Naming

- Hook tests: `hooks/test-<hook-name>.sh`
- Skill tests: `skills/test-<skill-name>.sh`
- Scenarios: `scenarios/<skill-name>/`

### Using Test Helpers

```bash
#!/usr/bin/env bash
source "${LIB_DIR}/test-helpers.sh"

test_setup

# Your test logic here
assert_equals "expected" "actual" "Description"
assert_contains "substring" "$output" "Description"
assert_file_exists "/path/to/file" "Description"

test_teardown
```

### Available Assertions

| Function | Description |
|----------|-------------|
| `assert_equals` | Compare expected vs actual |
| `assert_contains` | Check substring exists |
| `assert_not_contains` | Check substring does NOT exist |
| `assert_file_exists` | Check file exists |
| `assert_file_not_exists` | Check file does NOT exist |
| `assert_dir_exists` | Check directory exists |
| `assert_exit_code` | Check exit code |
| `assert_true` | Check truthy value |
| `assert_false` | Check falsy value |
| `assert_json_contains` | Check JSON key-value pair |

### Hook Testing Helpers

| Function | Description |
|----------|-------------|
| `run_hook` | Execute hook with test input |
| `run_hook_with_exit_code` | Execute hook and capture exit code |
| `mock_tool_input` | Generate PreToolUse input JSON |
| `mock_prompt_input` | Generate UserPromptSubmit input JSON |
| `mock_session_start` | Generate SessionStart input JSON |

### Skill Testing Helpers

| Function | Description |
|----------|-------------|
| `skill_exists` | Check if skill file exists |
| `get_skill_path` | Get path to skill file |
| `prompt_triggers_skill` | Check if prompt would trigger skill |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All tests passed |
| 1 | One or more tests failed |
| 2 | Test infrastructure error |

## Integration with Development

### During Development (TDD)

Test as you build:

```markdown
1. Write the skill trigger test FIRST
   -> Does prompt "X" trigger this skill?

2. Write the effectiveness test
   -> Does the skill improve the output?

3. Write the skill content
   -> Iterate until tests pass

4. Add to skill-rules.json
   -> Skill is now live
```

### Pre-Push Validation (Optional)

Add to `.git/hooks/pre-push`:

```bash
#!/bin/bash
CHANGED=$(git diff --name-only HEAD~1 | grep "^\.claude/\|^global/")

if [ -n "$CHANGED" ]; then
  echo "Running Jarvis tests for changed components..."
  ./tests/jarvis/test-jarvis.sh --changed "$CHANGED"

  if [ $? -ne 0 ]; then
    echo "Tests failed. Push aborted."
    exit 1
  fi
fi
```

### Via Command

```bash
/jarvis test                    # Run all tests
/jarvis test skills             # Test all skills
/jarvis test hooks              # Test all hooks
/jarvis test skill:git-expert   # Test specific skill
```
