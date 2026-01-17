# Linear Skills

This folder contains skills for integrating with Linear. Skills are organized by purpose.

## Organization

```
linear/
├── issue/            # Individual issue creation (bug, todo, question, etc.)
├── spec/             # Create Linear Project from spec (mirrors /spec)
├── design/           # Create Linear Document from design (mirrors /brainstorm how)
├── plan/             # Create Linear Issues from plan (mirrors /plan)
├── questions/        # Answer issues tagged "question" (decisions only)
├── bugs/             # Fix issues tagged "bug" (PR or won't fix)
├── tech-debt/        # Resolve issues tagged "tech-debt" (schedule/close)
├── feature-requests/ # Review feature requests (roadmap decisions)
├── cycle-planning/   # Plan issues for upcoming cycles
├── backlog-grooming/ # Clean up and maintain backlog
├── project-health/   # Generate project health reports
└── refine/           # Refine tickets in triage or tagged "refine"
```

## Naming Convention

Skills use action-oriented names that describe what they DO:

| Action | Command | Meaning |
|--------|---------|---------|
| **create** | `/create-linear-*` | Creates new Linear artifacts |
| **answer** | `/answer-linear-questions` | Provides answers/decisions |
| **fix** | `/fix-linear-bugs` | Fixes bugs with PRs |
| **resolve** | `/resolve-linear-tech-debt` | Resolves by scheduling or closing |
| **review** | `/review-linear-feature-requests` | Reviews and makes roadmap decisions |
| **linear** | `/linear-*` | Linear operations (planning, health, etc.) |

## Skill Categories

### Creation Skills (Input → Linear)

| Repo Workflow | Linear Workflow | Output |
|---------------|-----------------|--------|
| `/spec` | `/create-linear-spec` | File vs Linear Project |
| `/brainstorm how...` | `/create-linear-design` | File vs Linear Document |
| `/plan` | `/create-linear-plan` | File vs Linear Issues |
| N/A | `/linear` (issue skill) | Linear Issue |

### Response Skills (Linear → Action)

**All response skills EXPLORE THE CODEBASE before making decisions.**

| Skill | Trigger | Valid Outcomes |
|-------|---------|----------------|
| `/answer-linear-questions` | Tag: "question" | Decisions only (no code) |
| `/fix-linear-bugs` | Tag: "bug" | PR or won't fix explanation |
| `/resolve-linear-tech-debt` | Tag: "tech-debt" | Schedule or close |
| `/review-linear-feature-requests` | Tag: "feature-request" | Spec, roadmap, merge, reject |

### Management Skills (Linear Operations)

| Skill | Purpose | Frequency |
|-------|---------|-----------|
| `/linear-cycle-planning` | Plan upcoming cycle | Per cycle |
| `/linear-backlog-grooming` | Clean up backlog | Bi-weekly |
| `/linear-project-health` | Generate health report | Weekly |
| `/linear-refine-ticket` | Refine triage items | Ongoing |

## Process Parity

**Critical:** Linear workflows use the SAME PROCESS as their repo counterparts:

- `create-linear-spec` uses brainstorm (Discovery Mode)
- `create-linear-design` uses brainstorm (Approach Mode)
- `create-linear-plan` uses plan process

Only the output target differs.

## Codebase Exploration (Response Skills)

Response skills (`answer-`, `fix-`, `resolve-`, `review-`) all include **mandatory codebase exploration** before making decisions:

```
Issue → Read Details → EXPLORE CODEBASE → Informed Decision → Action
                            ↓
              - Find related files
              - Check existing patterns
              - Review git history
              - Identify dependencies
```

This ensures decisions are based on actual codebase context, not just the issue description.

## Linear Hierarchy

```
Workspace
└── Initiative (e.g., "App Beta")
    └── Project ← Spec goes here (description field)
        └── Document ← Design goes here
        └── Milestone (optional - UI only)
            └── Issue [Phase] ← Plan phases
                └── Sub-Issue [Task] ← Plan tasks (using parentId)
```

## Key Concept: `parentId`

To create sub-issues (parent-child relationship):

```typescript
// 1. Create parent issue
const parent = await create_issue({ title: "[Phase 1]..." });

// 2. Create sub-issue with parentId
await create_issue({
  title: "Task 1.1",
  parentId: parent.id  // ← Creates parent-child!
});
```

**DO NOT use `relatedTo`** - that creates "related" links, not parent-child.

## Full Creation Workflow

```
/spec [feature]           → Define WHAT/WHY (brainstorm Discovery)
    ↓
/create-linear-spec       → Linear Project (spec in description)
    ↓
/brainstorm how...        → Technical approach (brainstorm Approach)
    ↓
/create-linear-design     → Linear Document (design in project)
    ↓
/plan [feature]           → Define HOW (plan)
    ↓
/create-linear-plan       → Linear Issues (phases + tasks)
    ↓
/execute                  → Build it!
```

## Response Workflow

```
Questions:
  /answer-linear-questions → Explore codebase → Analyze → Decision → Close/Create work

Bugs:
  /fix-linear-bugs → Explore codebase → Reproduce → Fix (TDD → PR) OR Explain (won't fix)

Tech Debt:
  /resolve-linear-tech-debt → Assess impact → Schedule now/later OR Close

Feature Requests:
  /review-linear-feature-requests → Evaluate → Spec/Roadmap/Merge/Reject
```

## Management Workflow

```
Cycle Planning:
  /linear-cycle-planning → Review backlog → Prioritize → Balance → Assign

Backlog Grooming:
  /linear-backlog-grooming → Find stale → Merge duplicates → Update priorities

Project Health:
  /linear-project-health → Calculate metrics → Identify risks → Recommend actions

Ticket Refinement:
  /linear-refine-ticket → Add context → Write acceptance criteria → Define scope
```

## Labels Convention

| Label | Meaning | Used By |
|-------|---------|---------|
| `question` | Needs decision | answer-linear-questions |
| `bug` | Defect to fix | fix-linear-bugs |
| `tech-debt` | Technical debt | resolve-linear-tech-debt |
| `feature-request` | User/customer request | review-linear-feature-requests |
| `refine` | Needs refinement | linear-refine-ticket |
| `refined` | Ready for planning | linear-refine-ticket (output) |
| `phase` | Plan phase (parent) | create-linear-plan |
| `task` | Plan task (sub-issue) | create-linear-plan |
