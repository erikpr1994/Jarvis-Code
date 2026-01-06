---
name: review
description: Comprehensive code review with quality checks, security analysis, and PR preparation
disable-model-invocation: false
---

# /review - Code Review Command

Perform thorough code review with automated quality checks, security analysis, and optional PR creation.

## What It Does

1. **Reviews changes** - Analyzes diff against base branch
2. **Checks quality** - Runs linting, type-checking, and tests
3. **Security scan** - Identifies potential vulnerabilities
4. **Pattern validation** - Ensures consistency with codebase patterns
5. **Prepares PR** - Generates summary and creates pull request if requested

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | Review scope or action | "pr", "security", "branch:develop" |

## Process

### Phase 1: Context Gathering

1. **Identify review scope**
   ```bash
   git branch --show-current
   git log main..HEAD --oneline
   git diff main...HEAD --stat
   ```

2. **Load project context**
   - Read CLAUDE.md for project conventions
   - Load relevant skills for tech stack
   - Review existing patterns in codebase

3. **Gather all changes**
   - Files modified, added, deleted
   - Total lines changed
   - Commits included

### Phase 2: Automated Quality Checks

4. **Run quality gates**
   - Lint check: `npm run lint` or equivalent
   - Type check: `npm run typecheck` or equivalent
   - Build verification: `npm run build`
   - Test suite: `npm run test`

5. **Check coverage impact**
   - Compare coverage before/after
   - Flag coverage decreases
   - Identify untested new code

6. **Performance analysis** (if applicable)
   - Bundle size impact
   - Build time changes
   - Runtime complexity concerns

### Phase 3: Code Quality Review

7. **Pattern consistency check**
   - Naming conventions followed
   - File organization matches project structure
   - Import patterns consistent
   - Error handling matches existing patterns

8. **Code quality assessment**
   - Complexity analysis (cyclomatic, cognitive)
   - DRY violations (repeated code)
   - SOLID principle adherence
   - Code comments quality

9. **Documentation check**
   - New exports have JSDoc/docstrings
   - README updates if needed
   - API documentation current
   - Inline comments for complex logic

### Phase 4: Security Review

10. **Security vulnerability scan**
    - Hardcoded secrets or credentials
    - SQL injection risks
    - XSS vulnerabilities
    - Insecure direct object references
    - Authentication/authorization gaps

11. **Dependency security**
    - New dependencies added
    - Known vulnerabilities in deps
    - Outdated packages with security issues

12. **Data handling review**
    - PII handling compliance
    - Input validation present
    - Output encoding applied
    - Sensitive data logging

### Phase 5: Change-Specific Review

13. **Review each file changed**
    ```markdown
    ### file.ts
    **Purpose**: What this file does
    **Changes**: What was modified
    **Quality**: Issues or improvements
    **Suggestions**: Recommended changes
    ```

14. **Cross-cutting concerns**
    - Breaking changes identified
    - Migration requirements
    - Backward compatibility
    - Integration impacts

15. **Risk assessment**
    - High-risk areas flagged
    - Rollback complexity
    - Deployment considerations

### Phase 6: Summary and Action

16. **Generate review report**
    ```markdown
    ## Code Review Summary

    **Branch**: feature/xyz -> main
    **Commits**: 5
    **Files Changed**: 12 (+245 / -89)

    ### Quality Gates
    | Check | Status |
    |-------|--------|
    | Lint | Passed |
    | Types | Passed |
    | Tests | Passed (98% coverage) |
    | Build | Passed |

    ### Findings
    #### Critical (Must Fix)
    - [Finding description]

    #### Warnings (Should Fix)
    - [Finding description]

    #### Suggestions (Nice to Have)
    - [Finding description]

    ### Security
    - No vulnerabilities detected
    - [Or list of security concerns]

    ### Recommendation
    [Ready to merge / Needs changes / Needs discussion]
    ```

17. **If "pr" in arguments** - Create pull request
    ```bash
    gh pr create --title "..." --body "..."
    ```

## Output Modes

**Standard review:**
```
/review
```
Returns full review report with all findings.

**Quick review:**
```
/review quick
```
Returns only critical issues and blockers.

**Security focused:**
```
/review security
```
Deep security analysis only.

**Create PR:**
```
/review pr
```
Creates PR with auto-generated summary.

## PR Creation Format

When creating a PR, use this structure:

```markdown
## Summary
- [1-3 bullet points describing the change]

## Changes
- [List of significant changes]

## Testing
- [How this was tested]
- [Test coverage impact]

## Checklist
- [ ] Tests pass
- [ ] Linting passes
- [ ] Documentation updated
- [ ] No security issues
- [ ] Ready for review
```

## Examples

**Review current branch against main:**
```
/review
```

**Review and create PR:**
```
/review pr
```

**Review against specific branch:**
```
/review branch:develop
```

**Security-focused review:**
```
/review security
```

**Quick blocking issues only:**
```
/review quick
```

## Review Checklist

### Must Pass
- [ ] All tests pass
- [ ] No linting errors
- [ ] No type errors
- [ ] No security vulnerabilities
- [ ] No hardcoded secrets

### Should Check
- [ ] Code follows project patterns
- [ ] New code has tests
- [ ] Documentation updated
- [ ] No performance regressions
- [ ] Breaking changes documented

### Nice to Have
- [ ] Code is well-commented
- [ ] Variable names are clear
- [ ] Functions are small and focused
- [ ] Error messages are helpful

## Notes

- Uses `gh` CLI for GitHub operations
- Respects branch protection rules
- Integrates with CI/CD status checks
- Can be run multiple times during development
- Findings are categorized by severity
