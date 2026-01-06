# Testing Jarvis Itself

> Part of the [Jarvis Specification](./README.md)

## 17. Testing Jarvis Itself

### 17.1 Philosophy: TDD for the System

Just as we enforce TDD for code, Jarvis components (skills, hooks, agents, rules) must be tested before deployment. This ensures:

1. **Skills work as intended** under various conditions
2. **Hooks don't break workflows** when edge cases occur
3. **Agents produce consistent quality** across different prompts
4. **Rules don't create false positives** that annoy users

### 17.2 Test Categories

| Category | What It Tests | How |
|----------|---------------|-----|
| **Baseline** | Behavior WITHOUT the component | Run scenario, capture behavior |
| **Activation** | Component triggers correctly | Verify keywords/conditions work |
| **Effectiveness** | Component improves outcome | Compare baseline vs with-component |
| **Edge Cases** | Unusual inputs/conditions | Test boundary conditions |
| **Regression** | Existing behavior preserved | Run against known-good outputs |

### 17.3 Skill Testing Framework

```
tests/skills/
├── test-skill.sh                 # Test runner script
├── scenarios/
│   ├── skill-name/
│   │   ├── baseline.md           # Expected behavior WITHOUT skill
│   │   ├── with-skill.md         # Expected behavior WITH skill
│   │   ├── prompts/
│   │   │   ├── trigger-1.txt     # Prompt that should trigger skill
│   │   │   ├── trigger-2.txt     # Another triggering prompt
│   │   │   └── no-trigger.txt    # Prompt that should NOT trigger
│   │   └── expected/
│   │       ├── trigger-1.txt     # Expected output for trigger-1
│   │       └── trigger-2.txt     # Expected output for trigger-2
```

### 17.4 Skill Test Process (RED-GREEN-REFACTOR)

```markdown
## RED: Baseline Test
1. Run prompt WITHOUT skill loaded
2. Capture output
3. Identify deficiencies (what the skill should fix)

## GREEN: Skill Test
1. Run same prompt WITH skill loaded
2. Capture output
3. Verify deficiencies are addressed
4. Verify no regressions

## REFACTOR: Bulletproofing
1. Test edge cases (malformed input, missing context)
2. Test pressure scenarios (time pressure, conflicting guidance)
3. Close loopholes in skill wording
4. Document rationalizations and counter them
```

### 17.5 Hook Testing Framework

```bash
#!/bin/bash
# tests/hooks/test-hook.sh

HOOK="$1"
TEST_INPUT="$2"
EXPECTED_OUTPUT="$3"

# Run hook with test input
ACTUAL=$(echo "$TEST_INPUT" | "$HOOK")
EXIT_CODE=$?

# Compare
if [ "$ACTUAL" = "$EXPECTED_OUTPUT" ]; then
  echo "✅ PASS: $HOOK"
else
  echo "❌ FAIL: $HOOK"
  echo "Expected: $EXPECTED_OUTPUT"
  echo "Actual: $ACTUAL"
  exit 1
fi
```

### 17.6 Agent Testing

Agents are tested by:

1. **Input/Output Pairs**: Known prompts with expected outputs
2. **Quality Scoring**: Review output against rubric
3. **Consistency**: Same prompt produces similar quality across runs
4. **Boundary Testing**: Test with minimal context, maximum context

```markdown
# Agent Test: code-reviewer

## Test Case: Simple Bug Detection
Input: [code with obvious null pointer bug]
Expected: Agent identifies the bug with high confidence

## Test Case: No Issues
Input: [clean, well-written code]
Expected: Agent confirms code is good, no false positives

## Test Case: Conflicting Rules
Input: [code that violates style but not quality]
Expected: Agent prioritizes correctly (quality > style)
```

### 17.7 Rule Testing

Rules are tested for:

1. **True Positives**: Correctly identifies violations
2. **True Negatives**: Correctly allows valid code
3. **False Positive Rate**: <5% acceptable
4. **Confidence Calibration**: 80% confidence = correct 80% of time

### 17.8 Testing Strategy (Local-First)

Since this is a personal project (potentially open-sourced later), we use a **local-first testing approach** that costs nothing:

#### 17.8.1 Testing Approaches by Cost

| Approach | Cost | When to Use |
|----------|------|-------------|
| **During creation (TDD)** | Free | Always - test as you build |
| **Manual command** | Free | On-demand validation |
| **Pre-push git hook** | Free | Before pushing changes |
| **GitHub Actions** | $$ | Only if open-sourced |

#### 17.8.2 Primary: Test During Creation

The TDD approach means testing happens WHILE creating components:

```markdown
# Creating a new skill

1. Write the skill trigger test FIRST
   → Does prompt "X" trigger this skill?

2. Write the effectiveness test
   → Does the skill improve the output?

3. Write the skill content
   → Iterate until tests pass

4. Add to skill-rules.json
   → Skill is now live
```

#### 17.8.3 The `/jarvis test` Command

```markdown
# /jarvis test

Run Jarvis system tests locally.

## Usage
/jarvis test                    # Run all tests
/jarvis test skills             # Test all skills
/jarvis test hooks              # Test all hooks
/jarvis test skill:git-expert   # Test specific skill
/jarvis test --changed          # Test only changed components

## What It Does
1. Discovers all test scenarios in tests/jarvis/
2. Runs each test in isolated context
3. Reports pass/fail with details
4. Suggests fixes for failures
```

#### 17.8.4 Pre-Push Git Hook (Optional)

```bash
#!/bin/bash
# .husky/pre-push (or .git/hooks/pre-push)

# Only run if .claude/ files changed
CHANGED=$(git diff --name-only HEAD~1 | grep "^\.claude/")

if [ -n "$CHANGED" ]; then
  echo "🧪 Running Jarvis tests for changed components..."

  # Run quick tests only (< 30 seconds)
  ~/.claude/scripts/test-changed.sh "$CHANGED"

  if [ $? -ne 0 ]; then
    echo "❌ Jarvis tests failed. Push aborted."
    echo "Run '/jarvis test' for details."
    exit 1
  fi

  echo "✅ Jarvis tests passed."
fi
```

#### 17.8.5 Test Runner Script

```bash
#!/bin/bash
# ~/.claude/scripts/test-jarvis.sh

MODE="${1:-all}"
COMPONENT="${2:-}"

case "$MODE" in
  "skills")
    for skill_dir in ~/.claude/skills/*/; do
      test_skill "$skill_dir"
    done
    ;;
  "hooks")
    for hook in ~/.claude/hooks/*.sh; do
      test_hook "$hook"
    done
    ;;
  "skill:"*)
    skill_name="${MODE#skill:}"
    test_skill "~/.claude/skills/$skill_name"
    ;;
  "changed")
    # Test only files passed as argument
    for file in $COMPONENT; do
      test_component "$file"
    done
    ;;
  *)
    # Run all tests
    $0 skills
    $0 hooks
    ;;
esac
```

#### 17.8.6 Future: GitHub Actions (If Open-Sourced)

If/when the project is open-sourced, add CI:

```yaml
# Only enable when repo is public (free for public repos)
name: Jarvis Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/test-jarvis.sh all
```
