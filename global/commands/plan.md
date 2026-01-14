---
name: plan
description: Create a structured implementation plan with phases and checkpoints
---

# /plan - Create Implementation Plan

Create a well-structured, actionable implementation plan with phases, tasks, and verification checkpoints.

## Delegates To

This command invokes the **writing-plans** skill for full methodology.

## Quick Reference

| Action | Command |
|--------|---------|
| Create plan | `/plan add user authentication` |
| Quick plan | `/plan [task] --quick` |
| From spec | `/plan docs/specs/feature.md` |

## Arguments

| Argument | Description |
|----------|-------------|
| `$ARGUMENTS` | Task description or spec file path |
| `--quick` | Skip clarifying questions |

## Process Overview

```
1. CLARIFY  → Understand what we're building
2. RESEARCH → Analyze codebase and patterns
3. DESIGN   → Structure the approach
4. DOCUMENT → Write the plan with tasks
5. VALIDATE → Review and approve
```

## Output

Plans are saved to:
1. `docs/plans/` if it exists
2. `.claude/tasks/` otherwise

Format: `plan-[feature-slug]-[date].md`

## Plan Structure

```markdown
# Implementation Plan: [Feature]

## Goal
[What we're building]

## Phase 1: [Name]
- [ ] Task 1.1: [Description]
- [ ] Task 1.2: [Description]
**Checkpoint**: [Verification]

## Phase 2: [Name]
...
```

## Examples

```bash
# Create plan for feature
/plan add payment integration

# Plan from existing spec
/plan docs/specs/notifications.md

# Quick plan (no questions)
/plan fix login bug --quick
```

## Workflow

```
/spec [feature]     → Requirements (WHAT/WHY)
/brainstorm how...  → Technical Decision
/plan [feature]     → Implementation Steps
/execute [plan]     → Build It
```

## See Also

- **Full methodology**: `skill: "writing-plans"`
- **Execute plans**: `/execute`
- **Create specs**: `/spec`
