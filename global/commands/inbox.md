---
name: inbox
description: View and manage captured learnings and pending items
disable-model-invocation: false
---

# /inbox - Learnings Inbox

View and manage items captured during development that need review or action.

## What It Does

1. **Shows pending learnings** - Displays captured patterns, fixes, insights
2. **Allows processing** - Promote to patterns, rules, or dismiss
3. **Tracks review status** - Shows what needs attention
4. **Suggests actions** - Recommends how to process items

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | Optional filter or action | "patterns", "process 3", "dismiss 5" |

## Process

### Phase 1: Load Inbox

1. **Read inbox files**
   - Check `~/.claude/learning/inbox/`
   - Check `[project]/.claude/inbox/`
   - Sort by date captured

2. **Categorize items**
   - Patterns discovered
   - Bug fixes applied
   - Configuration changes
   - Code improvements
   - Documentation updates

### Phase 2: Display

3. **Show inbox summary**

```markdown
## Inbox Summary

**Total items:** 12
**Unprocessed:** 8
**This week:** 5

### By Category
| Category | Count | Oldest |
|----------|-------|--------|
| Patterns | 4 | 3 days ago |
| Bug Fixes | 2 | 1 day ago |
| Improvements | 2 | Today |

### Recent Items

1. [pattern] React error boundary pattern
   Captured: 2026-01-05
   Context: Fixed crash in dashboard component

2. [fix] Database connection retry logic
   Captured: 2026-01-05
   Context: Resolved intermittent connection failures

3. [improvement] API response caching
   Captured: 2026-01-04
   Context: Improved performance by 40%
```

### Phase 3: Actions

4. **Process items**

**Promote to pattern:**
```
/inbox promote 1
```
Moves item to patterns library with full documentation.

**Add as rule:**
```
/inbox rule 2
```
Creates a new rule from the learning.

**Dismiss:**
```
/inbox dismiss 3
```
Archives item without action.

**Review:**
```
/inbox review 4
```
Shows full details of item for review.

## Usage Modes

### View all items
```
/inbox
```

### Filter by category
```
/inbox patterns
/inbox fixes
/inbox improvements
```

### Process specific item
```
/inbox process 3
```
Interactive processing of item #3.

### Bulk actions
```
/inbox dismiss-old 30
```
Dismisses items older than 30 days.

### Search
```
/inbox search "database"
```
Finds items matching search term.

## Inbox Item Structure

Each inbox item contains:

```json
{
  "id": "inbox-2026-01-05-001",
  "type": "pattern",
  "title": "React error boundary pattern",
  "description": "Discovered effective pattern for handling component errors",
  "context": {
    "file": "src/components/Dashboard.tsx",
    "commit": "abc123",
    "date": "2026-01-05"
  },
  "content": "// Pattern code or description",
  "suggested_action": "promote_to_pattern",
  "confidence": 0.85,
  "status": "pending"
}
```

## Processing Workflow

1. **Review item** - Understand what was captured
2. **Decide action** - Promote, rule, or dismiss
3. **Enhance** - Add details if promoting
4. **Confirm** - Verify the action
5. **Complete** - Item moved to appropriate location

## Examples

**View inbox:**
```
/inbox
```

**View only patterns:**
```
/inbox patterns
```

**Promote item to pattern library:**
```
/inbox promote 1
```

**Create rule from fix:**
```
/inbox rule 2
```

**Dismiss irrelevant item:**
```
/inbox dismiss 3
```

**Search inbox:**
```
/inbox search "typescript"
```

**Clean old items:**
```
/inbox cleanup
```

## File Locations

| Location | Purpose |
|----------|---------|
| `~/.claude/learning/inbox/` | Global inbox items |
| `[project]/.claude/inbox/` | Project-specific items |
| `~/.claude/patterns/` | Promoted patterns |
| `~/.claude/rules/` | Promoted rules |
