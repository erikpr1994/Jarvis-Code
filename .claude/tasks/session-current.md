# Session - Linear Workflow Integration

## Session Context

**Created**: 2026-01-16
**Goal**: Add Linear-native workflows for specs and plans alongside existing markdown workflows
**Trigger**: User request to integrate specs as Linear Projects and plans as Milestones/Issues
**Scope**: Medium
**Status**: Complete

## Success Criteria

1. [x] `create-linear-spec` skill creates Linear Projects with spec content in description
2. [x] `create-linear-plan` skill creates Issues and Sub-issues from plan phases
3. [x] Both skills registered in skill-rules.json with appropriate triggers
4. [x] Existing markdown workflows remain unchanged
5. [x] Skills use same process as repo counterparts (brainstorming, writing-plans)

## Phase Breakdown

### Phase 1: Design & Create Skills
**Status**: Complete
**Deliverables**:
- `linear/spec/SKILL.md` - Uses brainstorming Discovery Mode
- `linear/plan/SKILL.md` - Uses writing-plans process
- `linear/issue/SKILL.md` - Existing issue creation (reorganized)
- `linear/README.md` - Organization documentation

### Phase 2: Register Skills
**Status**: Complete
**Deliverables**:
- Updated `~/.claude/skill-rules.json` (global)
- Updated worktree `skill-rules.json`
- Updated `~/.claude/commands/create-linear-spec.md`
- Updated `~/.claude/commands/create-linear-plan.md`

### Phase 3: Verification
**Status**: Complete
**Deliverables**: Directory structure verified

## Final Structure

```
linear/
├── README.md              # Organization overview
├── issue/
│   ├── SKILL.md           # Individual issue creation
│   └── templates/         # Bug, TODO, Question, Tech Debt, Feature
├── spec/
│   └── SKILL.md           # create-linear-spec (mirrors /spec)
└── plan/
    └── SKILL.md           # create-linear-plan (mirrors /plan)
```

## Work Log

### 2026-01-16 - Analysis
**Action**: Reviewed existing skill structure
**Result**: Understood Linear MCP tools and hierarchy

### 2026-01-16 - Implementation
**Action**: Created skills and reorganized directory
**Result**:
- Created create-linear-spec skill using brainstorming Discovery Mode
- Created create-linear-plan skill using writing-plans process
- Reorganized linear/ folder into issue/, spec/, plan/ subfolders
- Updated skill-rules.json files
- Created command files

## Architecture

```
Repo Workflow (unchanged):
/spec → brainstorming → docs/specs/*.md
/plan → writing-plans → docs/plans/*.md

Linear Workflow (new):
/create-linear-spec → brainstorming → Linear Project
/create-linear-plan → writing-plans → Linear Issues (phases + tasks)
```

## Key Design Decisions

1. **Process Parity**: Linear skills use SAME process as repo counterparts
   - `create-linear-spec` uses brainstorming Discovery Mode
   - `create-linear-plan` uses writing-plans process

2. **parentId for Sub-Issues**: Use `parentId` (not `relatedTo`) for parent-child

3. **Milestones Limitation**: Cannot create via MCP, must use Linear UI

## Session Closure

**Completed**: 2026-01-16
**Duration**: ~30 minutes
**Final Status**: Complete

### Accomplishments
- Created two new Linear-native workflow skills
- Reorganized linear skills into logical subfolders
- Maintained process parity with repo-based workflows
- Updated all registration files

### Follow-up Items
- [ ] Test workflows with real Linear workspace
- [ ] Consider creating milestone helper skill once API support available

---

## Extension: Create Linear Design Skill

**Date**: 2026-01-16
**Request**: Add technical design skill that outputs to Linear Document

### Work Completed
1. Created `linear/design/SKILL.md` - Uses brainstorming Approach Mode
2. Updated `~/.claude/skill-rules.json` - Added create-linear-design triggers
3. Updated worktree `skill-rules.json` - Added create-linear-design triggers
4. Created `~/.claude/commands/create-linear-design.md` command file
5. Updated `linear/README.md` - Added design folder and workflow step

### Final Structure
```
linear/
├── README.md              # Organization overview
├── issue/                 # Individual issue creation
├── spec/                  # create-linear-spec (mirrors /spec)
├── design/                # create-linear-design (mirrors /brainstorm how)
└── plan/                  # create-linear-plan (mirrors /plan)
```

### Process Parity Summary
| Repo Workflow | Linear Workflow | Process |
|---------------|-----------------|---------|
| `/spec` | `/create-linear-spec` | Brainstorming Discovery Mode |
| `/brainstorm how` | `/create-linear-design` | Brainstorming Approach Mode |
| `/plan` | `/create-linear-plan` | Writing-Plans Process |
