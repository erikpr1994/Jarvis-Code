---
name: linear
description: Track all work in Linear - features, bugs, TODOs, questions, tech debt
disable-model-invocation: false
---

# /linear - Work Tracking

Single source of truth for all work. Features, bugs, TODOs, questions, and tech debt.

## When to Use

- **Features** - Multi-phase implementations (`/linear plan`)
- **Bugs** - Something broken (`/linear bug`)
- **TODOs** - Quick standalone tasks (`/linear todo`)
- **Questions** - Discussions needing resolution (`/linear question`)
- **Tech Debt** - Improvements for later (`/linear debt`)

## Setup (First Time)

```bash
/mcp  # Authenticate via OAuth
```

## Commands

### Create Issues

```bash
# Feature plan (hierarchical)
/linear plan "User Authentication"

# Bug report
/linear bug "Login fails with special chars"

# Quick TODO
/linear todo "Add loading spinner to submit button"

# Question for discussion
/linear question "Should we use JWT or sessions?"

# Tech debt item
/linear debt "Refactor auth to use Redis sessions"
```

### View Issues

```bash
# My assigned issues
/linear tasks

# All bugs
/linear bugs

# All questions
/linear questions

# All tech debt
/linear debt --list

# View specific issue
/linear ENG-123

# View feature plan tree
/linear tree ENG-100
```

### Work on Issues

```bash
# Start next unassigned task
/linear next

# Start specific issue
/linear start ENG-123

# Complete issue
/linear done ENG-123

# Add comment
/linear comment ENG-123 "Fixed in commit abc123"
```

### Progress

```bash
# Plan progress
/linear progress ENG-100

# Current sprint
/linear cycle
```

## Quick Reference

| Command | Purpose |
|---------|---------|
| `/linear plan "X"` | Create feature plan |
| `/linear bug "X"` | Report bug |
| `/linear todo "X"` | Create quick task |
| `/linear question "X"` | Ask question |
| `/linear debt "X"` | Log tech debt |
| `/linear tasks` | My issues |
| `/linear bugs` | All bugs |
| `/linear next` | Start next task |
| `/linear start ID` | Start specific issue |
| `/linear done` | Complete issue |
| `/linear tree ID` | View plan hierarchy |
| `/linear cycle` | Current sprint |

## Issue Types

| Type | Label | Hierarchy |
|------|-------|-----------|
| Feature | `feature` | Deep (Feature → Phase → Task) |
| Bug | `bug` | Flat |
| TODO | `task` | Single issue |
| Question | `question` | Single issue |
| Tech Debt | `tech-debt` | Single or grouped |

## Examples

**Report a bug:**
```bash
/linear bug "Form validation breaks on Unicode input"
```

**Quick TODO:**
```bash
/linear todo "Add retry logic to API client"
```

**Start a feature:**
```bash
/linear plan "OAuth2 Integration"
```

**Log tech debt:**
```bash
/linear debt "Replace moment.js with date-fns"
```

## Detailed Workflow

For templates, examples, and full workflow details, see the **linear skill** (`skill: "linear"`).
