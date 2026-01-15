---
name: linear
description: Use when planning features, tracking tasks, or managing implementation. Replaces local markdown plans with Linear's hierarchical issues. Triggers - linear, plan, issue, task, feature planning, implementation plan.
---

# Linear Planning

**Iron Law:** EVERY TASK MUST BE EXECUTABLE. Each issue is a testable, runnable piece of code.

## When to Use

- Planning a new feature or multi-phase implementation
- Need to track work across multiple team members
- Want atomic, verifiable tasks instead of vague descriptions
- Coordinating work across phases with clear dependencies
- Creating execution checkpoints for TDD workflow

## Overview

Linear replaces markdown-based plans with hierarchical issues. Instead of writing plans to `docs/plans/`, create a structured issue tree in Linear where each leaf issue is an atomic, testable task. Each level of the hierarchy must be more specific than its parent, culminating in executable code with verification commands.

## Execution Model

```
1. CREATE ROOT   -> Feature issue with full context
2. CREATE PHASES -> Child issues for each phase
3. CREATE TASKS  -> Leaf issues for atomic work
4. EXECUTE       -> Work through leaves in order
5. VERIFY        -> Check phase completion
```

## Issue Hierarchy Example

```
ENG-100: [Feature] User Authentication System
├── ENG-101: [Phase 1] Database Schema
│   ├── ENG-102: Create users table migration
│   ├── ENG-103: Create sessions table migration
│   └── ENG-104: Add indexes for performance
├── ENG-105: [Phase 2] Core Implementation
│   ├── ENG-106: Implement password hashing utility
│   │   ├── ENG-107: Write failing test for hash function
│   │   └── ENG-108: Implement bcrypt hashing
│   ├── ENG-109: Create auth middleware
│   │   ├── ENG-110: Write failing test for token validation
│   │   └── ENG-111: Implement JWT validation
│   └── ENG-112: Create login endpoint
│       ├── ENG-113: Write failing test for login
│       └── ENG-114: Implement login handler
├── ENG-115: [Phase 3] Integration
│   └── ...
└── ENG-116: [Phase 4] Verification
    └── ...
```

Notice how each child is more specific than its parent, and leaf tasks are atomic.

## Step 1: Create Root Issue

The root issue is the feature/plan container.

**MCP Action:** Create issue in Linear

```markdown
## Root Issue Template

**Title:** [Feature] {Feature Name}
**Team:** {Team}
**Priority:** High
**Labels:** feature, plan

**Description:**

## Goal
{One sentence - what we're building}

## Why
{Business/user value}

## Success Criteria
- [ ] {Measurable criterion 1}
- [ ] {Measurable criterion 2}
- [ ] {Measurable criterion 3}

## Scope
**IN:** {What's included}
**OUT:** {What's excluded}

## Architecture
{2-3 sentences on approach}

## Dependencies
{External services, APIs, packages needed}

## Phases
1. {Phase 1 name}
2. {Phase 2 name}
3. {Phase 3 name}
4. Verification
```

## Step 2: Create Phase Issues

Each phase is a child issue of the root.

**MCP Action:** Create child issues under root

```markdown
## Phase Issue Template

**Title:** [Phase {N}] {Phase Name}
**Parent:** {Root Issue ID}
**Labels:** phase

**Description:**

## Objective
{What this phase accomplishes}

## Prerequisites
{What must be complete before starting}

## Deliverables
- {Deliverable 1}
- {Deliverable 2}

## Verification Checkpoint
{How to verify phase is complete}
```

## Step 3: Create Task Issues

Each task is an atomic, testable piece of work. **This is the most important step.**

**MCP Action:** Create leaf issues under phases

### Task Requirements

Every task issue MUST have:

1. **Single Action** - One atomic unit of working code
2. **Exact File Path** - Where the code goes
3. **Test First** - TDD order enforced
4. **Verification Command** - How to check it worked
5. **More Detail Than Parent** - Each level adds specificity

```markdown
## Task Issue Template

**Title:** {Action verb} {component} - {brief description}
**Parent:** {Phase Issue ID}
**Labels:** task

**Description:**

## Action
{Exactly what to do}

## File
`{exact/path/to/file.ts}`

## Test (Write First)
```typescript
test('{what we're testing}', () => {
  // Test code here
});
```

## Implementation
```typescript
// Implementation code here
```

## Verify
```bash
npm test -- path/to/file.test.ts
# Expected: 1 passed
```

## Done When
- [ ] Test written and failing
- [ ] Implementation passes test
- [ ] No lint errors
```

### Task Granularity

**Atomic = One unit of working code that makes sense on its own.**

Each child must be MORE specific than its parent:

```
ENG-106: Implement password hashing utility (concept)
├── ENG-107: Write failing test for hash function (test scope)
│   └── ENG-107a: Test hashPassword returns different value (single assertion)
│   └── ENG-107b: Test verifyPassword returns true for match (single assertion)
└── ENG-108: Implement bcrypt hashing (impl scope)
    └── ENG-108a: Add hashPassword function with bcrypt (single function)
    └── ENG-108b: Add verifyPassword function with compare (single function)
```

**Good tasks (atomic, specific):**
- "Test hashPassword returns different value than input"
- "Implement hashPassword function using bcrypt"
- "Add email format validation regex to user schema"

**Bad tasks (vague, multi-part):**
- "Implement authentication" ❌ (too big)
- "Add tests" ❌ (multiple tests bundled)
- "Fix the auth system" ❌ (unclear scope)

### TDD Task Pairs

For implementation work, create paired issues:

```
ENG-106: Implement password hashing utility
├── ENG-107: Write failing test for hash function
└── ENG-108: Implement bcrypt hashing to pass test
```

The test issue MUST be completed before the implementation issue.

## Step 4: Execute Tasks

Work through leaf issues in order.

### Before Starting a Task

1. **Check prerequisites** - Parent tasks complete?
2. **Read the issue** - Understand exactly what to do
3. **Update status** - Set to "In Progress"

### During Task Execution

1. **Follow TDD** - Test first, then implement
2. **Run verification** - Use the command in the issue
3. **Commit atomically** - One commit per task

### After Completing a Task

1. **Verify command passes** - Run the verification
2. **Update status** - Set to "Done"
3. **Add comment** - Note any deviations or learnings

```markdown
## Task Completion Comment

**Verified:** `npm test -- auth.test.ts` passes
**Commit:** abc1234
**Notes:** {Any deviations from plan}
```

## Step 5: Phase Verification

When all tasks in a phase are done:

1. **Run phase checkpoint** - Verification command from phase issue
2. **Review deliverables** - All listed items complete?
3. **Update phase status** - Set to "Done"
4. **Add summary comment** - What was accomplished

```markdown
## Phase Completion

**All tasks:** 5/5 complete
**Checkpoint:** All tests pass, migrations applied
**Ready for:** Phase 2
```

## Example: Full Plan

### Root Issue: ENG-100

```markdown
**Title:** [Feature] User Authentication System

## Goal
Implement secure user authentication with JWT tokens.

## Success Criteria
- [ ] Users can register with email/password
- [ ] Users can log in and receive JWT
- [ ] Protected routes require valid JWT
- [ ] Tokens refresh automatically

## Phases
1. Database Schema
2. Core Implementation
3. API Endpoints
4. Integration Testing
```

### Phase Issue: ENG-101

```markdown
**Title:** [Phase 1] Database Schema
**Parent:** ENG-100

## Objective
Create database tables for users and sessions.

## Deliverables
- users table with proper indexes
- sessions table for refresh tokens

## Verification
```bash
npm run migrate
npm run db:check
```
```

### Task Issue: ENG-102

```markdown
**Title:** Create users table migration
**Parent:** ENG-101

## Action
Create Prisma migration for users table.

## File
`prisma/migrations/001_create_users.sql`

## Implementation
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
```

## Verify
```bash
npx prisma migrate dev
# Expected: Migration applied successfully
```

## Done When
- [ ] Migration file created
- [ ] Migration applied successfully
- [ ] Table exists in database
```

### Task Issue: ENG-107 (Test-First)

```markdown
**Title:** Write failing test for hash function
**Parent:** ENG-106

## Action
Write test that verifies password hashing works correctly.

## File
`src/utils/__tests__/password.test.ts`

## Test
```typescript
import { hashPassword, verifyPassword } from '../password';

describe('password utilities', () => {
  test('hashPassword returns different value than input', async () => {
    const password = 'testPassword123';
    const hash = await hashPassword(password);

    expect(hash).not.toBe(password);
    expect(hash.length).toBeGreaterThan(50);
  });

  test('verifyPassword returns true for correct password', async () => {
    const password = 'testPassword123';
    const hash = await hashPassword(password);

    const isValid = await verifyPassword(password, hash);
    expect(isValid).toBe(true);
  });

  test('verifyPassword returns false for wrong password', async () => {
    const hash = await hashPassword('correct');

    const isValid = await verifyPassword('wrong', hash);
    expect(isValid).toBe(false);
  });
});
```

## Verify
```bash
npm test -- password.test.ts
# Expected: FAIL (module not found)
```

## Done When
- [ ] Test file created
- [ ] Test runs and FAILS (red phase)
```

### Task Issue: ENG-108 (Implementation)

```markdown
**Title:** Implement bcrypt hashing to pass test
**Parent:** ENG-106
**Blocked By:** ENG-107

## Action
Implement password hashing with bcrypt.

## File
`src/utils/password.ts`

## Implementation
```typescript
import bcrypt from 'bcrypt';

const SALT_ROUNDS = 12;

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, SALT_ROUNDS);
}

export async function verifyPassword(
  password: string,
  hash: string
): Promise<boolean> {
  return bcrypt.compare(password, hash);
}
```

## Verify
```bash
npm test -- password.test.ts
# Expected: 3 passed
```

## Done When
- [ ] Implementation file created
- [ ] All tests pass (green phase)
- [ ] No TypeScript errors
```

## MCP Tool Usage

When creating plans, use Linear MCP to:

### Create Root Issue
```
Create issue in team [X] with title "[Feature] ..." and description [full template]
```

### Create Child Issue
```
Create issue with parent [ID] with title "[Phase N] ..." and description [template]
```

### Create Task Issue
```
Create issue with parent [ID] with title "..." and description [task template]
```

### Update Status
```
Update issue [ID] status to "In Progress" / "Done"
```

### Add Comment
```
Add comment to issue [ID]: "Verification passed: ..."
```

## Integration with Jarvis

### Branch Naming
```
feature/ENG-100-user-auth
```

### Commit Messages
```
feat(auth): add password hashing

Implements bcrypt hashing with 12 salt rounds.

Closes ENG-108
```

### Session Files
Reference Linear in session state:
```markdown
## Linear Context
**Root:** ENG-100 - User Authentication
**Current Phase:** ENG-105 (Phase 2)
**Active Task:** ENG-107 (Writing test)
**Progress:** 4/12 tasks complete
```

## Quick Reference

```
ROOT ISSUE    -> [Feature] title, full context, phases listed
PHASE ISSUE   -> [Phase N] title, objective, checkpoint
TASK ISSUE    -> Action verb title, single file, test + impl, verify cmd

HIERARCHY     -> Each child more specific than parent
ATOMIC        -> One unit of working code per task
TDD ORDER     -> Test issue → Implementation issue (blocked by test)
VERIFICATION  -> Every task has runnable verify command

STATUS FLOW   -> Backlog → Todo → In Progress → Done
COMPLETION    -> Verify passes + commit + status update + comment
```

## Red Flags - STOP

- Task does multiple things → Break it down
- Child is not more specific than parent → Add detail
- No verify command → Add one
- "Implement X" without breakdown → Create subtasks
- Skipping test issue → Never skip TDD
- No exact file path → Be specific

## Integration with Other Skills

**Pairs with:**
- **tdd** - Each task enforces test-first order
- **session-management** - Track Linear plan progress in session checkpoints
- **executing-plans** - Use Linear issues as the execution plan instead of markdown
- **verification** - Document verification results in task comments
- **brainstorming** - Capture feature requirements before creating Linear plan

**Command reference:**
- Use `/linear` command for quick operations (create, list, mark done)
- Use `skill: "linear"` to access detailed planning workflow
