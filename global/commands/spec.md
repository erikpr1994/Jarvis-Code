---
name: spec
description: Create a feature specification with user stories and acceptance criteria
disable-model-invocation: false
---

# /spec - Create Feature Specification

Create a feature specification using the brainstorming skill's Discovery Mode.

> **The Spec Rule:** A spec contains WHAT and WHY. Never HOW. No code. No technical decisions.

## What It Does

1. **Explores the problem** - Understands who has the problem and why
2. **Brainstorms requirements** - Generates all possible requirements
3. **Prioritizes** - Applies MoSCoW (Must/Should/Could/Won't)
4. **Writes user stories** - Formalizes with acceptance criteria
5. **Outputs spec** - Saves to docs/specs/ or .claude/tasks/

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | Feature or problem description | "user notifications" |

## Delegates To

This command invokes the **brainstorming** skill in **Discovery Mode**.

## Process

### Phase 1: Problem Exploration

Ask clarifying questions:
- Who has this problem?
- What's their current workaround?
- What triggers the need?
- What does success look like?

### Phase 2: Requirements Brainstorming

Generate ALL possible requirements without filtering:
- Core functionality
- User experience
- Edge cases
- Integrations

**Minimum 5 requirements. Aim for 10+.**

### Phase 3: Prioritization

Apply MoSCoW:
- **P0 (Must)**: Without these, feature is useless
- **P1 (Should)**: Important but not critical for v1
- **P2 (Could)**: Nice to have
- **Won't**: Explicitly out of scope (this release)

### Phase 4: User Stories

For each P0/P1 requirement, write:

```markdown
### US-X: [Title]

**As a** [user type]
**I want to** [action]
**So that** [benefit]

**Acceptance Criteria:**
- [ ] Given [context], when [action], then [result]
- [ ] Given [context], when [action], then [result]
- [ ] Edge: Given [edge case], then [behavior]
```

### Phase 5: Output

Save spec document with:
- Problem statement
- Target users
- Success metrics
- All user stories
- Out of scope
- Open questions

## Output Location

1. If `docs/specs/` exists: `docs/specs/[feature-name].md`
2. If `docs/` exists: `docs/[feature-name]-spec.md`
3. Otherwise: `.claude/tasks/spec-[feature-name].md`

## Output Format

```markdown
## Spec Created

**Title**: [Feature Name] Specification
**Saved to**: [file path]
**User Stories**: [count]
**Acceptance Criteria**: [count]

### Summary
[Brief overview of what was specified]

### P0 Requirements
- [Requirement 1]
- [Requirement 2]

### Next Steps
- Review spec with stakeholders
- Brainstorm approach: `/brainstorm how to implement [feature]`
- Create design: `/design [spec-file]`
- Create plan: `/plan [spec-file]`
```

## Examples

**Basic spec:**
```
/spec user authentication
```

**With context:**
```
/spec notification system for real-time updates
```

**From problem:**
```
/spec users are missing important updates because they have to refresh
```

## Integration

**Workflow:**
```
/spec [feature]           → Feature Specification
    ↓
/brainstorm how to...     → Technical Decision
    ↓
/design [spec]            → Design Document
    ↓
/plan [spec]              → Implementation Plan
    ↓
/execute [plan]           → Implementation
```

## What Does NOT Belong in a Spec

| NOT in Spec | Belongs in |
|-------------|------------|
| Code snippets | Design doc, Plan |
| Database schema | Design doc |
| API endpoints | Design doc |
| "Use React/PostgreSQL/etc" | Design doc |
| Technical architecture | Design doc |
| Implementation steps | Plan |

**The test:** Could a non-technical stakeholder read and validate this spec?

## Notes

- Always ask clarifying questions before brainstorming
- Quantity over quality during brainstorming phase
- Every P0/P1 requirement needs a user story
- Every user story needs acceptance criteria
- Edge cases are often where bugs hide - cover them
- **NO code or technical implementation details**
