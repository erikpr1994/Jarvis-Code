---
name: debug
description: Systematic debugging workflow with root cause analysis, evidence collection, and fix verification
disable-model-invocation: false
---

# /debug - Debug Workflow Command

Systematic debugging with evidence-based investigation, root cause analysis, and verified fixes.

## What It Does

1. **Collects evidence** - Gathers logs, errors, and system state
2. **Reproduces issue** - Creates reliable reproduction steps
3. **Analyzes root cause** - Uses Five Whys methodology
4. **Proposes fix** - Suggests targeted solutions
5. **Verifies resolution** - Confirms fix and prevents regression

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | Bug description or error message | "login fails", "TypeError: undefined" |

## Core Philosophy

- **Evidence-based**: Every conclusion supported by concrete evidence
- **Systematic**: Follow structured investigation process
- **Root cause focus**: Fix underlying issues, not symptoms
- **Verification required**: Confirm fix resolves the problem

## Process

### Phase 1: Issue Understanding

1. **Capture the problem**
   - User-reported symptoms
   - Expected vs actual behavior
   - Error messages and codes
   - Affected components/features

2. **Gather initial context**
   - When did it start happening?
   - What changed recently?
   - Who is affected?
   - How severe is the impact?

3. **Check for known issues**
   - Search project issues/bugs
   - Check recent commits
   - Review deployment history
   - Search error in documentation

### Phase 2: Evidence Collection

4. **Frontend evidence** (if applicable)
   ```javascript
   // Browser console
   console.log(), errors, warnings
   // Network tab
   Request/response data, status codes, timing
   // React DevTools
   Component state, props, renders
   // Performance
   Memory usage, CPU, frame rate
   ```

5. **Backend evidence** (if applicable)
   ```bash
   # Server logs
   tail -f logs/app.log | grep ERROR
   # Database queries
   EXPLAIN ANALYZE suspicious_query;
   # System resources
   top, htop, iostat
   # API responses
   curl -v endpoint
   ```

6. **Environment evidence**
   - OS, browser, device
   - Package versions
   - Environment variables
   - Configuration state

### Phase 3: Reproduction

7. **Create reproduction steps**
   ```markdown
   ## Steps to Reproduce
   1. [First action]
   2. [Second action]
   3. [Third action]

   **Expected**: [What should happen]
   **Actual**: [What happens instead]
   **Frequency**: [Always / Sometimes / Rare]
   ```

8. **Isolate the issue**
   - Minimal reproduction case
   - Remove unrelated variables
   - Identify trigger conditions
   - Document environmental factors

9. **Verify reproduction**
   - Reproduce multiple times
   - Test in different environments
   - Confirm consistent behavior

### Phase 4: Root Cause Analysis

10. **Five Whys investigation**
    ```markdown
    ## Root Cause Analysis

    **Symptom**: [Observable problem]

    1. Why does [symptom] occur?
       → Because [cause 1]
       Evidence: [supporting data]

    2. Why does [cause 1] happen?
       → Because [cause 2]
       Evidence: [supporting data]

    3. Why does [cause 2] happen?
       → Because [cause 3]
       Evidence: [supporting data]

    4. Why does [cause 3] happen?
       → Because [cause 4]
       Evidence: [supporting data]

    5. Why does [cause 4] happen?
       → Because [ROOT CAUSE]
       Evidence: [supporting data]
    ```

11. **Hypothesis testing**
    - Form testable theories
    - Design experiments to validate
    - Eliminate alternatives
    - Confirm with evidence

12. **Code path tracing**
    - Follow execution flow
    - Identify failure point
    - Check data transformations
    - Validate assumptions

### Phase 5: Solution Development

13. **Propose fix**
    ```markdown
    ## Proposed Solution

    **Root Cause**: [Brief description]

    **Fix Approach**:
    - [Change 1]: [Why]
    - [Change 2]: [Why]

    **Files to Modify**:
    - path/to/file.ts
    - path/to/other.ts

    **Risk Assessment**:
    - Low/Medium/High
    - [Potential side effects]
    ```

14. **Consider alternatives**
    - Quick fix vs proper fix
    - Short-term vs long-term
    - Scope of change
    - Regression risk

15. **Implement fix**
    - Make minimal necessary changes
    - Add error handling if needed
    - Include helpful error messages
    - Document complex logic

### Phase 6: Verification

16. **Verify fix**
    - Original bug no longer reproduces
    - All edge cases handled
    - Error handling improved
    - No new issues introduced

17. **Regression testing**
    - Run existing test suite
    - Add new tests for bug case
    - Test related functionality
    - Performance impact check

18. **Prevention measures**
    - Add test to prevent recurrence
    - Update documentation if needed
    - Consider similar code patterns
    - Improve error messages

## Output

```markdown
## Debug Report

### Issue Summary
**Problem**: [Brief description]
**Severity**: [Critical / High / Medium / Low]
**Status**: [Investigating / Identified / Fixed / Verified]

### Evidence Collected
- [Evidence 1]
- [Evidence 2]
- [Evidence 3]

### Reproduction Steps
1. [Step 1]
2. [Step 2]
3. [Step 3]

### Root Cause
[Description of the underlying issue]

**Five Whys Path**:
Symptom → Cause 1 → Cause 2 → Cause 3 → ROOT CAUSE

### Solution
**Files Changed**:
- `path/to/file.ts`: [Change description]

**Fix Description**:
[What was changed and why]

### Verification
- [ ] Bug no longer reproduces
- [ ] Tests pass
- [ ] No regressions
- [ ] New test added

### Prevention
- [Test added to prevent recurrence]
- [Documentation updated]
- [Similar patterns checked]
```

## Examples

**Debug with error message:**
```
/debug TypeError: Cannot read property 'id' of undefined
```

**Debug with feature description:**
```
/debug user login redirects to wrong page
```

**Debug with component:**
```
/debug PaymentForm component crashes on submit
```

**Debug performance issue:**
```
/debug dashboard loads slowly after login
```

**Debug intermittent issue:**
```
/debug API sometimes returns 500 errors
```

## Debug Strategies by Type

### Crash/Error
1. Get full stack trace
2. Identify failing line
3. Check variable state
4. Trace data source

### Wrong Behavior
1. Document expected vs actual
2. Find decision point
3. Trace logic path
4. Check conditions

### Performance
1. Profile with tools
2. Identify bottleneck
3. Measure before/after
4. Validate improvement

### Intermittent
1. Identify patterns
2. Check race conditions
3. Review async code
4. Test under load

### External Service
1. Verify credentials/config
2. Check service status
3. Review API contracts
4. Test with minimal case

## Time-Boxing Rules

- **15 minutes**: If stuck, step back and reassess
- **30 minutes**: Try different approach
- **1 hour**: Ask for help or create minimal reproduction
- **After fix**: Spend time on prevention

## Notes

- Think like a detective: evidence-based conclusions
- Document everything for future reference
- Fix root causes, not symptoms
- Always verify the fix works
- Add tests to prevent recurrence
- Time-box to avoid rabbit holes
