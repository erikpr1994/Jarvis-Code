---
name: commit
description: Smart commit with intelligent message generation, pre-commit verification, and optional push
disable-model-invocation: false
---

# /commit - Smart Commit with Verification

Create well-structured commits with intelligent message generation, pre-commit checks, and safety verification.

## What It Does

1. **Analyzes changes** - Reviews staged and unstaged modifications
2. **Runs verification** - Executes linting, type-checking, and tests if configured
3. **Generates message** - Creates semantic commit message based on changes
4. **Creates commit** - Safely commits with proper formatting
5. **Optionally pushes** - Push to remote if requested

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | Optional commit message or "push" flag | "fix auth" or "push" |

## Process

### Phase 1: Change Analysis

1. **Check repository state**
   ```bash
   git status
   git diff --cached --name-only  # Staged files
   git diff --name-only           # Unstaged files
   ```

2. **Analyze change scope**
   - Classify changes: feat/fix/refactor/docs/style/test/build/chore
   - Identify affected modules or features
   - Check for breaking changes
   - Detect if changes span multiple logical areas

3. **Review recent commits** for message style consistency
   ```bash
   git log --oneline -10
   ```

### Phase 2: Pre-Commit Verification

4. **Run configured checks** (skip if not available)
   - Linting: `npm run lint` / `cargo clippy` / equivalent
   - Type checking: `npm run typecheck` / `mypy` / equivalent
   - Format check: `npm run format:check` / `cargo fmt --check`
   - Quick tests: `npm run test:unit` (if fast)

5. **Handle verification failures**
   - If fixable: Offer to auto-fix (formatting, lint --fix)
   - If not fixable: Report issues, ask to proceed or abort
   - Never force commit with failing checks

6. **Security check**
   - Scan for potential secrets (.env patterns, API keys)
   - Warn if sensitive files are staged
   - Block if credentials detected

### Phase 3: Message Generation

7. **Generate commit message**
   - Follow conventional commits format: `type(scope): description`
   - Keep subject line under 72 characters
   - Add body for complex changes
   - Reference issues if mentioned in branch name

8. **Message format**
   ```
   {type}({scope}): {concise description}

   {optional body explaining why, not what}

   {optional footer: breaking changes, issue refs}
   ```

9. **Smart grouping decision**
   - Single logical change: One commit
   - Multiple unrelated changes: Suggest splitting
   - Related changes across areas: Consider multi-commit strategy

### Phase 4: Commit Execution

10. **Stage changes** (if not already staged)
    - Prompt user for which files to include
    - Support `all` to stage everything
    - Respect .gitignore

11. **Create commit**
    ```bash
    git commit -m "$(cat <<'EOF'
    {generated message}
    EOF
    )"
    ```

12. **Verify commit created**
    ```bash
    git log -1 --oneline
    ```

### Phase 5: Optional Push

13. **If "push" in arguments**
    - Verify remote branch exists
    - Check if ahead of remote
    - Push with tracking: `git push -u origin {branch}`

14. **If pushing to main/master**
    - Warn and require explicit confirmation
    - Suggest creating PR instead

## Output

```markdown
## Commit Created

**Type**: {feat|fix|refactor|...}
**Scope**: {affected area}
**Message**: {commit message}

### Changes Included
- {file1}: {change summary}
- {file2}: {change summary}

### Verification
- Lint: Passed
- Types: Passed
- Format: Passed

### Next Steps
- Push with: `git push` or `/commit push`
- Create PR with: `/jarvis-review pr`
```

## Examples

**Basic commit (auto-generated message):**
```
/commit
```

**With message hint:**
```
/commit fix the login redirect bug
```

**Commit and push:**
```
/commit push
```

**With specific message and push:**
```
/commit add user profile feature, push
```

## Safety Rules

- **NEVER** force push without explicit user request
- **NEVER** commit files containing secrets
- **NEVER** push to main/master without warning
- **NEVER** amend commits that have been pushed
- **ALWAYS** run available verification checks
- **ALWAYS** show diff summary before committing

## Multi-Commit Strategy

When changes span multiple logical areas:

```bash
# Example: Frontend + Backend + Database changes
git add src/components/*
git commit -m "feat(ui): add profile components"

git add src/server/*
git commit -m "feat(api): add profile endpoints"

git add supabase/*
git commit -m "feat(db): add profile schema"
```

## Notes

- Uses HEREDOC for commit messages to preserve formatting
- Respects project's existing commit message conventions
- Integrates with pre-commit hooks if configured
- Works with both staged and unstaged changes
