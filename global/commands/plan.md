---
name: plan
description: Create a structured implementation plan with clarifying questions and scope definition
disable-model-invocation: false
---

# /plan - Create Implementation Plan

Create a well-structured, actionable implementation plan using the writing-plans skill methodology.

## What It Does

1. **Understands the goal** - Asks clarifying questions about scope and constraints
2. **Analyzes context** - Reviews codebase, existing patterns, and dependencies
3. **Structures the plan** - Creates phased approach with clear milestones
4. **Documents decisions** - Records assumptions, alternatives, and rationale
5. **Outputs plan** - Saves to docs/plans/ or .claude/tasks/

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | Task description or goal | "add user authentication" |

## Delegates To

This command delegates to the **writing-plans** skill for structured planning methodology.

## Process

### Phase 1: Goal Clarification

1. **Parse initial request**
   - Identify the core objective
   - Note any explicit constraints mentioned
   - Detect ambiguities that need clarification

2. **Ask clarifying questions**
   - Scope: What's included vs excluded?
   - Timeline: Any deadlines or urgency?
   - Dependencies: What must exist first?
   - Success criteria: How do we know it's done?
   - Constraints: Tech stack, performance, security requirements?

3. **Wait for user input** before proceeding (unless explicit "no questions" flag)

### Phase 2: Context Gathering

4. **Analyze project context**
   - Read CLAUDE.md for project conventions
   - Review existing patterns in codebase
   - Identify related components/features
   - Check for existing tests and documentation

5. **Identify dependencies**
   - External services or APIs needed
   - Internal modules that will be affected
   - Database changes required
   - Configuration changes needed

6. **Assess complexity**
   - Estimate scope (small/medium/large)
   - Identify high-risk areas
   - Note areas requiring research

### Phase 3: Plan Structure

7. **Create phased approach**
   ```markdown
   ## Phase 1: Foundation
   - [ ] Task 1.1: Description
   - [ ] Task 1.2: Description
   **Checkpoint**: Verification criteria

   ## Phase 2: Core Implementation
   - [ ] Task 2.1: Description
   - [ ] Task 2.2: Description
   **Checkpoint**: Verification criteria

   ## Phase 3: Integration & Testing
   - [ ] Task 3.1: Description
   - [ ] Task 3.2: Description
   **Checkpoint**: Verification criteria
   ```

8. **Define verification checkpoints**
   - Each phase ends with testable criteria
   - Include specific commands to run
   - Define expected outcomes

9. **Document decisions**
   - Assumptions made
   - Alternatives considered
   - Risks and mitigations

### Phase 4: Output

10. **Generate plan document**

```markdown
# Implementation Plan: [Title]

**Created**: [date]
**Status**: Draft
**Estimated Scope**: [small/medium/large]

## Goal
[Clear statement of what we're building]

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Assumptions
- Assumption 1
- Assumption 2

## Dependencies
- Dependency 1
- Dependency 2

## Phases

### Phase 1: [Name]
**Objective**: [What this phase accomplishes]

- [ ] Task 1.1: [Description]
- [ ] Task 1.2: [Description]

**Checkpoint**: [How to verify phase is complete]

### Phase 2: [Name]
...

## Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| Risk 1 | High/Med/Low | Strategy |

## Alternatives Considered
- Alternative 1: [Why not chosen]
- Alternative 2: [Why not chosen]

## Next Steps
1. Review plan with user
2. Execute with `/execute [plan-file]`
```

11. **Save plan to appropriate location**
    - If `docs/plans/` exists: save there
    - Otherwise: save to `.claude/tasks/`
    - Filename format: `plan-[slug]-[date].md`

12. **Present summary to user**
    - Show plan overview
    - Highlight key decisions
    - Ask for approval or modifications

## Output

```markdown
## Plan Created

**Title**: [plan title]
**Saved to**: [file path]
**Phases**: [count]
**Tasks**: [count]

### Summary
[Brief overview of the approach]

### Key Decisions
- Decision 1
- Decision 2

### Next Steps
- Review the plan: `Read [plan-file]`
- Execute the plan: `/execute [plan-file]`
- Modify: Ask me to adjust specific sections
```

## Examples

**Basic planning:**
```
/plan add user authentication with email/password
```

**With context:**
```
/plan refactor the payment module to support multiple providers
```

**Quick plan (skip questions):**
```
/plan add dark mode toggle --quick
```

## Integration with /execute

Plans created by `/plan` are designed to be executed by `/execute`:

```bash
# Create plan
/plan add user profile feature

# Review and approve plan
# ...

# Execute the plan
/execute docs/plans/plan-user-profile-2024-01-15.md
```

## Notes

- Always ask clarifying questions unless `--quick` flag provided
- Plans should be executable by someone unfamiliar with the context
- Each phase should be independently testable
- Plans are living documents - update as understanding evolves
- Use TDD approach: write test tasks before implementation tasks
