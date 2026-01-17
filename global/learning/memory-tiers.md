# Memory Tiers System

> Part of the [Jarvis Learning System](./README.md)

## Overview

The memory tiers system manages learnings based on recency, relevance, and scope. This prevents context overload while ensuring critical learnings are always accessible.

## Tier Definitions

### Hot Memory (Immediate Access)

**Location:** Session context, always loaded
**Retention:** Current session only
**Access:** Automatic, no lookup required

| Content Type | Example |
|--------------|---------|
| Active corrections | "User prefers X over Y" (said this session) |
| In-progress patterns | Pattern being established |
| Session preferences | Formatting choices made today |
| Recent errors | Mistakes to avoid immediately |

**Characteristics:**
- Instantly available in context
- Expires at session end
- Highest priority for application
- No storage overhead

### Warm Memory (Quick Access)

**Location:** `~/.jarvis/learnings/` and `.claude/learnings/`
**Retention:** 7-30 days active, then review
**Access:** Loaded on session start or skill activation

| Content Type | Example |
|--------------|---------|
| Established preferences | Confirmed coding style choices |
| Validated patterns | Patterns with 3+ occurrences |
| Active project context | Current project conventions |
| Recent skills updates | Skills modified this month |

**Characteristics:**
- Loaded when relevant context detected
- Periodically reviewed for promotion/demotion
- Moderate storage footprint
- Triggers skill activation when matched

### Cold Memory (Archive Access)

**Location:** `~/.jarvis/archive/` and version control
**Retention:** Indefinite
**Access:** Explicit search or historical reference

| Content Type | Example |
|--------------|---------|
| Historical patterns | Old project conventions |
| Deprecated preferences | Superseded by newer preferences |
| Archived sessions | Completed project sessions |
| Skill evolution history | Previous skill versions |

**Characteristics:**
- Not loaded automatically
- Searchable on demand
- Minimal impact on active context
- Preserved for reference and rollback

## Tier Transitions

```
                    Promotion
     ┌────────────────────────────────────────┐
     │                                        │
     ▼                                        │
┌─────────┐         ┌──────────┐         ┌─────────┐
│   HOT   │ ──────► │   WARM   │ ──────► │  COLD   │
│ Memory  │         │  Memory  │         │ Memory  │
└─────────┘         └──────────┘         └─────────┘
     │                    │                   │
     │                    │                   │
     └─────── Demotion ───┴───────────────────┘
```

### Promotion Criteria (Cold → Warm → Hot)

| From → To | Trigger | Criteria |
|-----------|---------|----------|
| Cold → Warm | Pattern match | Archived learning matches current context |
| Warm → Hot | Session activation | Learning relevant to current task |
| Cold → Hot | Explicit recall | User asks to apply old learning |

### Demotion Criteria (Hot → Warm → Cold)

| From → To | Trigger | Criteria |
|-----------|---------|----------|
| Hot → Warm | Session end | Learning persists beyond session |
| Warm → Cold | Inactivity | No matches for 30+ days |
| Hot → Cold | User rejection | User explicitly disagrees |

## Memory Structure

### Hot Memory Format

Stored in session context as structured prompts:

```markdown
## Active Learnings (This Session)

### Corrections
- [10:30] Use `const` instead of `let` for immutable bindings
- [11:15] Prefer explicit return types over inference

### Patterns In Progress
- Server action error handling (2 occurrences, watching)

### Avoid
- Using default exports (user corrected twice)
```

### Warm Memory Format

Stored as JSON in learnings directory:

```json
{
  "warm_memory": {
    "preferences": [
      {
        "id": "pref_001",
        "description": "Always use explicit TypeScript return types",
        "confidence": 0.95,
        "last_accessed": "2026-01-04",
        "access_count": 15,
        "source": "multiple_corrections"
      }
    ],
    "patterns": [
      {
        "id": "pat_001",
        "description": "Error handling with toast notifications in server actions",
        "confidence": 0.87,
        "last_accessed": "2026-01-03",
        "access_count": 8,
        "source": "code_repetition"
      }
    ],
    "context": {
      "current_project": "jarvis",
      "active_skills": ["session", "git-commits"],
      "recent_files": ["app/actions/*.ts"]
    }
  }
}
```

### Cold Memory Format

Archived in compressed, dated files:

```
~/.jarvis/archive/
├── 2025-Q4/
│   ├── learnings.json.gz
│   ├── patterns.json.gz
│   └── sessions/
│       ├── session-001.md.gz
│       └── session-002.md.gz
└── 2026-Q1/
    └── learnings.json.gz
```

## Access Patterns

### Session Start

1. Load all warm memory into context-aware cache
2. Initialize hot memory as empty
3. Set up pattern matchers for warm → hot promotion

```bash
# Pseudocode for session start
warm_memory = load_warm_memory()
hot_memory = {}
pattern_matchers = compile_patterns(warm_memory.patterns)
```

### During Session

1. Match user prompts against warm memory patterns
2. Promote matched learnings to hot memory
3. Capture new learnings into hot memory
4. Track access counts for priority scoring

```bash
# On each user prompt
for pattern in warm_memory.patterns:
    if pattern.matches(user_prompt):
        hot_memory.add(pattern)
        pattern.access_count++
```

### Session End

1. Persist hot memory learnings to warm memory
2. Score and consolidate learnings
3. Trigger demotion checks for inactive warm memory
4. Archive if thresholds exceeded

## Scoring System

### Confidence Score (0.0 - 1.0)

Determines learning reliability:

| Factor | Weight | Description |
|--------|--------|-------------|
| Frequency | 0.30 | How often pattern occurs |
| Recency | 0.25 | How recently accessed |
| User Confirmation | 0.25 | Explicit user approval |
| Consistency | 0.20 | No contradictions |

```
confidence = (frequency * 0.30) + (recency * 0.25) +
             (confirmation * 0.25) + (consistency * 0.20)
```

### Priority Score (1-100)

Determines loading order:

```
priority = (confidence * 50) + (access_count * 30) + (recency_bonus * 20)
```

## Capacity Management

### Hot Memory Limits

| Limit Type | Value | Action When Exceeded |
|------------|-------|---------------------|
| Max items | 20 | Demote lowest priority |
| Max tokens | ~2000 | Summarize older items |
| Session age | Session end | All demoted to warm |

### Warm Memory Limits

| Limit Type | Value | Action When Exceeded |
|------------|-------|---------------------|
| Max items | 500 | Archive lowest priority |
| Max age | 90 days inactive | Archive to cold |
| Storage | 10MB | Compress older items |

### Cold Memory Limits

| Limit Type | Value | Action When Exceeded |
|------------|-------|---------------------|
| Storage | Unlimited | Compression applied |
| Retention | Indefinite | Only deleted manually |

## Conflict Resolution

When learnings conflict:

1. **Recency wins** - More recent learning takes precedence
2. **Explicit wins** - User-stated preference beats inferred
3. **Specific wins** - Project-specific beats global
4. **Merge if compatible** - Combine non-contradictory aspects

```json
{
  "conflict_resolution": {
    "learning_a": "pref_001",
    "learning_b": "pref_015",
    "resolution": "recency",
    "winner": "pref_015",
    "reason": "More recent user preference"
  }
}
```

## Garbage Collection

### Daily Cleanup

- Remove expired hot memory items (handled by session end)
- Update access counts and recency scores
- Flag candidates for demotion

### Weekly Review

- Demote inactive warm memory (no access in 14+ days)
- Archive warm memory to cold (no access in 30+ days)
- Compress cold memory older than 90 days
- Generate memory health report

### Manual Cleanup

```bash
# Review memory usage
jarvis memory status

# Force cleanup
jarvis memory gc --dry-run  # Preview
jarvis memory gc            # Execute

# Archive specific items
jarvis memory archive --older-than 30d

# Restore from archive
jarvis memory restore --id pat_001
```

## Integration Points

### With Capture System

- Capture system writes to hot memory during session
- Hot memory promotes to warm on session end
- Capture triggers scoring recalculation

### With Auto-Update System

- Warm memory patterns feed into skill suggestions
- High-confidence learnings become skill candidates
- Applied learnings marked in memory tier

### With Skill System

- Skills can reference memory tiers for context
- Skill activation can promote relevant cold memory
- Skill application updates learning access counts

## Monitoring

### Memory Health Metrics

```bash
jarvis memory health

# Output:
# Hot Memory:  12/20 items (60% capacity)
# Warm Memory: 156/500 items (31% capacity)
# Cold Memory: 2.3MB (34 archived sessions)
#
# Pending demotions: 8 items (inactive 14+ days)
# Pending promotions: 3 items (high access)
# Conflicts: 0
```

### Access Logs

```json
{
  "access_log": [
    {
      "timestamp": "2026-01-04T10:30:00Z",
      "learning_id": "pref_001",
      "action": "promoted",
      "from_tier": "warm",
      "to_tier": "hot",
      "trigger": "pattern_match"
    }
  ]
}
```
