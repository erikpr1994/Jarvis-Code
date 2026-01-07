---
name: jarvis-test
description: Run Jarvis system tests
aliases: [jtest, test-jarvis]
---

# /jarvis test

Run Jarvis system tests locally.

## Description

Execute the Jarvis testing framework to validate skills, hooks, agents, and rules. Tests are run in isolated environments and report pass/fail with colors.

## Usage

```bash
/jarvis test                    # Run all tests
/jarvis test skills             # Test all skills
/jarvis test hooks              # Test all hooks
/jarvis test skill:git-expert   # Test specific skill
/jarvis test hook:session-start # Test specific hook
/jarvis test --changed          # Test only changed components
```

## Options

| Option | Description |
|--------|-------------|
| `skills` | Test all skill components |
| `hooks` | Test all hook components |
| `skill:<name>` | Test a specific skill by name |
| `hook:<name>` | Test a specific hook by name |
| `--changed` | Only test components changed since last commit |
| `all` | Run all tests (default) |

## What It Does

1. Discovers all test scenarios in `tests/jarvis/`
2. Runs each test in an isolated context
3. Reports pass/fail with details and colors
4. Returns appropriate exit codes

## Test Categories

| Category | What It Tests |
|----------|---------------|
| **Baseline** | Behavior WITHOUT the component |
| **Activation** | Component triggers correctly |
| **Effectiveness** | Component improves outcome |
| **Edge Cases** | Unusual inputs/conditions |

## Examples

### Run All Tests
```
/jarvis test
```

### Test Specific Skill
```
/jarvis test skill:test-driven-development
```

### Test Hooks Only
```
/jarvis test hooks
```

### Test Changed Components
```
/jarvis test --changed
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All tests passed |
| 1 | One or more tests failed |

## Implementation

When this command is invoked, execute:

```bash
# From project root
./tests/jarvis/test-jarvis.sh [args]

# Or with full path
~/.config/jarvis/tests/jarvis/test-jarvis.sh [args]
```

## TDD Workflow

Use this command during skill/hook development:

1. **Write Test First**: Create test in `tests/jarvis/skills/` or `tests/jarvis/hooks/`
2. **Run Test (RED)**: `/jarvis test skill:my-new-skill` - should fail
3. **Implement**: Write the skill/hook
4. **Run Test (GREEN)**: Test should pass
5. **Refactor**: Improve code, tests still pass

## Related Commands

- `/jarvis skills` - List available skills
- `/jarvis status` - Show current session status
- `/jarvis-init` - Initialize Jarvis in a project

## File Location

Test framework: `tests/jarvis/`

```
tests/jarvis/
├── test-jarvis.sh       # Main test runner
├── lib/
│   └── test-helpers.sh  # Shared utilities
├── skills/              # Skill tests
├── hooks/               # Hook tests
└── scenarios/           # Scenario-based tests
```
