# Jarvis Learning System

> Self-improving AI assistant through captured learnings

## Overview

The Jarvis Learning System enables continuous improvement by capturing corrections, preferences, and successful patterns during sessions. Unlike static configuration, this system evolves based on actual usage, making Jarvis increasingly effective over time.

## Core Principles

1. **Learn from Corrections** - When users correct behavior, capture it for future reference
2. **Detect Patterns** - Recognize repeated code structures and workflows for skill creation
3. **Tiered Memory** - Manage learnings by recency and relevance to avoid context overload
4. **TDD for Skills** - Validate learnings before applying them to ensure quality
5. **Rollback Safety** - All changes are versioned and reversible

## System Components

```
learning/
├── README.md           # This overview
├── capture.md          # How learnings are detected and captured
├── memory-tiers.md     # Hot/warm/cold memory management
└── auto-update.sh      # Script for applying validated learnings
```

### Capture System

The capture system identifies learnable moments during sessions:

| Trigger | Example | Capture Action |
|---------|---------|----------------|
| User Correction | "No, use X instead" | Record preference |
| Repeated Pattern | Same code structure 3x | Flag for skill creation |
| Manual Guidance | Explained same thing twice | Suggest automation |
| Successful Resolution | Complex bug fixed | Document approach |

See [capture.md](./capture.md) for detailed capture protocols.

### Memory Tiers

Learnings are organized by accessibility needs:

| Tier | Access | Contents | Retention |
|------|--------|----------|-----------|
| **Hot** | Always loaded | Current session learnings | Session only |
| **Warm** | Quick lookup | Validated patterns, active preferences | 30 days active |
| **Cold** | Archive search | Historical learnings, old sessions | Indefinite |

See [memory-tiers.md](./memory-tiers.md) for tier management details.

### Auto-Update System

Applies validated learnings to skills and patterns:

```bash
# Review pending learnings
./auto-update.sh review

# Validate a learning using TDD approach
./auto-update.sh validate pat_001

# Apply validated learning
./auto-update.sh apply pat_001

# Rollback if issues occur
./auto-update.sh rollback pat_001

# Check system status
./auto-update.sh status
```

See [auto-update.sh](./auto-update.sh) for full command reference.

## Workflow

```
SESSION                           BETWEEN SESSIONS
   │                                     │
   ▼                                     ▼
┌─────────────┐                   ┌─────────────┐
│   DETECT    │                   │   REVIEW    │
│  Learnings  │                   │  Captured   │
└─────────────┘                   └─────────────┘
       │                                 │
       ▼                                 ▼
┌─────────────┐                   ┌─────────────┐
│   CAPTURE   │                   │  VALIDATE   │
│  To Memory  │ ──── persist ───► │  (TDD)      │
└─────────────┘                   └─────────────┘
       │                                 │
       ▼                                 ▼
┌─────────────┐                   ┌─────────────┐
│   APPLY     │ ◄─── approved ─── │   APPLY     │
│  Hot Memory │                   │  Skills/    │
└─────────────┘                   │  Patterns   │
                                  └─────────────┘
```

## Learning Storage

### Project-Level Learnings

```
.claude/
└── learnings/
    └── project.json     # Project-specific patterns and preferences
```

### Global Learnings

```
~/.jarvis/
├── learnings/
│   └── global.json      # Cross-project learnings
├── patterns/
│   └── *.md             # Applied patterns
├── rules/
│   └── preferences.json # Applied preferences
├── backups/
│   └── *.json           # Rollback snapshots
└── archive/
    └── YYYY-QN/         # Cold storage
```

## Learning Format

```json
{
  "learnings": {
    "2026-01-04": {
      "patterns": [
        {
          "id": "pat_001",
          "type": "code_pattern",
          "description": "Server action error handling",
          "frequency": 5,
          "status": "suggested",
          "context": { "files": ["app/actions/*.ts"] }
        }
      ],
      "corrections": [
        {
          "id": "cor_001",
          "type": "user_preference",
          "description": "Prefer explicit return types",
          "original": "const fn = () => {}",
          "corrected": "const fn = (): void => {}"
        }
      ],
      "workflows": [
        {
          "id": "wf_001",
          "type": "workflow_improvement",
          "description": "PR review pipeline",
          "steps_before": 8,
          "steps_after": 3
        }
      ]
    }
  }
}
```

## Integration with Jarvis

### Skill Activation Hook

The learning system integrates with the skill activation hook:

1. When a prompt matches a captured pattern, relevant learnings load
2. High-confidence learnings become skill suggestions
3. Applied patterns update `skill-rules.json` triggers

### Session Management

Sessions track learnings automatically:

1. Session start loads warm memory
2. Corrections captured during session go to hot memory
3. Session end persists hot memory to warm tier
4. Weekly review promotes/demotes between tiers

### Agent Coordination

Sub-agents can access learnings:

- Master orchestrator sees all learning summaries
- Specialists receive domain-relevant learnings
- Session librarian archives learnings with sessions

## Commands Reference

### Capture Commands

```bash
# Manually capture a learning
jarvis learn "Always use explicit return types"

# Capture with type
jarvis learn --type=preference "Named exports over default"

# Capture from current context
jarvis learn --from-context
```

### Memory Commands

```bash
# View memory status
jarvis memory status

# Search learnings
jarvis memory search "error handling"

# Promote/demote items
jarvis memory promote pat_001
jarvis memory demote cor_015

# Garbage collection
jarvis memory gc
```

### Auto-Update Commands

```bash
# Full workflow
./auto-update.sh review    # See pending
./auto-update.sh validate  # Test before apply
./auto-update.sh apply     # Apply validated
./auto-update.sh rollback  # Undo if needed
```

## Best Practices

1. **Capture Context** - Include the "why", not just the "what"
2. **Be Specific** - Vague learnings are not actionable
3. **Include Examples** - Real code is more valuable than descriptions
4. **Track Frequency** - Weight learnings by occurrence count
5. **Regular Review** - Weekly review of accumulated learnings
6. **Prune Stale** - Remove learnings that no longer apply
7. **Test Before Apply** - Use TDD validation for all skill updates

## Troubleshooting

### Learnings Not Captured

- Check if capture triggers are properly configured
- Verify `~/.jarvis/learnings/` directory exists
- Review session logs for capture errors

### Memory Overload

- Run `jarvis memory gc` to clean up
- Review hot memory limits (default: 20 items)
- Archive inactive warm memory items

### Conflicting Learnings

- More recent learning takes precedence
- User-stated beats inferred
- Project-specific beats global
- Use `jarvis memory resolve` for manual resolution

### Rollback Needed

```bash
# View applied changes
./auto-update.sh status

# Rollback specific learning
./auto-update.sh rollback pat_001

# Restore from backup
ls ~/.jarvis/backups/
cp ~/.jarvis/backups/file_timestamp.json destination
```

## Contributing

When extending the learning system:

1. Follow TDD approach for new detection patterns
2. Update this README with new capabilities
3. Add tests for capture triggers
4. Document memory tier transitions
5. Ensure rollback safety for all changes
