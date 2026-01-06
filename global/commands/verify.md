---
name: verify
description: Run verification pipeline with configurable depth
disable-model-invocation: false
---

# /verify - Run Verification Pipeline

Execute the verification pipeline at specified depth to ensure code quality.

## What It Does

1. **Runs automated checks** - Lint, types, formatting, tests
2. **Triggers reviews** - Code, spec, security reviews via agents
3. **Reports results** - Consolidated pass/fail status
4. **Blocks on failures** - Prevents progression with issues

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | Verification level | "quick", "standard", "full", "release" |

## Verification Levels

| Level | Checks Included | When to Use |
|-------|-----------------|-------------|
| **quick** | Lint, types | During development |
| **standard** | + Unit tests | Before commit |
| **full** | + Integration, E2E, review agents | Before PR |
| **release** | + Performance, security audit | Before deploy |

## Process

### Phase 1: Quick Verification

```bash
# 1. TypeScript compilation
tsc --noEmit

# 2. Linting
pnpm lint

# 3. Formatting check
prettier --check .
```

### Phase 2: Standard Verification

```bash
# 4. Unit tests
pnpm test
```

### Phase 3: Full Verification

```bash
# 5. Integration tests
pnpm test:integration

# 6. E2E tests
pnpm test:e2e

# 7. Build verification
pnpm build
```

**Plus parallel review agents:**

```markdown
## Review Agents (Parallel Group 1 - Required)

Task: @code-reviewer
Review the changes for code quality and CLAUDE.md compliance.
Focus on: maintainability, readability, patterns.

---

Task: @spec-reviewer
Review changes against project specifications.
Verify feature completeness and correct implementation.
```

```markdown
## Review Agents (Parallel Group 2 - Optional)

Task: @security-reviewer
Audit for security vulnerabilities.
Check: auth, injection, data exposure.

---

Task: @accessibility-auditor
Verify WCAG compliance for UI changes.

---

Task: @performance-reviewer
Check for performance regressions.
```

### Phase 4: Release Verification

```bash
# 8. Performance benchmarks
pnpm bench

# 9. Security audit
npm audit

# 10. Bundle analysis
pnpm analyze
```

## Output Format

```markdown
## Verification Results

**Level:** full
**Status:** PASS ✅

### Automated Checks
| Check | Status | Time |
|-------|--------|------|
| TypeScript | ✅ Pass | 2.3s |
| Linting | ✅ Pass | 1.8s |
| Formatting | ✅ Pass | 0.5s |
| Unit Tests | ✅ Pass (142/142) | 8.2s |
| Integration | ✅ Pass (23/23) | 15.1s |
| E2E | ✅ Pass (18/18) | 45.3s |
| Build | ✅ Pass | 12.4s |

### Agent Reviews
| Agent | Status | Score | Key Findings |
|-------|--------|-------|--------------|
| code-reviewer | ✅ Approved | 8.5/10 | Clean implementation |
| spec-reviewer | ✅ Approved | 9/10 | Matches requirements |
| security-reviewer | ✅ Pass | - | No vulnerabilities |
| accessibility-auditor | ⚠️ Warning | - | 2 minor issues |
| performance-reviewer | ✅ Pass | - | No regressions |

### Summary
- Total time: 1m 25s
- All required checks passed
- 2 optional warnings (accessibility)

### Next Steps
- Ready for PR submission
- Consider addressing accessibility warnings
```

## Examples

**Quick check during development:**
```
/verify quick
```

**Standard check before commit:**
```
/verify standard
```

**Full check before PR:**
```
/verify full
```

**Release check before deploy:**
```
/verify release
```

**Check specific path:**
```
/verify quick src/components/
```

## Configuration

Configure in `settings.json`:

```json
{
  "verification": {
    "default_level": "standard",
    "fail_on_warnings": false,
    "parallel_agents": true,
    "timeout_minutes": 10,
    "required_agents": ["code-reviewer", "spec-reviewer"],
    "optional_agents": ["security-reviewer", "accessibility-auditor", "performance-reviewer"]
  }
}
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All checks passed |
| 1 | Required check failed |
| 2 | Optional check failed (warning) |
| 3 | Timeout |
| 4 | Configuration error |

## Integration

**With git hooks:**
```bash
# .husky/pre-commit
/verify standard

# .husky/pre-push
/verify full
```

**With CI:**
```yaml
# .github/workflows/verify.yml
- run: /verify release
```
