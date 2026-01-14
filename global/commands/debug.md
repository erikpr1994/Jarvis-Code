---
name: debug
description: Systematic debugging workflow with root cause analysis and fix verification
---

# /debug - Debug Workflow Command

Systematic debugging with evidence-based investigation, root cause analysis, and verified fixes.

## Delegates To

This command invokes the **systematic-debugging** skill for full methodology.

## Quick Reference

| Action | Command |
|--------|---------|
| Debug error | `/debug TypeError: undefined` |
| Debug behavior | `/debug login redirects wrong` |
| Debug performance | `/debug dashboard loads slowly` |

## Arguments

| Argument | Description |
|----------|-------------|
| `$ARGUMENTS` | Bug description or error message |

## Core Philosophy

- **Evidence-based**: Every conclusion supported by concrete evidence
- **Systematic**: Follow structured investigation process
- **Root cause focus**: Fix underlying issues, not symptoms
- **Verification required**: Confirm fix resolves the problem

## Process Overview

```
1. UNDERSTAND  → Capture problem, gather context
2. COLLECT     → Gather logs, errors, state evidence
3. REPRODUCE   → Create reliable reproduction steps
4. ANALYZE     → Five Whys to find root cause
5. FIX         → Implement targeted solution
6. VERIFY      → Confirm fix, add regression test
```

## Debug by Type

| Issue Type | Focus |
|------------|-------|
| Crash/Error | Stack trace → failing line → data source |
| Wrong Behavior | Expected vs actual → decision point → conditions |
| Performance | Profile → bottleneck → measure before/after |
| Intermittent | Patterns → race conditions → async code |

## Time-Boxing Rules

- **15 min**: If stuck, step back and reassess
- **30 min**: Try different approach
- **1 hour**: Ask for help or create minimal reproduction

## Examples

```bash
# Debug with error message
/debug TypeError: Cannot read property 'id' of undefined

# Debug wrong behavior
/debug user login redirects to wrong page

# Debug performance
/debug dashboard loads slowly after login

# Debug intermittent
/debug API sometimes returns 500 errors
```

## See Also

- **Full methodology**: `skill: "systematic-debugging"`
- **Create tests**: `/test`
- **Review code**: `/jarvis-review`
