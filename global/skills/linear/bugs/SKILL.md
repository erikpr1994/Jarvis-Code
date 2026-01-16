---
name: reply-linear-bugs
description: Fix Linear issues tagged with "bug". Either produces a PR with the fix or explains why it won't be fixed. Triggers - linear bugs, fix bugs, bug triage, resolve bugs.
---

# Reply Linear Bugs

**Iron Law:** Bugs produce either a FIX (PR) or an EXPLANATION (won't fix). No middle ground.

## Overview

This skill handles Linear issues tagged with "bug". Every bug must be resolved with either:
1. A Pull Request that fixes it
2. A documented explanation of why it won't be fixed

```
Bug → Investigate → Reproduce → Decision
                                  ↓
                    ┌─────────────┴─────────────┐
                    ↓                           ↓
              FIX (PR)                  WON'T FIX (Explanation)
```

## Valid Outcomes

| Outcome | When to Use | Action |
|---------|-------------|--------|
| **Fix with PR** | Bug is valid and fixable | TDD fix → `/submit-pr` |
| **Won't Fix** | Out of scope, by design, or not worth fixing | Comment explanation, close |
| **Duplicate** | Already reported/fixed | Link to original, close |
| **Cannot Reproduce** | Bug not reproducible | Request more info or close |
| **Needs More Info** | Insufficient details | Comment questions, keep open |

---

## The Workflow

### Step 1: List Pending Bugs

```typescript
mcp__linear-server__list_issues({
  label: "bug",
  state: "started",  // Or "triage", "backlog"
  limit: 20
});
```

### Step 2: Select a Bug

Present bugs to user:

```markdown
## Pending Bugs

| ID | Title | Priority | Age |
|----|-------|----------|-----|
| PEA-301 | Login fails with special characters | High | 1 day |
| PEA-315 | Pagination shows wrong count | Medium | 3 days |

Which bug would you like to address?
```

### Step 3: Understand the Bug

Read the full issue:

```typescript
mcp__linear-server__get_issue({ id: "issue-uuid" });
```

Gather:
- What is the expected behavior?
- What is the actual behavior?
- Steps to reproduce
- Environment/context
- Impact/severity

### Step 4: Reproduce the Bug

**Before writing any fix, REPRODUCE the bug:**

1. Set up the environment described
2. Follow reproduction steps
3. Observe the actual behavior
4. Document your findings

```markdown
## Reproduction Attempt

**Steps taken:**
1. [What you did]
2. [What you did]

**Result:** [Reproduced / Could not reproduce]
**Environment:** [Your test environment]
```

### Step 5: Decision Point

```
Can you reproduce it?
├── NO → Request more info OR close as "Cannot Reproduce"
└── YES → Is it worth fixing?
          ├── NO → Close as "Won't Fix" with explanation
          └── YES → Proceed to fix
```

### Step 6A: Fix the Bug (TDD)

**Use TDD process - test first:**

1. **Write failing test** that demonstrates the bug
2. **Run test** - verify it fails (proves bug exists)
3. **Write minimal fix** to pass the test
4. **Run test** - verify it passes
5. **Refactor** if needed

```markdown
## Bug Fix Plan

**Root Cause:** [What's causing the bug]
**Fix Approach:** [How you'll fix it]

**Test:** Will write test that [describes expected behavior]
**Files:** [Files to modify]
```

### Step 6B: Submit PR

After fix is verified locally:

```
Use /submit-pr skill for full PR pipeline
```

**PR Description must include:**
- Link to Linear issue
- Root cause explanation
- How fix addresses it
- Test coverage added

### Step 6C: Won't Fix / Close

If not fixing, document clearly:

```typescript
mcp__linear-server__create_comment({
  issueId: "bug-issue-uuid",
  body: `## Resolution: Won't Fix

**Reason:** [Why this won't be fixed]

**Options:**
${reasonType === 'by_design' ? '- This is intended behavior because [reason]' : ''}
${reasonType === 'out_of_scope' ? '- This is outside our current scope because [reason]' : ''}
${reasonType === 'not_worth_it' ? '- The fix cost outweighs the impact because [reason]' : ''}

**Alternatives:**
- [Any workarounds for the user]`
});

mcp__linear-server__update_issue({
  id: "bug-issue-uuid",
  state: "Canceled"  // Or your "Won't Fix" state
});
```

### Step 7: Confirm Resolution

```markdown
## Bug Resolved

**Bug:** PEA-301 - Login fails with special characters
**Resolution:** Fixed in PR #123
**Root Cause:** Input not properly escaped
**Test Added:** Yes - `tests/auth/login.test.ts`

Linear issue will auto-close when PR merges.

Next bug?
```

---

## Won't Fix Reasons

Use these templates:

### By Design
```
This behavior is intentional:
- [Explain the design decision]
- [Why it works this way]

If this causes issues for your use case, please create a feature request instead.
```

### Out of Scope
```
This is outside our current scope:
- [What scope it falls under]
- [Why it's not prioritized]

We may revisit this in the future. Creating a tracking issue for [timeframe/milestone].
```

### Cannot Reproduce
```
We could not reproduce this issue:
- Environment tested: [details]
- Steps followed: [steps]
- Result: [what happened]

Please provide:
- [ ] Browser/OS version
- [ ] Console errors
- [ ] Network requests
- [ ] Screen recording if possible
```

### Duplicate
```
This is a duplicate of [ISSUE-ID].

Tracking in the original issue. Closing this one.
```

---

## Example Session

**User says:** `/reply-linear-bugs`

**Step 1-2 - List & Select:**
```
Found 2 bugs:

1. PEA-301: Login fails with special characters (High, 1 day old)
2. PEA-315: Pagination shows wrong count (Medium, 3 days old)

Which bug would you like to address?
```

**User:** "PEA-301"

**Step 3 - Understand:**
```
## Bug Analysis: PEA-301

**Title:** Login fails with special characters
**Reporter:** User via support
**Priority:** High

**Expected:** User can login with password containing special chars
**Actual:** Login returns "Invalid credentials" error
**Steps to Reproduce:**
1. Create account with password "Test@123!"
2. Log out
3. Try to log in with same password
4. Error appears

**Impact:** Users with special character passwords cannot login
```

**Step 4 - Reproduce:**
```
## Reproduction Attempt

**Steps:**
1. Created test account with password "Test@123!"
2. Logged out
3. Attempted login

**Result:** REPRODUCED - Got "Invalid credentials" error
**Environment:** Local dev server

**Finding:** Password comparison fails because special chars not escaped
```

**Step 5-6 - Fix:**
```
## Bug Fix Plan

**Root Cause:** Password sanitization strips special characters before comparison
**Fix:** Remove sanitization from password comparison (sanitize only for display)

**TDD Plan:**
1. Write test: login with special char password should succeed
2. Verify test fails (bug exists)
3. Fix sanitization logic
4. Verify test passes

Proceeding with fix...
```

[TDD implementation happens here]

```
## Fix Complete

**Test added:** `tests/auth/login.test.ts` - "handles special characters in password"
**Files modified:** `src/auth/sanitize.ts`
**All tests passing:** Yes

Ready to submit PR?
```

**User:** "Yes"

[/submit-pr flow happens]

**Step 7 - Confirm:**
```
## Bug Resolved

**Bug:** PEA-301 - Login fails with special characters
**Resolution:** PR #45 - Fix password sanitization
**Root Cause:** Overly aggressive input sanitization
**Test Added:** Yes

PR created, CI running. Linear issue will auto-close on merge.

Next bug?
```

---

## Quick Reference

```
PROCESS: List → Select → Understand → Reproduce → Decide → Fix/Close → Confirm
OUTPUT:  PR (fix) OR Explanation (won't fix)
ALWAYS:  Reproduce before fixing, TDD for fixes

VALID OUTCOMES:
- PR with fix (TDD process)
- Won't fix (documented reason)
- Duplicate (linked to original)
- Cannot reproduce (request more info)
- Needs more info (ask questions)

TOOLS:
- mcp__linear-server__list_issues (find bugs)
- mcp__linear-server__get_issue (read details)
- mcp__linear-server__create_comment (add explanation)
- mcp__linear-server__update_issue (close/update)
- /submit-pr (for fixes)
```

## Red Flags - STOP

- About to fix without reproducing → STOP, reproduce first
- About to fix without test → STOP, write failing test first
- Closing without explanation → STOP, document why
- Can't decide fix vs won't fix → STOP, ask user

---

## Integration

**Uses:**
- **Linear MCP** - Issue operations
- **TDD skill** - Test-first bug fixes
- **submit-pr** - PR submission pipeline
- **systematic-debugging** - For complex bugs

**Workflow with Linear:**
```
Bug found → Linear issue created
    ↓
/reply-linear-bugs
    ↓
├── Fix → PR → Merge → Issue auto-closes
└── Won't Fix → Comment → Close issue
```

## Trigger Keywords

- "linear bugs"
- "fix bugs"
- "bug triage"
- "resolve bugs"
- "pending bugs"
