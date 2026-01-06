---
name: writing-design
description: Use when creating design documents, technical specs, architecture decisions, or system documentation. Covers structure, audience, and validation.
---

# Writing Design Documents

## Overview

Design documents capture decisions, trade-offs, and rationale BEFORE implementation. They prevent rework, align stakeholders, and create institutional knowledge.

## When to Use

- Planning new feature with multiple approaches
- Making architectural decisions
- Proposing system changes
- Documenting API contracts
- Recording technology choices

## Document Types

| Type | Purpose | Audience |
|------|---------|----------|
| **RFC** | Propose significant changes | Team, stakeholders |
| **ADR** | Record architecture decisions | Future developers |
| **Tech Spec** | Detail implementation approach | Implementers |
| **API Contract** | Define interface boundaries | Consumers, implementers |

---

## Structure Template

### RFC (Request for Comments)

```markdown
# RFC: [Title]

**Status**: Draft | Review | Accepted | Rejected | Superseded
**Author**: [Name]
**Created**: [Date]
**Reviewers**: [Names]

## Summary
[1-2 paragraph executive summary]

## Problem Statement
[What problem are we solving? Why now?]

## Goals
- [Goal 1]
- [Goal 2]

## Non-Goals
- [Explicitly out of scope]

## Proposed Solution
[Detailed solution with diagrams if helpful]

## Alternatives Considered
### Alternative 1: [Name]
- Pros: [...]
- Cons: [...]
- Why not: [...]

### Alternative 2: [Name]
[Same structure]

## Trade-offs
[Explicit trade-offs being made]

## Implementation Plan
1. [Phase 1]
2. [Phase 2]

## Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | Low/Med/High | Low/Med/High | [Plan] |

## Open Questions
- [ ] [Question 1]
- [ ] [Question 2]

## Timeline
[Estimated phases, no specific dates]

## References
- [Link 1]
```

### ADR (Architecture Decision Record)

```markdown
# ADR-[Number]: [Title]

**Status**: Proposed | Accepted | Deprecated | Superseded by ADR-X
**Date**: [Date]
**Deciders**: [Names]

## Context
[What is the issue that we're seeing that is motivating this decision?]

## Decision
[What is the change that we're proposing?]

## Consequences

### Positive
- [Benefit 1]
- [Benefit 2]

### Negative
- [Trade-off 1]
- [Trade-off 2]

### Neutral
- [Side effect]

## Alternatives Not Chosen
- [Alternative 1]: [Why not]
- [Alternative 2]: [Why not]
```

### Tech Spec

```markdown
# Tech Spec: [Feature Name]

**Author**: [Name]
**Status**: Draft | Approved | In Progress | Complete
**Target**: [Version/Sprint]

## Overview
[Brief description of what this feature does]

## Background
[Context needed to understand the spec]

## Requirements
### Functional
- [ ] [Requirement 1]
- [ ] [Requirement 2]

### Non-Functional
- Performance: [Target]
- Security: [Requirements]
- Scalability: [Requirements]

## Design

### Data Model
[Schema, types, structures]

### API Design
[Endpoints, contracts]

### Component Architecture
[How pieces fit together]

### Flow Diagrams
[Sequence or flow diagrams]

## Implementation Notes
[Specific implementation guidance]

## Testing Strategy
- Unit tests: [Approach]
- Integration tests: [Approach]
- E2E tests: [Approach]

## Rollout Plan
1. [Phase 1]
2. [Phase 2]

## Monitoring
[What to monitor, alerts]
```

---

## Quality Checklist

### Content
- [ ] Problem is clearly stated
- [ ] Goals are measurable/verifiable
- [ ] Non-goals explicitly stated
- [ ] Alternatives genuinely considered (not strawmen)
- [ ] Trade-offs acknowledged honestly
- [ ] Risks identified with mitigations

### Structure
- [ ] Appropriate template for document type
- [ ] Sections complete (no TODOs in final)
- [ ] Diagrams where text is unclear
- [ ] References linked, not inline

### Audience
- [ ] Technical level appropriate for readers
- [ ] Jargon explained or avoided
- [ ] Executive summary for skimmers

### Review
- [ ] Self-reviewed before sharing
- [ ] Reviewed by someone not involved
- [ ] Open questions addressed or marked

---

## Common Mistakes

### 1. Writing After Implementation
**Wrong**: Document what you built
**Right**: Document decisions BEFORE building

### 2. Fake Alternatives
**Wrong**: "Do nothing" or obviously bad options
**Right**: Genuinely viable alternatives you considered

### 3. Missing Trade-offs
**Wrong**: Only listing benefits
**Right**: Honest assessment of what you're giving up

### 4. Too Much Detail
**Wrong**: Implementation code in design doc
**Right**: Enough detail to make decisions, not implement

### 5. Stale Documents
**Wrong**: Design doc never updated
**Right**: Update status, add learnings, link to ADRs

---

## Anti-patterns

```markdown
# BAD: Solution disguised as problem
## Problem
We need to use Redis for caching.

# GOOD: Actual problem
## Problem
API response times exceed 500ms for dashboard queries,
causing poor user experience.
```

```markdown
# BAD: Strawman alternatives
## Alternatives
1. Do nothing (bad)
2. Use our solution (good)

# GOOD: Real alternatives
## Alternatives
1. Redis: Fast but operational overhead
2. In-memory: Simple but doesn't scale
3. CDN edge caching: Fast but invalidation complex
```

---

## Integration

**Related skills:** writing-plans, brainstorming
**Triggers:** design, RFC, ADR, tech spec, architecture, proposal
