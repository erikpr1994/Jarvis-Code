---
name: git-workflow
category: quality
confidence: 80
description: Git workflow rules for clean version control with Graphite and worktrees
---

# Git Workflow Rules

## Overview

A disciplined git workflow enables parallel development, clean history, and easy collaboration. This guide covers worktree-based isolation, conventional commits, and PR management.

## Worktree-Based Development

### Why Worktrees?

Git worktrees create isolated workspaces sharing the same repository:

- Work on multiple features simultaneously
- No branch switching disrupts work in progress
- Each worktree has its own working directory
- All share the same git history

### Directory Selection

Follow this priority order:

```bash
# 1. Check existing directories
ls -d .worktrees 2>/dev/null     # Preferred (hidden)
ls -d worktrees 2>/dev/null      # Alternative

# 2. Check CLAUDE.md for preference
grep -i "worktree.*director" CLAUDE.md 2>/dev/null

# 3. Ask user if no preference found
```

### Creating a Worktree

```bash
# Verify directory is gitignored
git check-ignore -q .worktrees || echo ".worktrees" >> .gitignore && git add .gitignore && git commit -m "chore: add .worktrees to gitignore"

# Create worktree with new branch
git worktree add .worktrees/feature-name -b feature/feature-name

# Enter worktree
cd .worktrees/feature-name

# Install dependencies (auto-detect project type)
npm install    # if package.json exists
cargo build    # if Cargo.toml exists
pip install -r requirements.txt  # if exists

# Verify clean baseline
npm test       # Ensure tests pass before starting
```

### Safety Verification

**CRITICAL:** Always verify worktree directory is gitignored:

```bash
# Check if ignored
git check-ignore -q .worktrees

# If NOT ignored, fix immediately
echo ".worktrees" >> .gitignore
git add .gitignore
git commit -m "chore: add .worktrees to gitignore"
```

### Cleanup After Merge

```bash
# Remove worktree after work is merged
git worktree remove .worktrees/feature-name

# Or if branch was deleted
git worktree prune
```

## Conventional Commits

### Commit Message Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, whitespace |
| `refactor` | Code change, no feature/fix |
| `perf` | Performance improvement |
| `test` | Adding/fixing tests |
| `chore` | Maintenance, dependencies |
| `ci` | CI/CD changes |

### Examples

```bash
# Feature
git commit -m "feat(auth): add OAuth2 login flow"

# Bug fix
git commit -m "fix(api): handle null user in profile endpoint"

# Breaking change
git commit -m "feat(api)!: change user endpoint response format

BREAKING CHANGE: User endpoint now returns nested profile object"

# With scope
git commit -m "chore(deps): update react to v19"
```

### Commit Message Guidelines

1. **Imperative mood:** "add feature" not "added feature"
2. **Lowercase first letter:** "add feature" not "Add feature"
3. **No period at end:** "add feature" not "add feature."
4. **Max 50 chars for title:** Keep it concise
5. **Explain WHY in body:** Not just what changed

## Branch Naming

### Format

```
<type>/<ticket-id>-<short-description>
```

### Examples

```
feature/AUTH-123-oauth-login
fix/API-456-null-user-profile
chore/DEPS-789-upgrade-react
```

### Branch Types

| Prefix | Purpose |
|--------|---------|
| `feature/` | New features |
| `fix/` | Bug fixes |
| `chore/` | Maintenance |
| `docs/` | Documentation |
| `refactor/` | Code improvements |
| `test/` | Test additions |

## Graphite Workflow

### Stack-Based Development

Graphite enables stacking PRs for incremental review:

```bash
# Create first branch in stack
gt branch create auth-types

# Make changes, commit
git add . && git commit -m "feat(auth): add authentication types"

# Create next branch in stack
gt branch create auth-service

# Submit all stacked PRs
gt stack submit
```

### Common Graphite Commands

```bash
# Create new branch (stacked on current)
gt branch create <branch-name>

# Submit current stack for review
gt stack submit

# Sync with remote
gt sync

# Rebase current stack
gt stack rebase

# View stack
gt log
```

## Pull Request Guidelines

### PR Size

- **Target:** <300 lines changed
- **Maximum:** 500 lines (rare exceptions)
- **Split large features** into logical increments

### PR Title

Follow conventional commit format:

```
feat(auth): implement OAuth2 login flow
```

### PR Description Template

```markdown
## Summary
<2-3 bullet points describing changes>

## Test Plan
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing completed

## Screenshots (if applicable)
<Add screenshots for UI changes>
```

### Before Creating PR

1. All tests pass locally
2. No TypeScript errors
3. No linting errors
4. Branch is up to date with base
5. Self-reviewed changes

## Finishing a Branch

### Step 1: Verify Tests

```bash
# Run test suite
npm test

# If tests fail, fix before proceeding
```

### Step 2: Present Options

After implementation is complete:

1. **Merge locally** - Merge to base branch, delete feature branch
2. **Create PR** - Push and open pull request
3. **Keep as-is** - Leave branch for later
4. **Discard** - Delete all work (requires confirmation)

### Step 3: Merge Process

```bash
# Option 1: Merge locally
git checkout main
git pull
git merge feature/my-feature
npm test  # Verify on merged result
git branch -d feature/my-feature

# Option 2: Create PR
git push -u origin feature/my-feature
gh pr create --title "feat: my feature" --body "## Summary..."
```

### Step 4: Cleanup

```bash
# Remove worktree after merge/discard
git worktree remove .worktrees/feature-name

# Prune stale worktrees
git worktree prune
```

## Common Mistakes

### Skipping Ignore Verification

**Problem:** Worktree contents get committed

**Fix:** Always verify `.worktrees` is in `.gitignore`

### Large PRs

**Problem:** Hard to review, delayed feedback

**Fix:** Split into logical increments <300 lines

### Vague Commit Messages

**Problem:** Can't understand history

**Fix:** Use conventional commits, explain why

### Proceeding with Failing Tests

**Problem:** Can't distinguish new bugs from old

**Fix:** Always verify clean test baseline before starting

## Quick Reference

### Daily Workflow

```bash
# Start new feature
git worktree add .worktrees/feature -b feature/new-thing
cd .worktrees/feature
npm install && npm test  # Verify baseline

# Work on feature with TDD
# Write test -> fail -> implement -> pass -> refactor

# Commit changes
git add . && git commit -m "feat(scope): description"

# Finish feature
npm test  # Verify all tests pass
git push -u origin feature/new-thing
gh pr create --title "feat(scope): description" --body "..."

# After merge
cd ../..
git worktree remove .worktrees/feature
```

### Commands Cheat Sheet

| Task | Command |
|------|---------|
| Create worktree | `git worktree add .worktrees/name -b branch` |
| List worktrees | `git worktree list` |
| Remove worktree | `git worktree remove .worktrees/name` |
| Create PR | `gh pr create --title "..." --body "..."` |
| Sync with remote | `git pull --rebase` |
| Stack PRs (Graphite) | `gt stack submit` |

## Red Flags

**Never:**
- Commit without passing tests
- Create worktree in non-ignored directory
- Force push to main/master
- Merge with failing tests
- Skip PR review for complex changes

**Always:**
- Verify worktree ignored before creation
- Run tests before commit
- Use conventional commit format
- Keep PRs small and focused
- Clean up worktrees after merge
