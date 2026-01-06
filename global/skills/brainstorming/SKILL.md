---
name: brainstorming
description: Use when generating ideas, exploring options, or making decisions with multiple viable approaches. Triggers - ideate, brainstorm, options, alternatives, explore, what if, could we, ways to, approaches.
---

# Brainstorming

**Iron Law:** NEVER commit to an approach without exploring at least 3 alternatives first.

## Overview

Brainstorming is structured ideation that generates options before evaluation. The goal is divergent thinking first (quantity), then convergent thinking (quality). Rushing to the first solution is the enemy of good solutions.

## When to Use

- User asks "how could we..." or "what are the options for..."
- Architecture or design decisions with trade-offs
- Debugging when root cause is unclear
- Feature implementation with multiple valid approaches
- Any decision where the first idea might not be the best

## The Process

```
1. DIVERGE  -> Generate options (quantity over quality)
2. CAPTURE  -> Document ALL ideas without judgment
3. EVALUATE -> Apply criteria to each option
4. DECIDE   -> Choose with explicit reasoning
5. DOCUMENT -> Record decision and alternatives considered
```

## Step 1: Diverge - Generate Options

**Minimum 3 options. Aim for 5-7.**

Techniques:
- **Inversion**: What's the opposite approach?
- **Extreme**: What if we had unlimited resources? Zero resources?
- **Steal**: How do others solve this? (competitors, other domains)
- **Combine**: Can we merge two partial solutions?
- **Simplify**: What's the minimum viable approach?

```markdown
## Options Generated

### Option 1: [Name]
[Brief description - one paragraph max]

### Option 2: [Name]
[Brief description]

### Option 3: [Name]
[Brief description]
```

**Do NOT evaluate during this step.** Capture everything.

## Step 2: Capture - Document Without Judgment

Write down every idea, even "bad" ones. Bad ideas often spark good ones.

```markdown
## Raw Ideas (Unfiltered)
1. [Idea] - even if seems impractical
2. [Idea] - even if already rejected mentally
3. [Idea] - even if unconventional
```

**Rules:**
- No criticism during capture
- No "but that won't work because..."
- No filtering or ranking yet
- Quantity is the goal

## Step 3: Evaluate - Apply Criteria

Define evaluation criteria BEFORE scoring options:

| Criterion | Weight | Description |
|-----------|--------|-------------|
| Complexity | High | Implementation effort required |
| Maintainability | High | Long-term maintenance burden |
| Performance | Medium | Runtime efficiency |
| Time to Implement | Medium | Calendar time to complete |
| Risk | High | Unknowns and failure modes |

**Score each option:**

```markdown
## Evaluation Matrix

| Option | Complexity | Maintainability | Performance | Time | Risk | Total |
|--------|------------|-----------------|-------------|------|------|-------|
| Option 1 | 3/5 | 4/5 | 5/5 | 2/5 | 4/5 | 18/25 |
| Option 2 | 5/5 | 3/5 | 3/5 | 5/5 | 3/5 | 19/25 |
| Option 3 | 4/5 | 5/5 | 4/5 | 3/5 | 5/5 | 21/25 |
```

## Step 4: Decide - Choose with Explicit Reasoning

State the chosen option AND why alternatives were rejected:

```markdown
## Decision

**Selected**: Option 3 - [Name]

**Reasoning**:
- Highest maintainability score (our codebase prioritizes this)
- Lowest risk despite moderate complexity
- Aligns with existing patterns in [specific location]

**Why NOT Option 1**:
- Time to implement too high for current sprint

**Why NOT Option 2**:
- Risk score unacceptable given production stability requirements
```

## Step 5: Document - Record for Future Reference

```markdown
## Decision Record

**Date**: [date]
**Context**: [what prompted this decision]
**Options Considered**: [list all]
**Decision**: [chosen option]
**Consequences**: [expected outcomes, trade-offs accepted]
**Review Date**: [when to revisit if applicable]
```

## Examples

### Good Brainstorming

```
User: "How should we implement user notifications?"

Options Generated:
1. WebSocket real-time push
2. Polling with exponential backoff
3. Server-Sent Events (SSE)
4. Push notifications via service worker
5. Email digests (async)

Evaluation applied against:
- Real-time requirement: Yes
- Browser support: Must support all modern browsers
- Server complexity: Minimize infrastructure

Decision: SSE for in-app, email digest for away
Reasoning: SSE simpler than WebSocket, native browser support,
falls back gracefully. Email catches users who are away.

Rejected WebSocket: Overkill for unidirectional notifications
Rejected Polling: Wasteful, poor UX for real-time feel
```

### Bad Brainstorming (DO NOT DO THIS)

```
User: "How should we implement user notifications?"

"Let's use WebSocket - it's real-time and modern."
[Proceeds to implement without considering alternatives]
```

**Why wrong:** No options explored, no evaluation, no documented reasoning.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "The answer is obvious" | Obvious to you now. Document for future maintainers. |
| "We don't have time to brainstorm" | Time spent now saves 10x in rework later. |
| "I already know the best approach" | Then documenting alternatives takes 5 minutes. |
| "The user asked for X specifically" | Explore X plus alternatives. User may not know all options. |
| "It's a simple decision" | Simple decisions compound. Document anyway. |
| "I'll remember why later" | You won't. Future you needs this. |
| "Only one option is technically feasible" | Are you sure? Document why others are infeasible. |

## Red Flags - STOP and Start Over

- Implementing the first idea without alternatives
- "Let me just try this..." without exploration
- Skipping evaluation criteria
- No documented reasoning for decision
- Dismissing options without explicit reasoning
- Evaluating while still generating (mixing phases)
- Fewer than 3 options considered
- No trade-offs acknowledged

**If you catch yourself doing any of these: STOP. Go back to Step 1.**

## Verification Checklist

Before proceeding with chosen approach:

- [ ] Generated at least 3 options
- [ ] Captured all ideas without judgment first
- [ ] Defined evaluation criteria before scoring
- [ ] Evaluated each option against criteria
- [ ] Documented explicit reasoning for decision
- [ ] Explained why alternatives were rejected
- [ ] Acknowledged trade-offs of chosen approach
- [ ] Created decision record for future reference

## Quick Reference

```
MINIMUM: 3 options
IDEAL: 5-7 options
ALWAYS: Document reasoning
NEVER: Implement first idea without alternatives
```

## Integration

**Pairs with:**
- **writing-plans** - Brainstorm before planning
- **executing-plans** - Decision informs execution
- **systematic-debugging** - Brainstorm hypotheses
- **verification** - Verify decision criteria met
