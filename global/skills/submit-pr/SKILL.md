---
name: submit-pr
description: Use when submitting pull requests. Covers pre-submit checklist, PR description, CodeRabbit integration, and review request process.
---

# Submit PR

## Overview

Complete PR submission pipeline from pre-submit verification through review request. Sub-skill of git-expert focused specifically on the PR creation and review workflow.

## When to Use

**Invoke this skill when:**
- Feature implementation is complete and ready for review
- Bug fix is tested and ready to merge
- Creating your first PR in a new repository
- Unsure about PR description format or best practices
- Need to set up CodeRabbit review integration
- Preparing stacked PRs with Graphite

**Do NOT use when:**
- Work is still in progress (use draft PR instead)
- Tests are failing (fix tests first)
- You haven't rebased on main recently
- Changes include sensitive data or secrets

## Quick Reference

| Phase | Actions |
|-------|---------|
| **Pre-Submit** | Tests, lint, typecheck, diff review |
| **PR Creation** | Branch push, description, labels |
| **Review** | CodeRabbit, team reviewers, comments |
| **Post-Review** | Address feedback, re-request review |

---

## Pre-Submit Checklist

**MANDATORY before creating PR:**

```bash
# 1. Verify all tests pass
npm test

# 2. Run linter
npm run lint

# 3. Type check
npm run typecheck

# 4. Review your changes
git diff main...HEAD

# 5. Check for secrets/sensitive data
git diff main...HEAD | grep -E "(password|secret|api_key|token)" || echo "Clean"

# 6. Verify branch is up to date
git fetch origin main
git rebase origin/main
```

**Do NOT proceed if any check fails.**

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

## PR Creation Process

### Step 1: Push Branch

```bash
# Push with upstream tracking
git push -u origin feature/my-feature
```

### Step 2: Create PR

```bash
gh pr create --title "feat: add user authentication" --body "$(cat <<'EOF'
## Summary
- Implement JWT-based authentication
- Add login/logout endpoints
- Include session management

## Test Plan
- [ ] Unit tests for auth logic
- [ ] Integration tests for endpoints
- [ ] Manual login/logout testing

Closes #42
EOF
)"
```

### Step 3: Add Labels (if applicable)

```bash
gh pr edit --add-label "feature,needs-review"
```

### Step 4: Request Review

```bash
# Request specific reviewer
gh pr edit --add-reviewer username

# Or request team review
gh pr edit --add-reviewer org/team-name
```

---

## CodeRabbit Integration

**Trigger CodeRabbit review:**
- CodeRabbit reviews automatically on PR creation (if configured)
- To re-trigger: push new commits or comment `@coderabbitai review`

**Addressing CodeRabbit feedback:**
1. Read each comment carefully
2. Address actionable items with code changes
3. Reply to explain non-obvious decisions
4. Mark conversations as resolved when addressed

See `coderabbit.md` skill for detailed CodeRabbit workflow.

---

## Review Request Process

### Requesting Human Review

```bash
# Check PR status
gh pr status

# Request specific reviewers
gh pr edit --add-reviewer reviewer1,reviewer2

# View pending reviews
gh pr view --json reviewRequests
```

### After Review Feedback

```bash
# 1. View review comments
gh pr view --comments

# 2. Make requested changes
# ... edit code ...

# 3. Commit fixes
git add .
git commit -m "fix: address review feedback"

# 4. Push updates
git push

# 5. Re-request review if needed
gh pr edit --add-reviewer original-reviewer
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
gt stack submit

# View stack status
gt log
```

---

## Red Flags - STOP

**Do NOT submit PR when:**
- Tests are failing
- Linter errors exist
- Type errors present
- Secrets in diff
- Incomplete implementation without draft flag

**Do NOT:**
- Skip pre-submit checklist
- Create PR without description
- Ignore CodeRabbit feedback
- Force merge without approval

---

## Verification Checklist

Before marking PR ready:
- [ ] All tests pass locally
- [ ] CI pipeline green
- [ ] PR description complete
- [ ] Relevant reviewers assigned
- [ ] No merge conflicts
- [ ] Self-review completed

---

## Integration

**Parent skill:** git-expert
**Related skills:** coderabbit, tdd-workflow, verification
