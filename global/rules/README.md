# Rules

Global behavior rules applied across all projects.

## Structure

```
rules/
├── iron-law-tdd.md         # TDD is mandatory
├── verification-required.md # Must verify before completion
├── no-direct-submit.md     # Must use submit-pr skill
└── isolation-required.md   # Must use worktree/Conductor
```

## Rule Format

Each rule is defined in a markdown file:

```markdown
---
id: rule-id
name: Rule Name
severity: error|warning|info
enforcement: strict|flexible
---

# Rule Name

## Description
What this rule enforces and why.

## Applies To
- When this rule applies
- Specific contexts or actions

## Requirements
1. Specific requirement
2. Another requirement

## Exceptions
- When this rule can be bypassed
- How to request an exception

## Rationale
Why this rule exists and its benefits.
```

## Rule Severity

- **error** - Blocks action, must be resolved
- **warning** - Allows action with caution
- **info** - Informational guidance

## Enforcement

- **strict** - No exceptions, always enforced
- **flexible** - Can be overridden with justification

## Core Rules

### Iron Law of TDD
All code changes must have tests written first.

### Verification Required
Must pass all verification steps before completion.

### No Direct Submit
Must use submit-pr skill for all PR submissions.

### Isolation Required
Must work in worktree or use Conductor for changes.

## Project Overrides

Projects can override global rules in their `.claude/rules/` directory.
Project rules take precedence over global rules.
