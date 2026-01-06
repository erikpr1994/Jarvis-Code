# Learning & Auto-Update System

> Part of the [Jarvis Specification](./README.md)

## 13. Learning & Auto-Update System

### 13.1 Learning Triggers

| Trigger | Detection | Action |
|---------|-----------|--------|
| **New Pattern** | Repeated code structure | Suggest adding to patterns |
| **Skill Gap** | Repeated manual guidance | Suggest creating skill |
| **Rule Violation** | Same error multiple times | Suggest adding rule |
| **Workflow Inefficiency** | Repeated multi-step process | Suggest automation |

### 13.2 Auto-Update Workflow

```
1. DETECT
   - Hook captures pattern/workflow
   - Compare against existing skills/patterns
   - Score novelty and frequency

2. VALIDATE (TDD for Skills)
   - RED: Run baseline scenario WITHOUT new content
   - GREEN: Run scenario WITH new content
   - Verify improvement

3. APPLY
   - Create/update skill, pattern, or rule
   - Update skill-rules.json with triggers
   - Log change in session file

4. ROLLBACK (if needed)
   - Version all changes
   - Monitor for regressions
   - Auto-rollback if quality drops
```

### 13.3 Learning Storage

```json
{
  "learnings": {
    "2026-01-04": {
      "patterns": [
        {
          "type": "code_pattern",
          "description": "Server action error handling",
          "frequency": 5,
          "status": "suggested",
          "skill": null
        }
      ],
      "workflows": [
        {
          "type": "workflow",
          "description": "PR review pipeline",
          "steps_before": 8,
          "steps_after": 3,
          "status": "applied"
        }
      ]
    }
  }
}
```
