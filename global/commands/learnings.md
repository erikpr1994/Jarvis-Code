---
name: learnings
description: View and search captured learnings across all projects
disable-model-invocation: false
---

# /learnings - View Captured Learnings

Browse, search, and manage all learnings captured across projects and sessions.

## What It Does

1. **Aggregates learnings** - Collects from global and project sources
2. **Enables search** - Find specific learnings by keyword
3. **Shows trends** - Identifies frequently captured patterns
4. **Supports export** - Share learnings across projects

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | Search term, filter, or action | "typescript", "recent", "export" |

## Process

### Phase 1: Collection

1. **Gather learnings**
   - `~/.claude/learning/` - Global learnings
   - `[project]/.claude/learnings/` - Project learnings
   - Git history analysis - Code patterns
   - Session logs - Captured insights

2. **Categorize**
   - By type: patterns, fixes, tips, gotchas
   - By domain: frontend, backend, database, infra
   - By language: typescript, python, sql, etc.
   - By date: today, this week, this month

### Phase 2: Display

3. **Show learnings summary**

```markdown
## Learnings Library

**Total learnings:** 156
**This month:** 23
**Top category:** TypeScript patterns (45)

### Recent Learnings

1. **TypeScript: Discriminated unions for API responses**
   Added: 2026-01-05
   Used: 12 times
   ```typescript
   type ApiResponse<T> =
     | { success: true; data: T }
     | { success: false; error: string }
   ```

2. **React: Optimistic updates pattern**
   Added: 2026-01-04
   Used: 8 times
   Pattern for immediate UI feedback with rollback.

3. **Supabase: RLS policy for team access**
   Added: 2026-01-03
   Used: 5 times
   Team-based row level security pattern.

### Most Used

| Learning | Times Used | Category |
|----------|------------|----------|
| Error boundary pattern | 45 | React |
| API response types | 38 | TypeScript |
| Database retry logic | 22 | Backend |
```

### Phase 3: Search & Filter

4. **Search capabilities**

```
/learnings typescript generics
```
Returns learnings matching "typescript" AND "generics"

```
/learnings --category react
```
Returns all React-related learnings

```
/learnings --recent 7
```
Returns learnings from last 7 days

## Usage Modes

### View all learnings
```
/learnings
```

### Search by keyword
```
/learnings "error handling"
```

### Filter by category
```
/learnings --category typescript
/learnings --category database
```

### View recent
```
/learnings recent
/learnings --since 2026-01-01
```

### View most used
```
/learnings popular
/learnings --sort usage
```

### Export learnings
```
/learnings export typescript
```
Exports TypeScript learnings to shareable format.

### Add learning manually
```
/learnings add
```
Interactive prompt to add a new learning.

## Learning Structure

```json
{
  "id": "learn-2026-01-05-001",
  "title": "TypeScript discriminated unions",
  "description": "Use discriminated unions for type-safe API responses",
  "category": "typescript",
  "tags": ["types", "api", "patterns"],
  "content": "// Code example or detailed description",
  "usage_count": 12,
  "created_at": "2026-01-05",
  "last_used": "2026-01-06",
  "source": {
    "type": "auto_capture",
    "context": "Working on API client"
  }
}
```

## Examples

**View all learnings:**
```
/learnings
```

**Search for database patterns:**
```
/learnings database
```

**View TypeScript learnings:**
```
/learnings --category typescript
```

**View popular learnings:**
```
/learnings popular
```

**Export for sharing:**
```
/learnings export --format md
```

**Add new learning:**
```
/learnings add "Always use transactions for multi-table updates"
```

## Categories

| Category | Description |
|----------|-------------|
| typescript | TypeScript patterns and tips |
| react | React patterns and hooks |
| nextjs | Next.js specific learnings |
| database | Database patterns and queries |
| testing | Testing patterns and strategies |
| git | Git workflows and commands |
| devops | CI/CD and infrastructure |
| security | Security best practices |
| performance | Optimization techniques |

## File Locations

| Location | Purpose |
|----------|---------|
| `~/.claude/learning/` | Global learnings |
| `[project]/.claude/learnings/` | Project learnings |
| `~/.claude/learning/capture.sh` | Capture script |
| `~/.claude/learning/auto-update.sh` | Auto-update system |
