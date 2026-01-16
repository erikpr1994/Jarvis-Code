---
name: create-linear-spec
description: Create a Linear Project from requirements using Discovery Mode brainstorming. Same process as /spec but outputs to Linear instead of file. Triggers - linear spec, spec to linear, create project from spec, linear project.
---

# Create Linear Spec

**Iron Law:** Same process as `/spec`, different output target. Discovery Mode → Linear Project.

## Overview

This skill runs the **brainstorming** skill in **Discovery Mode** and outputs the result to a **Linear Project** instead of a file.

```
/spec [feature]           → brainstorming (Discovery) → docs/specs/*.md
/create-linear-spec       → brainstorming (Discovery) → Linear Project
```

**Both use the same process. Only the output differs.**

## The Spec Rule

> **A spec contains WHAT and WHY. Never HOW.**

| In Spec | NOT In Spec |
|---------|-------------|
| User stories | Code snippets |
| Acceptance criteria | Technical approach |
| Success metrics | Database schema |
| Requirements | API design |
| Constraints | Implementation details |

---

## The Workflow

### Step 1: Run Discovery Mode (Brainstorming Skill)

**This is identical to `/spec`:**

```
1. EXPLORE    → What problems exist? Who has them?
2. BRAINSTORM → What are ALL the things this could do?
3. PRIORITIZE → What's essential vs nice-to-have? (MoSCoW)
4. SPECIFY    → Write user stories + acceptance criteria
5. VALIDATE   → Review with user before creating
```

### Step 2: Explore the Problem Space

```markdown
## Problem Exploration

**Who has this problem?**
- Primary user: [persona]
- Secondary users: [others affected]

**What's the pain today?**
- [Current workaround 1]
- [Current workaround 2]

**What triggers the need?**
- [Trigger event 1]

**What does success look like?**
- [Outcome 1]
- [Outcome 2]
```

### Step 3: Brainstorm Requirements

Generate ALL possible requirements without filtering:

```markdown
## Raw Requirements (Unfiltered)

### Core Functionality
- [ ] [Requirement] - even if obvious
- [ ] [Requirement] - even if complex

### User Experience
- [ ] [UX requirement]

### Edge Cases
- [ ] What if [edge case]?
```

**Quantity over quality at this stage.**

### Step 4: Prioritize (MoSCoW)

```markdown
## Prioritized Requirements

### Must Have (P0) - Without these, feature is useless
- [ ] [Requirement 1]

### Should Have (P1) - Important but not critical
- [ ] [Requirement 2]

### Could Have (P2) - Nice to have
- [ ] [Requirement 3]

### Won't Have (This Release)
- [Requirement 4] - Reason: [why deferred]
```

### Step 5: Write User Stories

```markdown
## User Stories

### US-1: [Title]

**As a** [user type]
**I want to** [action]
**So that** [benefit]

**Acceptance Criteria:**
- [ ] Given [context], when [action], then [result]
- [ ] Given [context], when [action], then [result]
```

### Step 6: Validate Before Creating

Show the user the complete spec for approval:

```markdown
## Proposed Linear Project

**Name:** [Feature Name]
**Summary:** [One-line summary, max 255 chars]

**Description:** (Full spec below)

---
[Full spec content]
---

Create this Linear Project? I can adjust before creating.
```

### Step 7: Select Initiative & Create Linear Project

List available initiatives:
```typescript
mcp__linear-server__list_projects({ state: "started", limit: 50 })
```

Once approved, use Linear MCP:

```typescript
mcp__linear-server__create_project({
  name: "[Feature Name]",
  summary: "[One-line summary]",  // Max 255 chars
  description: `[Full spec content in Markdown]`,
  team: "[Team Name]",
  initiative: "[Initiative ID]",  // Optional
  state: "planned"
});
```

### Step 8: Confirm Creation

```markdown
## Linear Spec Created

**Project:** [Feature Name]
**Team:** [Team Name]
**Initiative:** [Initiative Name]
**URL:** https://linear.app/[workspace]/project/[slug]

**Next Steps:**
- Technical approach: `/brainstorm how to implement [feature]`
- Create plan: `/plan [feature]`
- Sync plan to Linear: `/create-linear-plan`
```

---

## Project Description Template

The spec should be formatted as Markdown in the project description:

```markdown
# [Feature Name] Spec

**Status**: Draft
**Created**: [Date]

## Problem Statement
[2-3 sentences on the problem being solved]

## Target Users
- **Primary**: [Who] - [Goal]
- **Secondary**: [Who] - [Goal]

## Success Metrics
| Metric | Current | Target |
|--------|---------|--------|
| [Metric] | X | Y |

---

## User Stories

### US-1: [Title]

**As a** [user type]
**I want to** [action]
**So that** [benefit]

**Acceptance Criteria:**
- [ ] Given [context], when [action], then [result]
- [ ] Given [context], when [action], then [result]

### US-2: [Title]
[Same format]

---

## Out of Scope
- [Explicitly excluded 1]
- [Explicitly excluded 2]

## Open Questions
- [ ] [Question 1]
- [ ] [Question 2]

---
*Generated via /create-linear-spec*
```

---

## Example

**User says:** `/create-linear-spec user notifications`

**Steps 1-5 - Discovery Mode:**

```
Problem: Users miss important updates, have to refresh manually
Who: All authenticated users
Triggers: New message, status change, mention

Requirements (brainstormed):
- Real-time in-app notifications
- Email fallback for away users
- Notification preferences
- Read/unread status
- Notification center
- Push notifications
- Do not disturb
- Digest mode

Prioritized:
- P0: In-app real-time, read status
- P1: Email fallback, preferences
- P2: Push, digest mode
```

**Step 6 - Validate:**

```markdown
## Proposed Linear Project

**Name:** User Notifications
**Summary:** Real-time notifications for important events with email fallback

**Description:**
[Full spec with 4 user stories, acceptance criteria, metrics]

Create this Linear Project?
```

**Step 7 - Create:**

```typescript
mcp__linear-server__create_project({
  name: "User Notifications",
  summary: "Real-time notifications for important events with email fallback",
  description: "[Full spec content]",
  team: "Engineering",
  initiative: "app-beta-uuid",
  state: "planned"
})
```

**Step 8 - Confirm:**

```
## Linear Spec Created

**Project:** User Notifications
**URL:** https://linear.app/pea/project/user-notifications

Next: `/brainstorm how to implement notifications`
Then: `/plan notifications` → `/create-linear-plan`
```

---

## Quick Reference

```
PROCESS: Same as /spec (brainstorming Discovery Mode)
OUTPUT:  Linear Project (spec in description)
TOOLS:   mcp__linear-server__create_project

1. EXPLORE    → Problem space
2. BRAINSTORM → All requirements
3. PRIORITIZE → MoSCoW (P0/P1/P2)
4. SPECIFY    → User stories + AC
5. VALIDATE   → User approval
6. SELECT     → Choose initiative
7. CREATE     → Linear Project
8. CONFIRM    → Return URL
```

## Red Flags - STOP

- Skipping Discovery Mode and just converting a file
- Adding implementation details to spec
- No user stories, just feature list
- Missing acceptance criteria
- No prioritization
- Creating without user validation

---

## Integration

**Uses:**
- **brainstorming** skill (Discovery Mode) - Same process
- **Linear MCP** - Output target

**Mirrors:**
- `/spec` - Same process, different output (file vs Linear)

**Pairs with:**
- `/brainstorm how...` - Technical approach after spec
- `/create-linear-plan` - Implementation issues
