# Documentation Directory

> Inherits from: project root CLAUDE.md
> Level: L1-L2 (docs/)
> Token budget: ~400 tokens

## Purpose

Project documentation including specifications, plans, architecture decisions, and technical guides.

## Organization

```
docs/
├── README.md                # Documentation index
├── specs/                   # Feature specifications
│   └── feature-name.md
├── plans/                   # Implementation plans
│   └── feature-plan.md
├── architecture/            # Architecture documentation
│   ├── overview.md
│   └── decisions/           # ADRs (Architecture Decision Records)
│       └── 001-database-choice.md
├── api/                     # API documentation
│   └── endpoints.md
├── guides/                  # How-to guides
│   ├── setup.md
│   └── deployment.md
└── runbooks/                # Operational procedures
    └── incident-response.md
```

## Document Types

### Specification (specs/)

```markdown
# Feature: {{Feature Name}}

## Overview
Brief description of the feature and its purpose.

## User Stories
- As a [user type], I want to [action] so that [benefit]

## Requirements
### Functional
- [ ] Requirement 1
- [ ] Requirement 2

### Non-Functional
- Performance: Response time < 200ms
- Security: Authentication required

## Technical Design
High-level approach and key decisions.

## Dependencies
What this feature depends on.

## Out of Scope
What this feature explicitly does NOT include.

## Open Questions
- Question 1?
- Question 2?
```

### Implementation Plan (plans/)

```markdown
# Plan: {{Feature Name}}

## Status
- [ ] Planning
- [ ] In Progress
- [ ] Review
- [ ] Complete

## Scope
What this plan covers.

## Tasks
- [ ] Task 1 (estimate: Xh)
  - [ ] Subtask 1.1
  - [ ] Subtask 1.2
- [ ] Task 2 (estimate: Xh)

## Dependencies
- Prerequisite: [Link to spec or other plan]

## Risks
| Risk | Mitigation |
|------|------------|
| Risk 1 | Mitigation strategy |

## Timeline
- Start: YYYY-MM-DD
- Target: YYYY-MM-DD
```

### Architecture Decision Record (architecture/decisions/)

```markdown
# ADR-001: {{Decision Title}}

## Status
Accepted | Proposed | Deprecated | Superseded by ADR-XXX

## Context
What is the issue that we're seeing that is motivating this decision?

## Decision
What is the change that we're proposing and/or doing?

## Consequences
What becomes easier or more difficult because of this change?

### Positive
- Benefit 1
- Benefit 2

### Negative
- Tradeoff 1
- Tradeoff 2

## Alternatives Considered
### Option A
Description, pros, cons.

### Option B
Description, pros, cons.
```

## Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Specs | `{{feature-name}}.md` | `user-authentication.md` |
| Plans | `{{feature-name}}-plan.md` | `user-authentication-plan.md` |
| ADRs | `{{NNN}}-{{decision}}.md` | `001-use-postgresql.md` |
| Guides | `{{topic}}.md` | `local-development.md` |

## Writing Guidelines

1. **Be Concise**: Lead with the most important information
2. **Use Examples**: Code snippets, diagrams, screenshots
3. **Keep Updated**: Stale docs are worse than no docs
4. **Link Related**: Cross-reference related documents
5. **Version Control**: All docs in git with meaningful commits

## Markdown Standards

- Use ATX-style headers (`# H1`, `## H2`)
- Use fenced code blocks with language identifiers
- Use tables for structured data
- Use relative links for internal references
- Include alt text for images

## DO NOT

- Document obvious code (self-documenting > comments)
- Create orphan documents (link from index)
- Duplicate information (link instead)
- Use absolute paths for internal links
- Skip updating docs when code changes
- Write docs that require constant updates
- Include sensitive information (secrets, credentials)

## Common Tasks

| Task | Location |
|------|----------|
| New feature spec | `docs/specs/{{feature}}.md` |
| Implementation plan | `docs/plans/{{feature}}-plan.md` |
| Architecture decision | `docs/architecture/decisions/{{NNN}}-{{title}}.md` |
| API documentation | `docs/api/{{endpoint}}.md` |
| Setup guide | `docs/guides/setup.md` |
