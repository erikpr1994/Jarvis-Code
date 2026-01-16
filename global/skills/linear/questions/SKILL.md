---
name: reply-linear-questions
description: Reply to Linear issues tagged with "question". Reviews questions and produces decisions - never code changes or PRs. Triggers - linear questions, answer questions, review questions, question triage.
---

# Reply Linear Questions

**Iron Law:** Questions produce DECISIONS, not CODE. No GitHub PRs, no implementation.

## Overview

This skill handles Linear issues tagged with "question". It reviews pending questions and produces decisions that guide future work.

```
Question → Analysis → Decision → Action Item
                         ↓
              Never: Code changes, PRs, Implementation
```

## Valid Outcomes

| Outcome | When to Use | Linear Action |
|---------|-------------|---------------|
| **Create Issue** | Question reveals work needed | Create new issue with details |
| **Create Spec** | Question needs discovery/requirements | `/create-linear-spec` |
| **Add to Project** | Work belongs in existing project | Add issue to project |
| **Update Existing** | Answer affects existing issue | Comment or update issue |
| **Close as Resolved** | Question answered, no work needed | Comment answer, close issue |
| **Close as Won't Do** | Out of scope or declined | Comment reasoning, close issue |

## Invalid Outcomes

- Writing code
- Creating GitHub PRs
- Making implementation changes
- Modifying files in the codebase

---

## The Workflow

### Step 1: List Pending Questions

```typescript
mcp__linear-server__list_issues({
  label: "question",
  state: "started",  // Or "triage", "backlog" based on your workflow
  limit: 20
});
```

### Step 2: Select a Question

Present questions to user or work through them:

```markdown
## Pending Questions

| ID | Title | Created | Priority |
|----|-------|---------|----------|
| PEA-123 | How should we handle auth tokens? | 2 days ago | High |
| PEA-145 | What's the pagination limit? | 1 week ago | Medium |

Which question would you like to address?
```

### Step 3: Analyze the Question

Read the full issue:

```typescript
mcp__linear-server__get_issue({ id: "issue-uuid" });
```

Understand:
- What is being asked?
- What context is provided?
- Who is asking? (stakeholder, team member, external)
- What's the impact of the answer?

### Step 4: Research if Needed

If the question requires investigation:
- Check existing documentation
- Review related issues
- Look at codebase for context (READ ONLY - no changes)
- Consult external resources

### Step 5: Formulate Decision

The decision should be:
- **Clear** - Unambiguous answer or direction
- **Actionable** - What happens next is obvious
- **Documented** - Reasoning is captured

### Step 6: Execute Decision

Based on decision type:

#### Create New Issue
```typescript
mcp__linear-server__create_issue({
  title: "[Resulting work from question]",
  description: `## Context\nFrom question PEA-123: [original question]\n\n## Decision\n[What we decided]\n\n## Work Required\n[Scope of work]`,
  team: "Engineering",
  labels: ["from-question"]
});
```

#### Create Spec
```
Use /create-linear-spec skill to explore requirements
```

#### Add to Project
```typescript
mcp__linear-server__update_issue({
  id: "existing-issue-uuid",
  project: "relevant-project"
});
```

#### Close with Answer
```typescript
// Add comment with answer
mcp__linear-server__create_comment({
  issueId: "question-issue-uuid",
  body: "## Answer\n\n[Your answer here]\n\n## Reasoning\n[Why this is the answer]"
});

// Close the issue
mcp__linear-server__update_issue({
  id: "question-issue-uuid",
  state: "Done"  // Or "Canceled" if won't do
});
```

### Step 7: Confirm Resolution

```markdown
## Question Resolved

**Question:** PEA-123 - How should we handle auth tokens?
**Decision:** Create spec for token management strategy
**Action Taken:** Created project "Auth Token Strategy" via /create-linear-spec
**Original Issue:** Closed with comment linking to new project

Next question or done for now?
```

---

## Decision Framework

Use this framework to decide outcomes:

```
Is the answer known?
├── YES → Does it require work?
│         ├── YES → Is scope clear?
│         │         ├── YES → Create Issue
│         │         └── NO → Create Spec
│         └── NO → Close with Answer
└── NO → Need more info?
          ├── YES → Research, then return to top
          └── NO → Close as Won't Do (with reasoning)
```

---

## Example Session

**User says:** `/reply-linear-questions`

**Step 1 - List:**
```
Found 3 questions:

1. PEA-201: Should we support OAuth2? (High priority, 3 days old)
2. PEA-215: What's the rate limit for API? (Medium, 1 week old)
3. PEA-220: Can we use Redis for caching? (Low, 2 weeks old)

Which question would you like to address?
```

**User:** "Let's do PEA-201"

**Step 3-4 - Analyze:**
```
## Question Analysis: PEA-201

**Question:** Should we support OAuth2?
**Asked by:** Product Manager
**Context:** Customer requests for SSO integration

**Research:**
- 3 enterprise customers requested this
- Current auth is email/password only
- OAuth2 would require new dependencies

**Impact:** High - affects architecture
```

**Step 5 - Decision:**
```
## Decision

This requires proper requirements gathering before implementation.

**Recommendation:** Create a spec to explore OAuth2 requirements
- Discover which OAuth providers to support
- Define scope (login only vs full authorization)
- Identify security requirements

Proceed with /create-linear-spec for OAuth2?
```

**User:** "Yes"

**Step 6-7 - Execute:**
```
Created spec project "OAuth2 Integration" via /create-linear-spec
Closed PEA-201 with comment linking to new project

## Question Resolved

**Question:** PEA-201 - Should we support OAuth2?
**Decision:** Create spec for proper requirements discovery
**Action:** Created "OAuth2 Integration" project
**Status:** Original question closed

Next question?
```

---

## Quick Reference

```
PROCESS: List → Select → Analyze → Research → Decide → Execute → Confirm
OUTPUT:  Decisions and Linear actions (issues, comments, state changes)
NEVER:   Code changes, GitHub PRs, file modifications

VALID OUTCOMES:
- Create issue (clear scope)
- Create spec (unclear scope)
- Add to project (existing work)
- Close with answer (no work needed)
- Close as won't do (out of scope)

TOOLS:
- mcp__linear-server__list_issues (find questions)
- mcp__linear-server__get_issue (read details)
- mcp__linear-server__create_issue (new work)
- mcp__linear-server__create_comment (add answer)
- mcp__linear-server__update_issue (close/update)
```

## Red Flags - STOP

- About to write code → STOP, this is a question skill
- About to create a PR → STOP, questions produce decisions
- About to modify files → STOP, read-only research allowed
- Unclear decision → STOP, ask for clarification

---

## Integration

**Uses:**
- **Linear MCP** - All issue operations
- **create-linear-spec** - When question needs requirements discovery
- **create-linear-plan** - When question reveals clear work items

**Does NOT use:**
- Git operations
- File write/edit operations
- PR submission skills

## Trigger Keywords

- "linear questions"
- "answer questions"
- "review questions"
- "question triage"
- "pending questions"
