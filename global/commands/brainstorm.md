---
name: brainstorm
description: Structured ideation for requirements (discovery) or solutions (approach)
---

# /brainstorm - Structured Ideation

Generate ideas, explore options, and make decisions through structured brainstorming.

## Delegates To

This command invokes the **brainstorming** skill with two modes:
- **Discovery Mode**: What should we build? → Outputs a spec
- **Approach Mode**: How should we build it? → Outputs a decision

## Quick Reference

| Mode | Command | Output |
|------|---------|--------|
| Discovery | `/brainstorm what should [feature] do` | Feature spec |
| Approach | `/brainstorm how to implement [feature]` | Decision record |
| Quick | `/brainstorm [topic] --quick` | 3 options, brief |
| Deep | `/brainstorm [topic] --deep` | 5+ options, detailed |

## Arguments

| Argument | Description |
|----------|-------------|
| `$ARGUMENTS` | Topic or question to brainstorm |
| `--quick` | Generate 3 options with brief analysis |
| `--deep` | Generate 5+ options with extensive analysis |

## Discovery Mode (Spec)

Use when requirements are unclear:

```bash
/brainstorm what should the notification system do
/brainstorm user authentication requirements
```

**Output**: Feature spec with user stories and acceptance criteria.

## Approach Mode (Decision)

Use when choosing implementation:

```bash
/brainstorm how to implement real-time notifications
/brainstorm PostgreSQL vs MongoDB vs DynamoDB
```

**Output**: Decision record with evaluated options.

## Process Overview

**Discovery:**
```
EXPLORE → BRAINSTORM → PRIORITIZE → SPECIFY → VALIDATE
```

**Approach:**
```
DIVERGE → CAPTURE → EVALUATE → DECIDE → DOCUMENT
```

## Examples

```bash
# Discovery: What to build
/brainstorm what features should the dashboard have

# Approach: How to build
/brainstorm state management options for React app

# Comparative
/brainstorm microservices vs monolith for MVP

# Quick session
/brainstorm auth approach --quick
```

## Workflow

```
/brainstorm what...  → Feature Spec (WHAT/WHY)
/brainstorm how...   → Decision Record (HOW)
/design [spec]       → Technical Architecture
/plan [design]       → Implementation Plan
/execute [plan]      → Build It
```

## See Also

- **Full methodology**: `skill: "brainstorming"`
- **Spec only**: `/spec [feature]`
- **Create design**: `/design`
- **Create plan**: `/plan`
