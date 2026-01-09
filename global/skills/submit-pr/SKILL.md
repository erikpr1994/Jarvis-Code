---
name: submit-pr
description: |
  Complete PR submission pipeline with local sub-agent review before pushing, CI verification, and automated review integration. Dispatches specialized review agents (security, performance, dependency) before code leaves the machine. Waits for CI with `gh pr checks --watch`. Integrates CodeRabbit and Greptile feedback.
---

# Submit PR

## Overview

Orchestrates the full PR lifecycle: pre-submit verification → local sub-agent review → push → CI verification → automated review feedback → human review request. Catches issues at the earliest possible stage.

## When to Use

**Invoke this skill when:**
- Feature implementation is complete and ready for review
- Bug fix is tested and ready to merge
- Creating your first PR in a new repository
- Unsure about PR description format or best practices
- Need comprehensive pre-push quality checks
- Preparing stacked PRs with Graphite

**Do NOT use when:**
- Work is still in progress (use draft PR instead)
- Tests are failing (fix tests first)
- You haven't rebased on main recently
- Changes include sensitive data or secrets

## Quick Reference

| Phase | Actions |
|-------|---------|
| **1. Pre-Submit** | Local tests, lint, typecheck, diff review |
| **2. Sub-Agent Review** | Dispatch security/performance/structure reviewers |
| **3. Address Findings** | Fix issues found by sub-agents |
| **4. Push & Create PR** | Branch push, description, labels |
| **5. CI Verification** | Wait for CI with `gh pr checks --watch` |
| **6. Automated Review** | Read CodeRabbit/Greptile feedback |
| **7. Final Fixes** | Address any remaining feedback |

---

## Phase 1: Pre-Submit Checklist

**MANDATORY before proceeding:**

```bash
# 1. Verify all tests pass
npm test

# 2. Run linter
npm run lint

# 3. Type check
npm run typecheck

# 4. Review your changes
git diff main...HEAD --stat

# 5. Check for secrets/sensitive data
git diff main...HEAD | grep -E "(password|secret|api_key|token)" || echo "Clean"

# 6. Verify branch is up to date
git fetch origin main
git rebase origin/main
```

**Do NOT proceed if any check fails.**

---

## Phase 2: Local Sub-Agent Review

**BEFORE pushing**, dispatch specialized review agents to catch issues early.

### Determine Which Agents to Dispatch

Analyze changes to select appropriate reviewers:

```bash
# Get changed files for analysis
git diff main...HEAD --stat
git diff main...HEAD --name-only
```

| Change Type | Dispatch Agent |
|-------------|----------------|
| Auth/security code | `security-reviewer` |
| Database queries, loops, rendering | `performance-reviewer` |
| package.json/lock files | `dependency-reviewer` |
| New files, reorganization | `structure-reviewer` |
| Complex PR (10+ files) | `code-reviewer` (comprehensive) |

### Dispatch Review Agents in Parallel

Use the Task tool to run specialized reviewers simultaneously:

```markdown
Task: @security-reviewer
Review changes for security vulnerabilities.
Run: git diff main...HEAD
Focus: authentication, authorization, input validation, data exposure, XSS, injection.

---

Task: @performance-reviewer
Analyze performance implications of changes.
Run: git diff main...HEAD
Focus: query efficiency, N+1 problems, rendering, bundle size, memory leaks.

---

Task: @dependency-reviewer
Review dependency changes (if package.json modified).
Check: known vulnerabilities, license compatibility, maintenance status.
```

### Aggregate Sub-Agent Results

Collect and assess findings:

```markdown
## Local Review Summary

### Security Review: [PASS/WARN/FAIL]
- Critical: [count]
- Warnings: [count]
- [Key findings]

### Performance Review: [PASS/WARN/FAIL]
- Critical: [count]
- Warnings: [count]
- [Key findings]

### Dependency Review: [PASS/WARN/FAIL]
- Vulnerabilities: [count]
- [Key findings]

### Overall: [READY TO PUSH / NEEDS FIXES]
```

---

## Phase 3: Address Sub-Agent Findings

**If any sub-agent reports FAIL or critical issues:**

1. Fix the identified issues
2. Re-run affected tests
3. Re-dispatch the sub-agent that found issues
4. Verify PASS before proceeding

**Do NOT push with unresolved critical findings.**

---

## Phase 4: Push & Create PR

Only after local sub-agent review passes:

### Push Branch

For pushes with pre-push hooks, use background execution with TaskOutput:

```typescript
// Start push in background (hooks may run tests)
Bash("CLAUDE_SUBMIT_PR_SKILL=1 git push -u origin feature/my-feature", run_in_background: true)
// → task_id: "push_123"

// Wait for push + hooks to complete (up to 3 min)
TaskOutput(task_id: "push_123", block: true, timeout: 180000)
// → Returns push result
```

**See `background-tasks` skill for efficient waiting patterns.**

For quick pushes without hooks:
```bash
# Direct push (no pre-push hooks)
CLAUDE_SUBMIT_PR_SKILL=1 git push -u origin feature/my-feature
```

### Create PR

```bash
CLAUDE_SUBMIT_PR_SKILL=1 gh pr create --title "feat: add feature" --body "$(cat <<'EOF'
## Summary
- [What changed and why]

## Test Plan
- [ ] Unit tests added/updated
- [ ] Integration tests pass

## Local Review
- [x] Security review passed
- [x] Performance review passed
- [x] Tests pass locally

Closes #[issue]
EOF
)"

# Capture PR number
PR_NUMBER=$(gh pr view --json number -q '.number')
echo "Created PR #$PR_NUMBER"
```

---

## Phase 5: CI Verification

**Wait for CI checks to complete:**

```bash
# Watch CI checks until completion (blocks until done)
gh pr checks $PR_NUMBER --watch
```

| CI Status | Action |
|-----------|--------|
| All pass | Proceed to Phase 6 |
| Tests fail | Fix, push, re-watch |
| Lint/Type errors | Fix, push, re-watch |

---

## Phase 6: Automated Review Feedback

Read feedback from CodeRabbit, Greptile, and other automated reviewers:

```bash
# View all comments
gh pr view $PR_NUMBER --comments

# Check review status
gh pr view $PR_NUMBER --json reviewDecision -q '.reviewDecision'
```

### Addressing Automated Feedback

1. Review each comment for actionable items
2. Fix issues in code
3. Commit and push fixes
4. Re-run `gh pr checks --watch`
5. Verify automated reviewers are satisfied

---

## Phase 7: Request Human Review

Only after all automated checks pass:

```bash
# Request specific reviewers
gh pr edit $PR_NUMBER --add-reviewer reviewer1,reviewer2

# Or request team review
gh pr edit $PR_NUMBER --add-reviewer org/team-name
```

---

## PR Description Template

```markdown
## Summary
[1-3 bullet points describing what changed and why]

## Changes
- [Specific change 1]
- [Specific change 2]
- [Specific change 3]

## Test Plan
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Edge cases covered

## Screenshots
[If UI changes, include before/after]

## Related
- Closes #[issue_number]
- Related to #[related_issue]
```

---


## Common Patterns

### Draft PR (Work in Progress)

```bash
gh pr create --draft --title "WIP: feature implementation"
```

### Ready for Review

```bash
gh pr ready
```

### Stacked PRs with Graphite

```bash
# Submit entire stack
CLAUDE_SUBMIT_PR_SKILL=1 gt stack submit

# View stack status
gt log
```

### Quick PR (Skip Optional Sub-Agents)

For small, low-risk changes, you may skip optional sub-agents:

```bash
# Minimum required: security-reviewer for any code changes
# Skip: performance-reviewer, dependency-reviewer, structure-reviewer
```

---

## Decision Tree

```
Phase 1: Pre-Submit Checks Pass?
├── NO → Fix issues, re-run checks
└── YES → Phase 2: Dispatch Sub-Agents
           ↓
      Phase 2: Sub-Agent Review Complete?
      ├── Any FAIL? → Phase 3: Fix issues, re-dispatch
      └── All PASS? → Phase 4: Push & Create PR
                      ↓
                 Phase 5: CI Passes?
                 ├── NO → Fix, push, re-watch
                 └── YES → Phase 6: Read Automated Feedback
                           ↓
                      Issues Found?
                      ├── YES → Fix, push, verify
                      └── NO → Phase 7: Request Human Review
```

---

## Red Flags - STOP

**Do NOT push when:**
- Tests are failing
- Linter errors exist
- Type errors present
- Secrets in diff
- Sub-agent reports FAIL or critical issues
- Incomplete implementation without draft flag

**Do NOT:**
- Skip pre-submit checklist
- Skip local sub-agent review
- Push with unresolved critical findings
- Create PR without description
- Ignore CodeRabbit/Greptile feedback
- Force merge without approval

---

## Verification Checklist

### Before Dispatching Sub-Agents (Phase 1)
- [ ] All tests pass locally
- [ ] Linter clean
- [ ] Type check passes
- [ ] No secrets in diff
- [ ] Branch rebased on main

### Before Pushing (Phase 3)
- [ ] Sub-agent reviews complete
- [ ] No critical findings unresolved
- [ ] All WARN items assessed

### Before Requesting Human Review (Phase 7)
- [ ] CI pipeline green (`gh pr checks --watch`)
- [ ] Automated review feedback addressed
- [ ] PR description complete
- [ ] No merge conflicts
- [ ] Self-review completed

---

## Integration

**Parent skill:** git-expert
**Related skills:** coderabbit, tdd, verification, dispatching-parallel-agents, multi-agent-patterns, background-tasks

**Review sub-agents (Phase 2):**
- `security-reviewer` - XSS, injection, auth vulnerabilities
- `performance-reviewer` - Queries, rendering, bundle size
- `dependency-reviewer` - Vulnerabilities, licenses, maintenance
- `structure-reviewer` - File organization, patterns
- `code-reviewer` - Comprehensive multi-file review
- `test-coverage-analyzer` - Test adequacy and gaps

**Architecture note:** Uses supervisor pattern from multi-agent-patterns. Sub-agents provide context isolation - each reviewer operates in a clean context focused on its domain. Results aggregate without any single context bearing the full burden.

---

## Metadata

**Version:** 2.0.0
**Last Updated:** 2026-01-08
