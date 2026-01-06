---
name: brainstorm
description: Structured ideation session to explore options with pros/cons analysis
disable-model-invocation: false
---

# /brainstorm - Structured Ideation Session

Facilitate a structured brainstorming session to explore options, generate ideas, and evaluate alternatives with clear pros/cons analysis.

## What It Does

1. **Defines the problem** - Clarifies what we're solving
2. **Generates options** - Creates multiple solution approaches
3. **Evaluates each** - Analyzes pros, cons, and trade-offs
4. **Recommends path** - Suggests best option with rationale
5. **Documents session** - Saves for future reference

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | Topic or question to brainstorm | "database architecture options" |

## Delegates To

This command delegates to the **brainstorming** skill for structured ideation methodology.

## Process

### Phase 1: Problem Definition

1. **Clarify the topic**
   - What problem are we solving?
   - What constraints exist?
   - What are the success criteria?
   - Who are the stakeholders?

2. **Establish boundaries**
   - What's in scope?
   - What's explicitly out of scope?
   - What resources are available?
   - What's the timeline?

3. **Identify evaluation criteria**
   - What matters most? (priority order)
   - Performance, cost, complexity, maintainability?
   - Any hard requirements?

### Phase 2: Option Generation

4. **Generate diverse options**
   - Aim for 3-5 distinct approaches
   - Include conventional and unconventional ideas
   - Consider build vs buy vs adapt
   - Think short-term vs long-term

5. **Structure each option**
   ```markdown
   ### Option [N]: [Name]

   **Overview**: Brief description of the approach

   **How it works**:
   - Key component 1
   - Key component 2
   - Key component 3

   **Example**:
   [Code snippet or diagram if applicable]
   ```

6. **Ensure diversity**
   - Different technical approaches
   - Different trade-off priorities
   - Different complexity levels
   - Different risk profiles

### Phase 3: Evaluation

7. **Analyze each option**

   For each option, evaluate:

   **Pros:**
   - What problems does it solve well?
   - What advantages does it offer?
   - Where does it excel?

   **Cons:**
   - What problems does it create?
   - What are the drawbacks?
   - Where does it struggle?

   **Trade-offs:**
   - What are you giving up?
   - What are you gaining?
   - Is the trade-off worth it?

   **Risks:**
   - What could go wrong?
   - What's the worst case?
   - How can risks be mitigated?

8. **Create comparison matrix**
   ```markdown
   | Criterion | Option 1 | Option 2 | Option 3 |
   |-----------|----------|----------|----------|
   | Performance | High | Medium | High |
   | Complexity | Low | Medium | High |
   | Cost | Low | Medium | High |
   | Scalability | Medium | High | High |
   | Time to implement | 1 week | 2 weeks | 3 weeks |
   ```

### Phase 4: Recommendation

9. **Synthesize findings**
   - Which option best meets criteria?
   - Is there a clear winner?
   - Are there hybrid approaches?

10. **Make recommendation**
    ```markdown
    ## Recommendation

    **Selected Option**: Option [N] - [Name]

    **Rationale**:
    [Why this option best fits the constraints and criteria]

    **Key Trade-offs Accepted**:
    - Trade-off 1
    - Trade-off 2

    **Risks to Monitor**:
    - Risk 1: Mitigation strategy
    - Risk 2: Mitigation strategy

    **Alternative Considered**:
    Option [M] would be preferred if [condition changes]
    ```

11. **Define next steps**
    - What to do immediately
    - What to research further
    - What decisions to defer

### Phase 5: Documentation

12. **Generate brainstorm document**

```markdown
# Brainstorm: [Topic]

**Date**: [date]
**Participants**: User, Jarvis
**Status**: Complete

## Problem Statement
[Clear statement of what we're solving]

## Constraints
- Constraint 1
- Constraint 2

## Evaluation Criteria (Priority Order)
1. Criterion 1
2. Criterion 2
3. Criterion 3

## Options Explored

### Option 1: [Name]
**Overview**: [description]

**Pros**:
- Pro 1
- Pro 2

**Cons**:
- Con 1
- Con 2

**Effort**: [low/medium/high]
**Risk**: [low/medium/high]

### Option 2: [Name]
...

### Option 3: [Name]
...

## Comparison Matrix
| Criterion | Option 1 | Option 2 | Option 3 |
|-----------|----------|----------|----------|
| ... | ... | ... | ... |

## Recommendation
**Selected**: Option [N] - [Name]

**Rationale**: [explanation]

## Next Steps
1. Step 1
2. Step 2

## Deferred Decisions
- Decision 1: Revisit when [condition]
```

13. **Save to appropriate location**
    - Save to `.claude/brainstorms/` or `docs/decisions/`
    - Filename: `brainstorm-[topic-slug]-[date].md`

## Output

```markdown
## Brainstorm Complete

**Topic**: [topic]
**Options Explored**: [count]
**Recommended**: Option [N] - [Name]
**Saved to**: [file path]

### Quick Summary
[2-3 sentence summary of recommendation and key insight]

### Next Steps
- Create plan: `/plan [recommended approach]`
- Explore further: Ask about specific options
- Document decision: ADR format available
```

## Session Modes

**Quick brainstorm:**
```
/brainstorm auth approach --quick
```
Generates 3 options with brief analysis.

**Deep dive:**
```
/brainstorm database architecture --deep
```
Generates 5+ options with extensive analysis.

**Comparative:**
```
/brainstorm PostgreSQL vs MongoDB vs DynamoDB
```
Focused comparison of specific options.

**Creative:**
```
/brainstorm monetization strategies --creative
```
Encourages unconventional ideas.

## Interactive Mode

During the session, you can:

- **Add constraint**: "Also consider that we need to support offline mode"
- **Explore option**: "Tell me more about Option 2"
- **Add option**: "What about using a hybrid approach?"
- **Change criteria**: "Actually, cost is more important than performance"
- **Request recommendation**: "Which do you recommend and why?"

## Examples

**Technical decision:**
```
/brainstorm state management approach for our React app
```

**Architecture choice:**
```
/brainstorm microservices vs monolith for our MVP
```

**Feature design:**
```
/brainstorm notification system design
```

**Tool selection:**
```
/brainstorm CI/CD platform options
```

## Integration with Other Commands

```bash
# Brainstorm options
/brainstorm authentication providers

# Create plan for chosen approach
/plan implement Auth0 authentication

# Execute the plan
/execute docs/plans/plan-auth0.md
```

## Notes

- Encourage diverse thinking - include unconventional options
- Be explicit about trade-offs - no option is perfect
- Prioritize actionability - options should be implementable
- Document rationale - future you will thank present you
- Keep options distinct - avoid overlapping approaches
- Consider reversibility - prefer options that can be changed later
