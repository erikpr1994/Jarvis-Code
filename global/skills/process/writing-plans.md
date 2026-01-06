---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code. Triggers - plan, design, architect, implementation plan, spec, requirements.
triggers: ["plan", "write plan", "create plan", "design", "architect", "implementation plan", "spec", "requirements", "how to build", "plan out"]
---

# Writing Plans

**Iron Law:** NEVER write code before the plan is complete and approved.

## Overview

Plans bridge the gap between requirements and implementation. A good plan enables any skilled developer to execute correctly, even with zero context about the codebase. Plans fail when they're vague, miss edge cases, or skip verification steps.

## When to Use

- Before implementing any multi-step feature
- When requirements are defined but approach is unclear
- After brainstorming, when moving to structured execution
- When delegating work to subagents or other developers
- Before any change touching more than 3 files

## The Process

```
1. CLARIFY   -> Understand what we're building
2. RESEARCH  -> Understand the existing codebase
3. DESIGN    -> Structure the approach
4. DOCUMENT  -> Write the plan
5. VALIDATE  -> Review and approve
```

## Step 1: Clarify - Understand What We're Building

Before writing anything, ensure you understand:

```markdown
## Goal Clarification

**What**: [One sentence - what we're building]
**Why**: [Business/user value]
**Success Criteria**:
- [ ] Criterion 1 (measurable)
- [ ] Criterion 2 (testable)
- [ ] Criterion 3 (observable)

**Scope**:
- IN: [What's included]
- OUT: [What's explicitly excluded]

**Constraints**:
- Technical: [Stack, performance, etc.]
- Timeline: [Deadlines if any]
- Dependencies: [What must exist first]
```

**Ask clarifying questions if anything is unclear.** Do not proceed with assumptions.

## Step 2: Research - Understand the Codebase

Investigate before designing:

```markdown
## Codebase Research

**Relevant Files**:
- `src/path/to/related.ts` - Does X, we'll extend it
- `tests/path/to/tests.ts` - Existing test patterns
- `docs/architecture.md` - Relevant architecture

**Existing Patterns**:
- Authentication: Uses JWT middleware
- Error handling: Custom ApiError class
- Database: Prisma with transactions

**Similar Features**:
- User registration follows same flow
- Payment module has similar validation

**Gotchas Found**:
- Must use specific error format
- Tests require mock database
```

## Step 3: Design - Structure the Approach

Break down into phases and tasks:

```markdown
## Design Overview

**Architecture**: [2-3 sentences on approach]
**Tech Stack**: [Key technologies]

**Phases**:
1. Foundation - Setup and scaffolding
2. Core - Main implementation
3. Integration - Connect components
4. Testing - Verification
5. Polish - Edge cases, docs

**Risk Areas**:
- [Area 1] - Mitigation: [strategy]
- [Area 2] - Mitigation: [strategy]
```

## Step 4: Document - Write the Plan

### Plan Document Format

```markdown
# [Feature Name] Implementation Plan

> **For Claude:** Use executing-plans skill to implement this plan task-by-task.

**Created**: [date]
**Status**: Draft | In Review | Approved | In Progress | Complete
**Estimated Scope**: Small | Medium | Large

**Goal**: [One sentence describing what this builds]

**Architecture**: [2-3 sentences about approach]

**Tech Stack**: [Key technologies/libraries]

---

## Success Criteria

- [ ] Criterion 1 (with verification command)
- [ ] Criterion 2 (with expected output)
- [ ] Criterion 3 (with test to run)

## Phase 1: [Name]

**Objective**: [What this phase accomplishes]

### Task 1.1: [Descriptive Name]

**Files**:
- Create: `exact/path/to/file.ts`
- Modify: `exact/path/to/existing.ts:123-145`
- Test: `tests/exact/path/to/test.ts`

**Step 1: Write the failing test**

```typescript
describe('feature', () => {
  it('should do specific thing', () => {
    const result = feature(input);
    expect(result).toBe(expected);
  });
});
```

**Step 2: Run test to verify it fails**

```bash
npm test -- --testPathPattern="feature" -v
```
Expected: FAIL with "feature is not defined"

**Step 3: Write minimal implementation**

```typescript
export function feature(input: Input): Output {
  return expected;
}
```

**Step 4: Run test to verify it passes**

```bash
npm test -- --testPathPattern="feature" -v
```
Expected: PASS

**Step 5: Commit**

```bash
git add src/feature.ts tests/feature.test.ts
git commit -m "feat: add feature functionality"
```

### Task 1.2: [Next Task]
...

**Phase 1 Checkpoint**:
- [ ] All tests passing: `npm test`
- [ ] Feature X works: [verification command]
- [ ] No regressions: `npm run test:all`

## Phase 2: [Name]
...

---

## Dependencies

| Dependency | Purpose | Status |
|------------|---------|--------|
| Package X | Does Y | Installed |
| API Key | External service | Needed |

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Risk 1 | High | Strategy |
| Risk 2 | Medium | Strategy |

## Alternatives Considered

1. **Alternative A**: [Why not chosen]
2. **Alternative B**: [Why not chosen]

## Notes for Implementer

- Remember to [specific gotcha]
- Check [specific file] for [specific pattern]
- Don't forget [common mistake to avoid]
```

### Task Granularity Rules

**Each step is ONE action (2-5 minutes max):**

Good:
- "Write the failing test for X" - one action
- "Run test to verify it fails" - one action
- "Implement minimal code to pass" - one action
- "Run test to verify it passes" - one action
- "Commit changes" - one action

Bad:
- "Implement the feature" - too vague
- "Add tests and implementation" - multiple actions
- "Write the authentication system" - way too big

### Plan Requirements Checklist

- [ ] Exact file paths (not "in the utils folder")
- [ ] Complete code snippets (not "add validation")
- [ ] Exact commands with expected output
- [ ] Each step is 2-5 minutes of work
- [ ] TDD order: test first, then implementation
- [ ] Commit after each logical unit
- [ ] Verification at each phase checkpoint
- [ ] No ambiguous instructions

## Step 5: Validate - Review and Approve

Before execution, verify the plan:

```markdown
## Plan Review Checklist

- [ ] Goal is clear and measurable
- [ ] All files have exact paths
- [ ] All code is complete (not pseudocode)
- [ ] All commands have expected outputs
- [ ] Steps are granular (2-5 min each)
- [ ] TDD pattern followed throughout
- [ ] Phase checkpoints are verifiable
- [ ] Dependencies are identified
- [ ] Risks have mitigations
- [ ] Someone with no context could execute this
```

**Get user approval before proceeding to execution.**

## Output Location

Save plans to the appropriate location:

1. If `docs/plans/` exists: `docs/plans/YYYY-MM-DD-feature-name.md`
2. Otherwise: `.claude/tasks/plan-feature-name.md`

## Execution Handoff

After saving the plan:

```markdown
## Plan Complete

**Saved to**: `docs/plans/2024-01-15-user-auth.md`
**Phases**: 4
**Tasks**: 12
**Estimated Scope**: Medium

**Ready to execute?** Two options:

1. **Sequential** - Execute tasks one by one with verification
2. **Subagent-Driven** - Dispatch parallel subagents per task

Which approach would you prefer?
```

## Examples

### Good Plan Excerpt

```markdown
### Task 2.1: Add Password Hashing

**Files**:
- Create: `src/utils/password.ts`
- Test: `tests/utils/password.test.ts`

**Step 1: Write failing test**

```typescript
import { hashPassword, verifyPassword } from '../src/utils/password';

describe('password utils', () => {
  it('should hash password', async () => {
    const password = 'testPassword123';
    const hash = await hashPassword(password);
    expect(hash).not.toBe(password);
    expect(hash.length).toBeGreaterThan(50);
  });

  it('should verify correct password', async () => {
    const password = 'testPassword123';
    const hash = await hashPassword(password);
    const isValid = await verifyPassword(password, hash);
    expect(isValid).toBe(true);
  });
});
```

**Step 2: Run test**
```bash
npm test -- tests/utils/password.test.ts
```
Expected: FAIL - "Cannot find module '../src/utils/password'"
```

### Bad Plan (DO NOT DO THIS)

```markdown
### Task: Implement Password System

- Add password hashing
- Add verification
- Make sure it's secure
- Add tests

Files: utils folder
```

**Why wrong:** Vague tasks, no exact paths, no code, no commands.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "The task is simple enough" | Simple tasks compound. Plan anyway. |
| "I'll figure it out as I go" | That's how bugs happen. Plan first. |
| "Plans take too long" | Plans save 10x the time in rework. |
| "I know this codebase" | Future you doesn't. Document it. |
| "Just one small change" | Small changes cascade. Plan the cascade. |
| "The user wants it now" | Rushing creates more delays. |

## Red Flags - STOP and Revise

- Tasks that take more than 10 minutes
- "Implement X" without specific steps
- Missing file paths
- Missing test commands
- Pseudocode instead of real code
- No verification checkpoints
- "Figure out the best approach" in a step
- Skipped phases or tasks

## Verification Checklist

Before calling the plan complete:

- [ ] Every task has exact file paths
- [ ] Every task has complete code
- [ ] Every task has run command with expected output
- [ ] Every phase has verification checkpoint
- [ ] Plan is executable by someone with no context
- [ ] Success criteria are measurable
- [ ] User has approved the plan

## Quick Reference

```
ALWAYS: Exact file paths
ALWAYS: Complete code (not pseudocode)
ALWAYS: Test first, then implement
ALWAYS: Expected output for commands
NEVER: "Implement X" without breakdown
NEVER: Skip verification steps
MINIMUM: 3 success criteria
```

## Integration

**Pairs with:**
- **brainstorming** - Generate options before planning
- **executing-plans** - Execute the plan step by step
- **tdd-workflow** - TDD pattern within each task
- **verification** - Verify checkpoints
- **subagent-driven-development** - Parallel execution
