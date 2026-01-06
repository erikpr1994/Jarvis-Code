---
name: session
description: Manage work sessions (new, list, resume, archive) to maintain context across conversations
disable-model-invocation: false
---

# /session - Manage Work Sessions

Manage long-running work sessions to preserve context, track progress, and facilitate handoffs.

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `new` | Create a new session file | `/session new "Refactor Auth"` |
| `list` | List available sessions | `/session list` |
| `resume` | Load specific session context | `/session resume session-001.md` |
| `archive` | Archive current session | `/session archive` |
| `status` | Show current session status | `/session status` |

## Usage

### Start a New Session

```bash
/session new "Feature: Dark Mode"
```
Creates `.claude/tasks/session-current.md` from template and initializes it with the goal.

### List Sessions

```bash
/session list
```
Shows all session files in `.claude/tasks/` with their status.

### Resume a Session

```bash
/session resume session-current.md
```
Reads the session file and loads critical context (Current State, Next Action) into memory.

### Archive a Session

```bash
/session archive
```
Renames `session-current.md` to `session-[timestamp]-[slug].md` and extracts learnings.

## Process

The `/session` command delegates to the **session-management** skill.

1. **Check for .claude/tasks/** directory
   - Create if missing

2. **Execute Action**
   - **new**: Copy template, replace placeholders, open for editing
   - **list**: `ls -la .claude/tasks/`
   - **resume**: `read .claude/tasks/[file]`
   - **archive**: `mv .claude/tasks/session-current.md .claude/tasks/session-[date]-[slug].md`

## Examples

**Starting fresh:**
```
/session new "Implement User Profile"
```

**Resuming work:**
```
/session resume
> Found active session: session-current.md
> Last action: Created database schema
> Next action: Implement API endpoints
```

**Cleaning up:**
```
/session archive
> Session archived to session-2024-01-15-user-profile.md
```
