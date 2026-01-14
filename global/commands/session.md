---
name: session
description: Manage work sessions to maintain context across conversations
---

# /session - Manage Work Sessions

Manage long-running work sessions to preserve context, track progress, and facilitate handoffs.

## Delegates To

This command invokes the **session-management** skill for full methodology.

## Quick Reference

| Action | Command |
|--------|---------|
| New session | `/session new "Feature Name"` |
| List sessions | `/session list` |
| Resume work | `/session resume` |
| Archive done | `/session archive` |
| Check status | `/session status` |

## Arguments

| Argument | Description |
|----------|-------------|
| `new [name]` | Create new session file |
| `list` | List available sessions |
| `resume [file]` | Load session context |
| `archive` | Archive current session |
| `status` | Show current session status |

## Session Location

Sessions are stored in `.claude/tasks/`:
- Active: `session-current.md`
- Archived: `session-[date]-[slug].md`

## Examples

```bash
# Start new work
/session new "Implement User Profile"

# Resume previous session
/session resume

# List all sessions
/session list

# Archive completed work
/session archive
```

## Workflow

```
/session new [goal]    → Start tracking
/plan [feature]        → Create implementation plan
/execute [plan]        → Do the work
/session archive       → Save learnings
```

## See Also

- **Full methodology**: `skill: "session-management"`
- **Create plans**: `/plan`
- **Track learnings**: `/learnings`
