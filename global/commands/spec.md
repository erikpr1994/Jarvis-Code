---
name: spec
description: Create a feature specification with user stories and acceptance criteria
---

# /spec - Create Feature Specification

Create a feature specification using structured brainstorm and prioritization.

> **The Spec Rule:** A spec contains WHAT and WHY. Never HOW. No code. No technical decisions.

## Delegates To

This command invokes the **brainstorm** skill in **Discovery Mode**.

## Quick Reference

| Action | Command |
|--------|---------|
| Create spec | `/spec user authentication` |
| From problem | `/spec users miss updates because they refresh` |
| With context | `/spec notification system for real-time` |

## Arguments

| Argument | Description |
|----------|-------------|
| `$ARGUMENTS` | Feature or problem description |

## Process Overview

```
1. EXPLORE    → Understand the problem and users
2. BRAINSTORM → Generate all possible requirements
3. PRIORITIZE → Apply MoSCoW (Must/Should/Could/Won't)
4. SPECIFY    → Write user stories with acceptance criteria
5. OUTPUT     → Save to docs/specs/ or .claude/tasks/
```

## Output Location

1. If `docs/specs/` exists: `docs/specs/[feature-name].md`
2. If `docs/` exists: `docs/[feature-name]-spec.md`
3. Otherwise: `.claude/tasks/spec-[feature-name].md`

## What Belongs in a Spec

| In Spec | NOT In Spec |
|---------|-------------|
| User stories | Code snippets |
| Acceptance criteria | Database schema |
| Success metrics | API endpoints |
| Problem statement | Technical approach |
| Target users | "Use React/PostgreSQL" |

**The test:** Could a non-technical stakeholder read and validate this spec?

## Examples

```bash
# Basic spec
/spec user authentication

# From problem statement
/spec users are missing important updates because they have to refresh

# Feature with context
/spec notification system for real-time updates
```

## Workflow

```
/spec [feature]           → Feature Specification (WHAT/WHY)
    |
/brainstorm how to...     → Technical Decision (HOW)
    |
/plan [spec]              → Implementation Plan
    |
/execute [plan]           → Implementation
```

## See Also

- **Full methodology**: `skill: "brainstorm"` (Discovery Mode)
- **Technical decisions**: `/brainstorm how...`
- **Create plans**: `/plan`
