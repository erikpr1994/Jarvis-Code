---
name: execute
description: Execute an implementation plan with verification checkpoints
---

# /execute - Execute Implementation Plan

Execute a structured implementation plan with verification checkpoints and progress tracking.

## Delegates To

This command invokes the **executing-plans** skill for full methodology.

## Quick Reference

| Action | Command |
|--------|---------|
| Execute plan | `/execute docs/plans/plan-auth.md` |
| Resume from phase | `/execute plan.md --from-phase 2` |
| Dry run | `/execute plan.md --dry-run` |
| List plans | `/execute --list` |

## Arguments

| Argument | Description |
|----------|-------------|
| `$ARGUMENTS` | Path to plan file |
| `--from-phase N` | Resume from phase N |
| `--dry-run` | Preview without changes |
| `--verbose` | Detailed output |
| `--list` | List available plans |

## Process Overview

```
1. LOAD     → Parse plan file, extract phases/tasks
2. VALIDATE → Check prerequisites and dependencies
3. EXECUTE  → Work through tasks systematically
4. VERIFY   → Run checkpoint at each phase boundary
5. REPORT   → Generate completion summary
```

## Examples

```bash
# Execute a plan
/execute docs/plans/plan-user-profile.md

# Resume from phase 2
/execute plan-auth.md --from-phase 2

# Preview what would happen
/execute plan-refactor.md --dry-run
```

## Workflow

```
/plan [feature]     → Create plan
/execute [plan]     → Execute with checkpoints
/commit             → Commit changes
```

## See Also

- **Full methodology**: `skill: "executing-plans"`
- **Create plans**: `/plan`
- **Review changes**: `/jarvis-review`
