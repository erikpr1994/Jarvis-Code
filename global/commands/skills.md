---
name: skills
description: List available skills, show activation keywords, and indicate which are currently loaded
disable-model-invocation: false
---

# /skills - List Available Skills

Display all available skills, their activation keywords, and current loading status.

## What It Does

1. **Lists all skills** - Shows skills from global and project directories
2. **Shows activation** - Displays keywords that trigger each skill
3. **Indicates status** - Shows which skills are currently loaded
4. **Provides details** - Can show full skill documentation

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | Optional skill name or filter | "git", "process", "--loaded" |

## Process

### Phase 1: Skill Discovery

1. **Scan skill directories**
   - Global: `~/.claude/skills/`
   - Project: `.claude/skills/`
   - Built-in: Jarvis core skills

2. **Parse skill metadata**
   - Read SKILL.md or skill markdown files
   - Extract name, description, triggers
   - Identify category (meta, process, domain, etc.)

3. **Check loading status**
   - Read skill-rules.json
   - Identify currently active skills
   - Note auto-loaded vs on-demand

### Phase 2: Categorization

4. **Group skills by category**

   | Category | Description |
   |----------|-------------|
   | **Meta** | Skills about using the system |
   | **Process** | Development methodology |
   | **Execution** | Task execution patterns |
   | **Domain** | Technical expertise |
   | **Project** | Project-specific skills |

5. **Identify loading strategy**
   - Always loaded (meta, process)
   - Keyword-triggered (domain)
   - Explicitly invoked (project)

### Phase 3: Output Generation

6. **Generate skill listing**

```markdown
## Available Skills

### Meta Skills (Always Loaded)
| Skill | Description | Status |
|-------|-------------|--------|
| **using-skills** | How to discover and use skills | Loaded |
| **writing-skills** | How to write new skills | Loaded |
| **writing-commands** | How to write commands | Loaded |
| **writing-rules** | How to write rules | Loaded |
| **improving-jarvis** | System improvement guide | Loaded |

### Process Skills (Always Loaded)
| Skill | Description | Status |
|-------|-------------|--------|
| **test-driven-development** | TDD methodology | Loaded |
| **verification-before-completion** | Final verification | Loaded |
| **systematic-debugging** | Debug methodology | Loaded |
| **writing-plans** | Plan creation | Loaded |
| **executing-plans** | Plan execution | Loaded |
| **brainstorming** | Ideation sessions | Loaded |

### Domain Skills (Keyword-Triggered)
| Skill | Triggers | Status |
|-------|----------|--------|
| **git-expert** | git, commit, branch, PR | On-demand |
| **frontend-design** | UI, design, component | On-demand |
| **payment-processing** | payment, stripe, checkout | On-demand |
| **infra-ops** | deploy, docker, server | On-demand |
| **analytics** | analytics, tracking, metrics | On-demand |

### Project Skills (This Project)
| Skill | Description | Status |
|-------|-------------|--------|
| **domain-expert** | Project domain knowledge | Available |
| **archon** | Task management | Available |
```

## Output Modes

**List all skills:**
```
/skills
```

**Filter by category:**
```
/skills process
```

**Show only loaded:**
```
/skills --loaded
```

**Show skill details:**
```
/skills git-expert
```

**Search skills:**
```
/skills --search "deployment"
```

## Detailed Skill View

When a specific skill is requested:

```markdown
## Skill: git-expert

**Category**: Domain
**Status**: On-demand
**Location**: `~/.claude/skills/domain/git-expert.md`

### Description
Expert-level git operations including complex workflows, rebasing, cherry-picking, and PR management.

### Activation Triggers
- Keywords: `git`, `commit`, `branch`, `merge`, `rebase`, `PR`, `pull request`
- Commands: `/commit`, `/review`
- Patterns: Git-related error messages

### Sub-Skills
- **submit-pr** - Full PR pipeline
- **git-worktrees** - Parallel development
- **branch-finishing** - Clean branch completion

### Usage Example
"Help me rebase my feature branch onto main and resolve conflicts"

### Related Skills
- code-review
- systematic-debugging
```

## Skill Activation

Skills can be activated by:

1. **Keywords in conversation**
   - "I need to set up payments" triggers `payment-processing`
   - "Help me debug this" triggers `systematic-debugging`

2. **Explicit invocation**
   - "Use the git-expert skill"
   - "Load the frontend-design skill"

3. **Command delegation**
   - `/plan` loads `writing-plans`
   - `/commit` loads `git-expert`

## Examples

**List all skills:**
```
/skills
```

**Show process skills:**
```
/skills process
```

**Get details on a skill:**
```
/skills systematic-debugging
```

**Find skills for a topic:**
```
/skills --search "testing"
```

**Show loaded skills only:**
```
/skills --loaded
```

**Show skill keywords:**
```
/skills --triggers
```

## Skill Management

**Refresh skill list:**
```
/skills --refresh
```
Re-scans directories for new or modified skills.

**Check skill health:**
```
/skills --check
```
Validates all skills have required metadata.

## Output Format Options

**Compact list:**
```
/skills --compact
```

**JSON format:**
```
/skills --json
```

**Markdown table:**
```
/skills --table
```

## Notes

- Skills are automatically loaded based on conversation context
- Explicitly loading a skill overrides on-demand behavior
- Project skills take precedence over global skills
- Use `/skills [name]` to see full skill documentation
- Skills can reference other skills via sub-skills
- Loading status resets each session
