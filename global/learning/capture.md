# Learning Capture System

> Part of the [Jarvis Learning System](./README.md)

## Overview

The capture system identifies and records learnings during sessions for future reference. It detects patterns, corrections, preferences, and successful approaches that should be preserved.

## Learning Triggers

| Trigger | Detection Method | Capture Action |
|---------|------------------|----------------|
| **Repeated Pattern** | Same code structure 3+ times | Log pattern for skill consideration |
| **User Correction** | User says "no, do X instead" | Record preference with context |
| **Skill Gap** | Manual guidance repeated 2+ times | Flag for new skill creation |
| **Rule Violation** | Same error pattern 3+ times | Suggest adding validation rule |
| **Workflow Inefficiency** | Multi-step process repeated | Suggest automation hook |
| **Successful Resolution** | Complex problem solved | Document solution approach |

## Capture Protocol

### 1. During Session

When a learning trigger is detected, immediately capture:

```markdown
## Learning Entry

**Type:** [pattern | correction | preference | gap | violation | workflow | success]
**Date:** YYYY-MM-DD
**Session:** session-XXX
**Context:** Brief description of what was happening

### What Happened
Detailed description of the trigger event

### Resolution
How it was resolved or what the user preferred

### Suggested Action
- [ ] Add to patterns
- [ ] Create new skill
- [ ] Update existing skill: [skill-name]
- [ ] Add validation rule
- [ ] Create automation hook
```

### 2. Capture Locations

Learnings are captured in a tiered system based on scope:

| Scope | Location | Contents |
|-------|----------|----------|
| **Session** | `.claude/tasks/session-current.md` | Immediate learnings, in-progress notes |
| **Project** | `.claude/learnings/project.json` | Project-specific patterns and preferences |
| **Global** | `~/.jarvis/learnings/global.json` | Cross-project patterns and preferences |

### 3. Capture Format

```json
{
  "learnings": {
    "2026-01-04": {
      "patterns": [
        {
          "id": "pat_001",
          "type": "code_pattern",
          "description": "Server action error handling with toast notifications",
          "frequency": 5,
          "status": "suggested",
          "context": {
            "files": ["app/actions/*.ts"],
            "trigger": "error handling in server actions"
          },
          "suggested_skill": null,
          "created_at": "2026-01-04T10:30:00Z"
        }
      ],
      "corrections": [
        {
          "id": "cor_001",
          "type": "user_preference",
          "description": "Prefer explicit return types over inferred",
          "original": "const fn = () => {}",
          "corrected": "const fn = (): void => {}",
          "frequency": 3,
          "status": "active",
          "created_at": "2026-01-04T11:00:00Z"
        }
      ],
      "workflows": [
        {
          "id": "wf_001",
          "type": "workflow_improvement",
          "description": "PR review pipeline with parallel checks",
          "steps_before": 8,
          "steps_after": 3,
          "automation": "hooks/pr-review.sh",
          "status": "applied",
          "created_at": "2026-01-04T14:00:00Z"
        }
      ]
    }
  }
}
```

## Detection Patterns

### Code Pattern Detection

Look for repeated structures:

```yaml
Pattern Indicators:
  - Same import + usage pattern 3+ times
  - Identical try/catch structure across files
  - Repeated validation logic
  - Similar component composition patterns
```

### Correction Detection

Monitor for user corrections:

```yaml
Correction Signals:
  - "No, use X instead"
  - "I prefer Y"
  - "Always do Z"
  - "Never do W"
  - User immediately editing AI output
  - Same fix applied multiple times
```

### Preference Detection

Identify user preferences:

```yaml
Preference Categories:
  - Naming conventions (camelCase vs snake_case)
  - File organization (co-location vs separation)
  - Error handling style (try/catch vs Result type)
  - Comment style and density
  - Test structure preferences
  - Import ordering
```

## Capture Commands

### Manual Capture

When explicitly asked to capture a learning:

```bash
# Add to current session
jarvis learn "Always use explicit return types in TypeScript"

# Add with category
jarvis learn --type=preference "Prefer named exports over default exports"

# Add pattern from current context
jarvis learn --from-context --type=pattern
```

### Automatic Capture

The system automatically captures when:

1. **Session ends** - Reviews session for learnable moments
2. **Skill invoked** - Tracks skill usage patterns
3. **Error resolved** - Documents resolution approach
4. **User provides feedback** - Records corrections and preferences

## Processing Pipeline

```
Detection → Validation → Storage → Review → Application
    ↓           ↓           ↓         ↓          ↓
 Triggers    Confirm     Save to   User/AI    Update
 matched    relevance    tier     approval   skills
```

### Validation Steps

1. **Novelty Check** - Is this already captured?
2. **Frequency Check** - Has this occurred enough to be significant?
3. **Scope Check** - Project-specific or global?
4. **Conflict Check** - Does this contradict existing learnings?

## Integration with Skills

### Skill Suggestion Flow

When a learning reaches sufficient frequency:

1. **Suggest** - Prompt user: "Pattern X detected 5 times. Create skill?"
2. **Draft** - Auto-generate skill skeleton from captured data
3. **Review** - User approves, modifies, or rejects
4. **Apply** - Add to skills directory with trigger rules

### Skill Update Flow

When a learning relates to an existing skill:

1. **Detect** - Learning matches existing skill domain
2. **Propose** - "Add this pattern to [skill-name]?"
3. **Merge** - Integrate learning into skill content
4. **Version** - Track skill evolution

## Session End Protocol

At session end, the capture system:

1. **Review** all captured learnings from session
2. **Consolidate** similar learnings into single entries
3. **Promote** high-frequency learnings to appropriate tier
4. **Summarize** key learnings in session close-out

```markdown
## Session Learnings Summary

### Captured This Session
- 2 new patterns identified
- 1 user preference recorded
- 1 workflow improvement suggested

### Pending Actions
- [ ] Review pattern: "Form validation with Zod" (3 occurrences)
- [ ] Consider skill: "Supabase RLS patterns" (flagged for creation)
```

## Best Practices

1. **Capture Context** - Always include the "why" not just the "what"
2. **Be Specific** - Vague learnings are not actionable
3. **Include Examples** - Real code snippets are more valuable than descriptions
4. **Track Frequency** - Weight learnings by how often they occur
5. **Regular Review** - Weekly review of accumulated learnings
6. **Prune Stale** - Remove learnings that no longer apply
