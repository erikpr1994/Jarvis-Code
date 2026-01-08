---
name: git-workflow
category: quality
confidence: 0.8
description: Git workflow rules (most enforced by hooks)
---

# Git Workflow

## Enforcement

Most git workflow rules are enforced by **Claude Code hooks**:

| Rule | Hook |
|------|------|
| No `git reset --hard` | `git-safety-guard.sh` |
| No `git push --force` | `git-safety-guard.sh` |
| No `git checkout --` | `git-safety-guard.sh` |
| No `rm -rf` | `git-safety-guard.sh` |
| Use submit-pr skill for PRs | `block-direct-submit.sh` |
| No direct main branch edits | `require-isolation.sh` |

Commit format is enforced by **commitlint** at the project level.

---

## Worktree-Based Development

Use git worktrees for isolated workspaces:

```bash
# Create worktree
git worktree add .worktrees/feature-name -b feature/feature-name

# Work in isolation
cd .worktrees/feature-name

# Clean up after merge
git worktree remove .worktrees/feature-name
```

**Why worktrees?**
- Work on multiple features simultaneously
- No branch switching disrupts work
- Clean git status

---

## Conventional Commits

Format: `<type>(<scope>): <description>`

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

**Enforced by commitlint** - invalid messages are blocked.

Install: `~/.claude/templates/project-configs/setup-enforcement.sh --commitlint --husky`

---

## Branch Naming

Format: `<type>/<ticket-id>-<short-description>`

Examples:
```
feature/AUTH-123-oauth-login
fix/API-456-null-user-profile
chore/DEPS-789-upgrade-react
```

---

## PR Guidelines

### Size Target
- **Target:** <300 lines
- **Maximum:** 500 lines
- Split large features into logical increments

*Note: This can be enforced with a `pr-size-check.sh` hook if needed.*

### PR Title
Follow conventional commit format:
```
feat(auth): implement OAuth2 login flow
```

### Before Creating PR

Enforced by hooks:
- ✅ All tests pass
- ✅ No TypeScript errors
- ✅ No linting errors

Not automated (self-review):
- [ ] Branch is up to date with base
- [ ] Self-reviewed changes
