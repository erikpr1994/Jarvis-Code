---
name: using-skills
description: Use when starting any task or receiving any user request. Establishes how to find, evaluate, and invoke skills before taking action.
---

# Using Skills

<CRITICAL>
If there is even a 1% chance a skill applies, you MUST invoke it.
This is not optional. Skills contain workflows not in base context.
</CRITICAL>

## The Rule

**Invoke relevant skills BEFORE any response or action.**

```
User message received
    |
    v
Might any skill apply? (even 1% chance)
    |
    +--> YES --> Invoke Skill tool --> Follow instructions
    |
    +--> DEFINITELY NOT --> Respond directly
```

## How to Access

**In Claude Code:** Use the `Skill` tool. Never use Read on skill files.

## Red Flags

These thoughts mean STOP - you're rationalizing:

| Thought | Reality |
|---------|---------|
| "Just a simple question" | Questions are tasks. Check for skills. |
| "Need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore first" | Skills tell you HOW to explore. Check first. |
| "I can handle this quickly" | Speed without skills = missed protocols. |
| "Skill is overkill" | Simple things become complex. Use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "I'll do this one thing first" | Check BEFORE doing anything. |

## Skill Priority

When multiple skills could apply:

1. **Process skills first** (TDD, debugging, planning) - determine HOW
2. **Domain skills second** (git, infra, frontend) - provide specifics

Examples:
- "Build X" -> brainstorming, then implementation skills
- "Fix bug" -> systematic-debugging, then domain skills
- "Add feature" -> TDD, then relevant domain skills

## Skill Types

**Rigid** (TDD, debugging): Follow exactly. No shortcuts.

**Flexible** (patterns, domain): Adapt principles to context.

The skill content tells you which.

## Core Skills Reference

| Skill | When to Use |
|-------|-------------|
| test-driven-development | Any code implementation |
| systematic-debugging | Errors, bugs, unexpected behavior |
| session-management | Multi-step features, refactoring |
| git-expert | Commits, branches, PRs |
| writing-* | Creating new Jarvis components |
| improving-jarvis | System enhancements |
