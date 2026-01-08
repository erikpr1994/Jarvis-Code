# Jarvis Project Config Templates (Optional)

These templates are **optional extras** for projects that want enhanced tooling.

**You don't need these for Jarvis to work.** The Claude Code hooks enforce rules directly without requiring any project-level changes.

---

## What Jarvis Enforces Automatically

These rules are enforced by Claude Code hooks - no project setup needed:

| Rule | Hook | Bypass |
|------|------|--------|
| No destructive git commands | `git-safety-guard.sh` | `CLAUDE_ALLOW_DESTRUCTIVE=1` |
| Conventional commit format | `conventional-commit.sh` | `CLAUDE_SKIP_COMMIT_FORMAT=1` |
| Run lint/typecheck before commit | `enforce-quality.sh` | `CLAUDE_SKIP_QUALITY_CHECK=1` |
| Warn on `any` types | `no-any-types.sh` | `CLAUDE_ALLOW_ANY=1` |
| PR workflow via skill | `block-direct-submit.sh` | `CLAUDE_ALLOW_DIRECT_SUBMIT=1` |
| Worktree isolation | `require-isolation.sh` | `CLAUDE_ALLOW_MAIN_MODIFICATIONS=1` |

---

## When You Might Want These Templates

Use these templates if you want:

1. **IDE Integration** - ESLint errors shown in VS Code/Cursor
2. **CI/CD Checks** - Same rules enforced in GitHub Actions
3. **Team Standards** - Enforce rules for all developers, not just Claude
4. **Coverage Thresholds** - Fail builds if coverage drops

---

## Available Templates

### `eslint.config.js`
Strict TypeScript ESLint config with:
- No `any` types (error)
- Complexity limits
- Naming conventions
- Import ordering

### `commitlint.config.js`
Conventional commit validation for husky.

### `tsconfig.strict.json`
Maximum TypeScript strictness.

### `vitest.config.ts`
Test runner with 80% coverage thresholds.

### `husky/`
Git hooks for pre-commit and commit-msg.

### `setup-enforcement.sh`
One-command installer for all of the above.

---

## Installation (Optional)

```bash
# Copy what you need to your project
cp ~/.claude/templates/project-configs/eslint.config.js .
npm install -D eslint typescript-eslint @eslint/js eslint-plugin-import

# Or run the full setup
~/.claude/templates/project-configs/setup-enforcement.sh --all
```

---

## Remember

**These are optional.** Jarvis hooks work without any project changes.
