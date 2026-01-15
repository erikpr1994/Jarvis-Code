---
name: linear
description: Plan and track features using Linear's hierarchical issues (replaces markdown plans)
disable-model-invocation: false
---

# /linear - Plan with Linear

Create and execute implementation plans using Linear's hierarchical issues instead of markdown files.

## When to Use

- Starting a new feature or multi-phase implementation
- Need to break down large work into atomic tasks
- Want execution tracking within Linear instead of markdown
- Coordinating work across phases or team members

## Setup (First Time)

```bash
# Authenticate via MCP (run once)
/mcp
# Follow OAuth prompts
```

## Commands

### Planning Commands

```bash
# Create a new feature plan
/linear plan "Feature Name"

# View all active plans
/linear plans

# View hierarchical plan structure
/linear tree ENG-100
```

### Execution Commands

```bash
# Start next unassigned task
/linear next

# Start a specific task
/linear start ENG-107

# Complete current task (with verification)
/linear done ENG-107

# View your assigned tasks
/linear tasks
```

### Progress Commands

```bash
# View plan progress
/linear progress ENG-100

# View current sprint cycle
/linear cycle

# Add comment to task (after verification)
/linear comment ENG-107 "Verified: npm test passes"
```

## Quick Reference

| Command | Purpose |
|---------|---------|
| `/linear plan "X"` | Create new feature plan |
| `/linear plans` | List all active plans |
| `/linear tree ID` | View plan hierarchy |
| `/linear next` | Start next task in queue |
| `/linear start ID` | Start specific task |
| `/linear done` | Mark current task complete |
| `/linear progress ID` | Check plan completion |
| `/linear tasks` | View your assignments |
| `/linear cycle` | View current sprint |

## How Plans Are Structured

Each plan creates a hierarchy in Linear:

```
ENG-100: [Feature] Feature Name
├── ENG-101: [Phase 1] Phase Name
│   ├── ENG-102: Write test for component
│   ├── ENG-103: Implement component
│   └── ENG-104: Integrate with page
├── ENG-105: [Phase 2] Next Phase
│   └── ...
└── ENG-106: [Phase 4] Verification
    └── ...
```

Every leaf task is atomic and testable—it contains exactly what to do, which file to edit, test code, and a verification command.

## Detailed Workflow

For the complete planning workflow, including:
- How issues are created and structured
- Task format and requirements
- TDD ordering and verification
- Integration patterns
- Full examples with code

See the **linear skill** (`skill: "linear"`).

## Example Usage

**Start a feature:**
```bash
/linear plan "User Authentication System"
```

**See what needs work:**
```bash
/linear next
```

**Mark it complete:**
```bash
/linear done
```

**Check overall progress:**
```bash
/linear progress ENG-100
```
