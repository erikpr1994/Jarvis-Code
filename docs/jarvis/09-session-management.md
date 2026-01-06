# Session & Context Management

> Part of the [Jarvis Specification](./README.md)

## 11. Session & Context Management

### 11.1 Session State Structure

```markdown
# Session: [timestamp]

## Status
- Phase: [planning|implementing|reviewing|complete]
- Active Task: [task description]
- Branch: [branch name]

## Context
- Project: [project name]
- Tech Stack: [detected stack]
- Active Skills: [list of loaded skills]

## Progress
- [ ] Task 1
- [x] Task 2 (completed)
- [ ] Task 3

## Decisions
- Decision 1: [rationale]
- Decision 2: [rationale]

## Research Notes
[accumulated research]

## Learnings
[patterns discovered this session]
```

### 11.2 Context Persistence Strategy

| Source | Purpose | Loading |
|--------|---------|---------|
| **Session file** | Current work state | Always on resume |
| **Memory MCP** | Long-term memory | Relevance-scored retrieval |
| **Docs files** | Spec/design/plan | On explicit reference |
| **Pattern index** | Available patterns | Always (summaries) |

### 11.3 Memory MCP Strategy

**Problem**: Memory MCP can bloat context
**Solution**: Tiered retrieval system

| Tier | Content | Loading |
|------|---------|---------|
| **Hot** | Last 24h, current project | Always in context |
| **Warm** | Last week, related projects | On relevance score >0.7 |
| **Cold** | Older memories | On explicit search only |

### 11.4 Session Continuation Detection

```bash
# Smart detect logic
if [ "$(last_session_age)" -lt "4_hours" ] && [ "$(has_active_tasks)" = "true" ]; then
  # Continue previous session
  load_session_file
  echo "Continuing session from [timestamp]"
else
  # Fresh start
  create_new_session
  ask "What are you working on today?"
fi
```

### 11.5 Pre-Compaction Preservation

When context reaches ~80% capacity:
1. Summarize current session state
2. Archive detailed notes to session file
3. Preserve critical context (active task, decisions, blockers)
4. Clear non-essential context
5. Continue with preserved state
