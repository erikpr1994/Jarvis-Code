---
name: global-rules
category: critical
confidence: 0.9
description: Core rules that apply to ALL development work
---

# Global Rules

## Philosophy

> *"If something can be enforced by a tool, it shouldn't be in the prompt."*

Most rules are enforced by:
- **ESLint** → Type safety, code quality
- **Commitlint** → Commit format
- **Husky** → Pre-commit checks
- **Claude Code Hooks** → Git safety, PR workflow

See `templates/project-configs/` for project-level enforcement setup.

---

## Rules That Cannot Be Automated

These require human judgment and remain as guidance:

### 1. Test-Driven Development (TDD)

Write the test first. Watch it fail. Write minimal code to pass.

```
Write test → Watch it fail → Write minimal code → Watch it pass → Refactor
```

**Why this can't be automated:** Temporal order cannot be verified by static analysis.

**If you wrote code before the test:** Delete it. Start over. No exceptions.

### 2. Research Before Implementation

For complex tasks:
1. Classify complexity: Trivial, Moderate, Complex
2. Match effort to complexity
3. Gather context: Read relevant files, check existing patterns
4. Verify paths: Check 3+ examples before assuming import paths

**Why this can't be automated:** Complexity classification is subjective.

### 3. Ask Before Architectural Changes

- About to change a core abstraction? Ask first.
- About to modify a widely-used interface? Ask first.
- Can't explain why the code works? Ask first.

**Why this can't be automated:** Context-dependent judgment.

### 4. Explain WHY, Not Just WHAT

In commit bodies and comments, explain *why* you made the change, not just what you changed.

```bash
# BAD
git commit -m "fix: update validation logic"

# GOOD  
git commit -m "fix(auth): reject empty passwords

Previously, empty strings passed validation because we only
checked for null. This caused silent auth failures in production."
```

**Why this can't be automated:** Semantic content requires human judgment.

---

## Priority Order

When trade-offs arise:

```
Correctness > Maintainability > Performance > Brevity
```

---

## Red Flags - STOP and Ask

- Can't explain why code works
- "Just this once" rationalization
- Skipping TDD "because it's simple"
- Under time pressure (rushing guarantees rework)

---

## What's Enforced Elsewhere

| Rule | Enforcement |
|------|-------------|
| No destructive git commands | `git-safety-guard.sh` hook |
| PR workflow via skill | `block-direct-submit.sh` hook |
| Worktree isolation | `require-isolation.sh` hook |
| Conventional commits | commitlint (project) |
| No `any` types | ESLint (project) |
| No `@ts-ignore` without comment | ESLint (project) |
| Tests pass before commit | husky pre-commit (project) |
| Type check before commit | husky pre-commit (project) |
| Coverage > 80% | vitest thresholds (project) |
| Function < 30 lines | ESLint (project) |
| File < 300 lines | ESLint (project) |
| Complexity < 10 | ESLint (project) |

**Don't repeat these in prompts. They're already enforced.**
