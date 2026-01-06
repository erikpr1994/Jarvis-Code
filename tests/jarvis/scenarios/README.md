# Scenario-Based Testing

This directory contains scenario-based tests for complex skill validation.

## What is Scenario Testing?

Scenario testing validates that a skill actually improves Claude's behavior by comparing:

1. **Baseline**: How Claude responds WITHOUT the skill
2. **With Skill**: How Claude responds WITH the skill
3. **Expected**: The improvement we expect to see

## Directory Structure

```
scenarios/
├── README.md                 # This file
└── <skill-name>/
    ├── baseline.md           # Expected behavior WITHOUT skill
    ├── with-skill.md         # Expected behavior WITH skill
    ├── prompts/
    │   ├── trigger-1.txt     # Prompt that should trigger skill
    │   ├── trigger-2.txt     # Another triggering prompt
    │   └── no-trigger.txt    # Prompt that should NOT trigger
    └── expected/
        ├── trigger-1.txt     # Expected output for trigger-1
        └── trigger-2.txt     # Expected output for trigger-2
```

## Creating a Scenario

### Step 1: Create Skill Directory

```bash
mkdir -p scenarios/<skill-name>/{prompts,expected}
```

### Step 2: Document Baseline Behavior

Create `baseline.md` describing how Claude behaves WITHOUT this skill:

```markdown
# Baseline: <skill-name>

## Scenario
When user asks to [specific task]...

## Observed Behavior (Without Skill)
- Claude does X
- Claude forgets to Y
- Claude doesn't consider Z

## Problems
1. [Problem this skill should fix]
2. [Another problem]
```

### Step 3: Document Expected Behavior

Create `with-skill.md` describing how Claude SHOULD behave WITH this skill:

```markdown
# With Skill: <skill-name>

## Scenario
When user asks to [specific task]...

## Expected Behavior (With Skill)
- Claude should do X correctly
- Claude should remember to Y
- Claude should consider Z

## Improvements
1. [How first problem is fixed]
2. [How second problem is fixed]
```

### Step 4: Create Test Prompts

Create prompt files in `prompts/`:

**trigger-1.txt** (should trigger the skill):
```
User prompt that should activate this skill
```

**no-trigger.txt** (should NOT trigger the skill):
```
User prompt that should NOT activate this skill
```

### Step 5: Create Expected Outputs (Optional)

Create expected output patterns in `expected/`:

**trigger-1.txt**:
```
Key phrases or patterns that should appear in output:
- Must mention X
- Should include Y
- Should NOT include Z
```

## Example: test-driven-development Skill

### Scenario Directory Structure

```
scenarios/test-driven-development/
├── baseline.md
├── with-skill.md
├── prompts/
│   ├── trigger-implement-feature.txt
│   ├── trigger-add-function.txt
│   └── no-trigger-documentation.txt
└── expected/
    ├── trigger-implement-feature.txt
    └── trigger-add-function.txt
```

### baseline.md

```markdown
# Baseline: test-driven-development

## Scenario
When user asks to implement a new feature...

## Observed Behavior (Without Skill)
- Claude jumps directly to writing implementation code
- Tests are written after (if at all)
- Claude may write code that's difficult to test
- No verification of requirements before coding

## Problems
1. Implementation may not match requirements
2. Tests become an afterthought
3. Code may have hidden bugs
4. Refactoring is risky without tests
```

### with-skill.md

```markdown
# With Skill: test-driven-development

## Scenario
When user asks to implement a new feature...

## Expected Behavior (With Skill)
- Claude first discusses requirements and edge cases
- Claude writes test(s) BEFORE implementation
- Claude runs tests to verify they fail (RED)
- Claude writes minimal code to pass tests (GREEN)
- Claude refactors with confidence (REFACTOR)

## Improvements
1. Requirements are validated through test cases
2. Tests serve as living documentation
3. Code is testable by design
4. Safe refactoring enabled
```

### prompts/trigger-implement-feature.txt

```
Implement a function that validates email addresses
```

### expected/trigger-implement-feature.txt

```
Expected output should include:
- Discussion of edge cases (empty string, special chars, etc.)
- Test code written BEFORE implementation
- Multiple test cases covering: valid emails, invalid emails, edge cases
- RED-GREEN-REFACTOR pattern mentioned or followed
```

## Running Scenario Tests

Scenario tests are automatically discovered and run by `test-jarvis.sh`:

```bash
# Run all tests including scenarios
./test-jarvis.sh skills

# Run specific skill scenario
./test-jarvis.sh skill:test-driven-development
```

## RED-GREEN-REFACTOR Pattern

Each scenario should follow the TDD pattern:

### RED Phase (Baseline)
1. Run the trigger prompt WITHOUT the skill
2. Capture the baseline behavior
3. Document what's missing or wrong

### GREEN Phase (With Skill)
1. Run the same prompt WITH the skill
2. Verify the problems are addressed
3. Ensure no regressions

### REFACTOR Phase (Edge Cases)
1. Test edge case prompts
2. Test conflicting scenarios
3. Verify skill doesn't over-trigger

## Scenario Validation

The test framework validates scenarios by checking:

1. **Required files exist**: `baseline.md`, `with-skill.md`
2. **Prompts directory has content**: At least one `trigger-*.txt` file
3. **Expected directory matches prompts**: Each trigger has corresponding expected output

## Best Practices

1. **Be specific in baselines** - Document concrete problems, not vague issues

2. **Use realistic prompts** - Test with prompts users would actually type

3. **Keep expected outputs flexible** - Use patterns, not exact matches

4. **Test edge cases** - Include no-trigger prompts to prevent false positives

5. **Update scenarios when skills change** - Keep documentation in sync

6. **Review baseline periodically** - Claude improves; baseline may become outdated
