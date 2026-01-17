# Skill Tests

This directory contains tests for Jarvis skills.

## Test File Naming

All skill test files should follow the naming convention:

```
test-<skill-name>.sh
```

For example:
- `test-git-expert.sh`
- `test-debug.sh`
- `test-test-driven-development.sh`

## Writing a Skill Test

### Basic Template

```bash
#!/usr/bin/env bash
# Test: <skill-name>
# Purpose: Verify <skill-name> skill triggers and behaves correctly

set -euo pipefail

# Get test framework directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

# Source test helpers
source "${LIB_DIR}/test-helpers.sh"

# ============================================================================
# SETUP
# ============================================================================

test_setup

SKILL_NAME="<skill-name>"

# ============================================================================
# TESTS
# ============================================================================

# Test 1: Skill file exists
test_skill_exists() {
    if skill_exists "$SKILL_NAME"; then
        assert_true "1" "Skill file exists"
    else
        assert_true "" "Skill file should exist"
    fi
}

# Test 2: Trigger prompts activate skill
test_trigger_prompts() {
    local trigger_prompts=(
        "keyword1 in a sentence"
        "another keyword2 prompt"
    )

    for prompt in "${trigger_prompts[@]}"; do
        if prompt_triggers_skill "$prompt" "$SKILL_NAME"; then
            assert_true "1" "Prompt should trigger: $prompt"
        else
            assert_true "" "Prompt should trigger: $prompt"
        fi
    done
}

# Test 3: Non-trigger prompts do NOT activate skill
test_non_trigger_prompts() {
    local non_trigger_prompts=(
        "unrelated request"
        "something else entirely"
    )

    for prompt in "${non_trigger_prompts[@]}"; do
        if ! prompt_triggers_skill "$prompt" "$SKILL_NAME"; then
            assert_true "1" "Prompt should NOT trigger: $prompt"
        else
            assert_true "" "Prompt should NOT trigger: $prompt"
        fi
    done
}

# ============================================================================
# RUN TESTS
# ============================================================================

test_skill_exists
test_trigger_prompts
test_non_trigger_prompts

# ============================================================================
# CLEANUP
# ============================================================================

test_teardown
```

## Test Categories for Skills

### 1. Existence Tests
Verify the skill file exists and is properly formatted.

```bash
test_skill_exists() {
    assert_file_exists "$(get_skill_path "$SKILL_NAME")" "Skill file exists"
}
```

### 2. Trigger Tests
Verify the skill is triggered by appropriate prompts.

```bash
test_trigger_prompts() {
    assert_true "$(prompt_triggers_skill 'debug this error' 'debug')" \
        "Debug prompts trigger debugging skill"
}
```

### 3. Non-Trigger Tests (False Positive Prevention)
Verify the skill is NOT triggered by unrelated prompts.

```bash
test_non_trigger_prompts() {
    assert_false "$(prompt_triggers_skill 'hello world' 'debug')" \
        "Generic prompts should not trigger debugging skill"
}
```

### 4. Priority Tests
Verify skills are prioritized correctly when multiple match.

```bash
test_priority() {
    # Test that critical skills take precedence
    local prompt="implement a feature with tests"
    # test-driven-development (critical) should rank higher than session
}
```

## Scenario-Based Testing

For more complex skill testing, use the `scenarios/` directory. See `../scenarios/README.md` for details.

## Running Skill Tests

```bash
# Run all skill tests
../test-jarvis.sh skills

# Run specific skill test
../test-jarvis.sh skill:git-expert

# Run from project root
./tests/jarvis/test-jarvis.sh skills
```

## Best Practices

1. **Test both positive and negative cases** - Ensure skills trigger when they should AND don't trigger when they shouldn't

2. **Use realistic prompts** - Test with prompts that users would actually type

3. **Test edge cases** - Single word, very long prompts, special characters

4. **Test keyword variations** - "test", "tests", "testing", "TDD"

5. **Document test purpose** - Each test should have clear description

6. **Keep tests independent** - Each test should not depend on others
