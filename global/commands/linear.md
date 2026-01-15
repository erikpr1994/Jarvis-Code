---
name: linear
description: Plan and track features using Linear's hierarchical issues (replaces markdown plans)
disable-model-invocation: false
---

# /linear - Plan with Linear

Create and execute implementation plans using Linear's hierarchical issues instead of markdown files.

## What It Does

1. **Plan** - Create feature plans as hierarchical Linear issues
2. **Execute** - Work through tasks with TDD enforcement
3. **Track** - Update status and verify completion
4. **View** - Check progress on plans and tasks

## Setup (First Time)

```bash
# Authenticate via MCP (run once)
/mcp
# Follow OAuth prompts
```

## Usage

### Create a Plan

```bash
# Start planning a feature
/linear plan "User Authentication"

# With team specified
/linear plan "User Authentication" --team Engineering
```

This creates:
1. **Root issue** - `[Feature] User Authentication`
2. **Phase issues** - `[Phase 1] Database`, `[Phase 2] Core`, etc.
3. **Task issues** - Atomic, testable tasks under each phase

### View Plans

```bash
# List active plans
/linear plans

# View specific plan
/linear plan ENG-100

# View plan tree
/linear tree ENG-100
```

### Execute Tasks

```bash
# Start next task
/linear next

# Start specific task
/linear start ENG-107

# Mark task done (with verification)
/linear done ENG-107

# Add comment to task
/linear comment ENG-107 "Verified: npm test passes"
```

### View Progress

```bash
# My current tasks
/linear tasks

# Plan progress
/linear progress ENG-100

# Current cycle
/linear cycle
```

## Plan Creation Flow

When you run `/linear plan "Feature Name"`:

### Step 1: Gather Context

Claude asks:
- What's the goal?
- What are the success criteria?
- What's in/out of scope?

### Step 2: Research

Claude:
- Reads relevant codebase files
- Identifies existing patterns
- Checks dependencies

### Step 3: Create Structure

Claude creates in Linear:

```
ENG-100: [Feature] Feature Name
├── ENG-101: [Phase 1] Foundation
│   ├── ENG-102: Task 1 (test)
│   ├── ENG-103: Task 1 (impl)
│   └── ...
├── ENG-104: [Phase 2] Core
│   └── ...
├── ENG-105: [Phase 3] Integration
│   └── ...
└── ENG-106: [Phase 4] Verification
    └── ...
```

### Step 4: Confirm

Claude shows the plan tree and asks for approval before execution.

## Task Format

Every task issue contains:

```markdown
## Action
{Exactly what to do}

## File
`exact/path/to/file.ts`

## Test (or Implementation)
```typescript
// Complete code
```

## Verify
```bash
npm test -- file.test.ts
# Expected: PASS
```
```

## Execution Flow

When executing tasks:

1. **Pick task** - `/linear next` or `/linear start ENG-XXX`
2. **Read issue** - Claude shows task details
3. **Execute** - Claude follows TDD (test → implement)
4. **Verify** - Run verification command
5. **Complete** - `/linear done ENG-XXX` updates status

## Examples

**Create auth feature plan:**
```
/linear plan "JWT Authentication"
```

**View current plan tree:**
```
/linear tree ENG-100
```

**Start working on next task:**
```
/linear next
```

**Complete current task:**
```
/linear done
```

**Check plan progress:**
```
/linear progress ENG-100
```

## Quick Reference

| Command | Action |
|---------|--------|
| `/linear plan "X"` | Create new plan |
| `/linear plans` | List active plans |
| `/linear tree ID` | View plan hierarchy |
| `/linear next` | Start next task |
| `/linear start ID` | Start specific task |
| `/linear done` | Complete current task |
| `/linear progress ID` | View plan progress |
| `/linear tasks` | My assigned tasks |
| `/linear cycle` | Current sprint |

## Loads Skill

This command loads the `linear` skill for detailed planning workflow and templates.
