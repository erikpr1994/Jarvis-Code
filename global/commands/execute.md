---
name: execute
description: Execute an implementation plan with verification checkpoints and progress reporting
disable-model-invocation: false
---

# /execute - Execute Implementation Plan

Execute a structured implementation plan with verification checkpoints, progress tracking, and quality gates.

## What It Does

1. **Loads plan** - Reads and parses the plan file
2. **Validates prerequisites** - Checks dependencies are met
3. **Executes phases** - Works through tasks systematically
4. **Verifies checkpoints** - Runs verification at each phase boundary
5. **Reports progress** - Provides clear status updates

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | Path to plan file or plan identifier | "docs/plans/plan-auth-2024-01-15.md" |

## Delegates To

This command delegates to the **executing-plans** skill for systematic execution methodology.

## Process

### Phase 1: Plan Loading

1. **Locate plan file**
   - Check if argument is a file path
   - Search in `docs/plans/` and `.claude/tasks/`
   - List available plans if not found

2. **Parse plan structure**
   - Extract phases and tasks
   - Identify checkpoints
   - Note dependencies and prerequisites

3. **Validate plan**
   - All phases have verification criteria
   - Tasks are actionable
   - Dependencies are identifiable

### Phase 2: Prerequisites Check

4. **Verify environment**
   - Required tools installed
   - Dependencies available
   - Correct branch/state

5. **Check blockers**
   - Unmet dependencies
   - Missing files or configurations
   - Incomplete prior phases

6. **Report readiness**
   ```markdown
   ## Execution Readiness

   **Plan**: [plan name]
   **Status**: Ready / Blocked

   ### Prerequisites
   - [x] Prerequisite 1
   - [x] Prerequisite 2
   - [ ] Prerequisite 3 (BLOCKER)

   ### Starting Phase
   Phase 1: [name]
   ```

### Phase 3: Systematic Execution

7. **For each phase:**

   a. **Announce phase start**
   ```markdown
   ## Starting Phase [N]: [Name]
   **Objective**: [What this phase accomplishes]
   **Tasks**: [count]
   ```

   b. **Execute tasks sequentially**
   - Mark task as in-progress
   - Complete the task
   - Verify task completion
   - Mark task as complete

   c. **Run checkpoint verification**
   - Execute verification commands
   - Check expected outcomes
   - Document results

   d. **Report phase completion**
   ```markdown
   ## Phase [N] Complete

   **Tasks completed**: [X/Y]
   **Verification**: Passed / Failed

   ### Results
   - Result 1
   - Result 2

   ### Issues Encountered
   - Issue 1 (resolved)
   - Issue 2 (deferred to Phase N+1)
   ```

8. **Handle failures gracefully**
   - Stop at failed checkpoint
   - Report what succeeded
   - Identify what failed
   - Suggest remediation

### Phase 4: Verification Gates

9. **At each checkpoint:**
   - Run specified verification commands
   - Compare against expected outcomes
   - Pass: Continue to next phase
   - Fail: Stop and report

10. **Quality gates**
    - Tests pass (if applicable)
    - Linting passes
    - Type checking passes
    - Build succeeds

### Phase 5: Completion

11. **Final verification**
    - All phases complete
    - All checkpoints passed
    - Success criteria met

12. **Generate completion report**
    ```markdown
    ## Execution Complete

    **Plan**: [plan name]
    **Duration**: [time taken]
    **Status**: Success / Partial / Failed

    ### Summary
    | Phase | Status | Duration |
    |-------|--------|----------|
    | Phase 1 | Complete | 5m |
    | Phase 2 | Complete | 12m |
    | Phase 3 | Complete | 8m |

    ### Deliverables
    - [x] Feature implemented
    - [x] Tests added
    - [x] Documentation updated

    ### Quality Checks
    - Tests: Passed (15/15)
    - Lint: Passed
    - Types: Passed
    - Build: Passed

    ### Next Steps
    - Create PR: `/jarvis-review pr`
    - Commit changes: `/commit`
    ```

## Output Modes

**Normal execution:**
```
/execute docs/plans/plan-auth.md
```
Executes with progress reporting at each task.

**Verbose mode:**
```
/execute docs/plans/plan-auth.md --verbose
```
Detailed output for each step.

**Dry run:**
```
/execute docs/plans/plan-auth.md --dry-run
```
Shows what would be executed without making changes.

**Resume from phase:**
```
/execute docs/plans/plan-auth.md --from-phase 2
```
Resume execution from a specific phase.

## Progress Tracking

During execution, maintain progress state:

```markdown
## Current Progress

**Plan**: plan-auth-2024-01-15.md
**Current Phase**: 2 of 3
**Current Task**: 2.3 of 2.5

### Completed
- [x] Phase 1: Foundation (5 tasks)
- [ ] Phase 2: Core Implementation (2/5 tasks)
- [ ] Phase 3: Integration (0/4 tasks)

### Currently Working On
Task 2.3: Implement password hashing

### Blockers
None
```

## Error Handling

**On task failure:**
1. Stop execution
2. Report what completed
3. Identify failure point
4. Suggest remediation options:
   - Fix and resume: `/execute [plan] --from-task 2.3`
   - Skip and continue: `/execute [plan] --skip 2.3`
   - Abort: Stop execution

**On checkpoint failure:**
1. Do not proceed to next phase
2. Report checkpoint results
3. List what needs fixing
4. Offer to re-run checkpoint after fixes

## Examples

**Execute a plan:**
```
/execute docs/plans/plan-user-profile.md
```

**Resume from phase 2:**
```
/execute plan-auth.md --from-phase 2
```

**Dry run to preview:**
```
/execute plan-refactor.md --dry-run
```

**List available plans:**
```
/execute --list
```

## Integration with Other Commands

```bash
# Create plan first
/plan add payment integration

# Execute the plan
/execute docs/plans/plan-payment-integration.md

# Review and commit when done
/review
/commit
```

## Notes

- Never skip verification checkpoints without explicit user approval
- Update plan file with actual outcomes if they differ from expected
- Stop on failures rather than continuing with broken state
- Each task should leave the codebase in a working state
- Use the todo list to track progress during execution
