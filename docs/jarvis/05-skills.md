# Skill Taxonomy

> Part of the [Jarvis Specification](./README.md)

## 6. Skill Taxonomy

### 6.1 Skill Categories

| Category | Purpose | Loading Strategy |
|----------|---------|------------------|
| **Meta** | How to use the system | Always (minimal size) |
| **Process** | Workflow discipline | Always (critical for quality) |
| **Execution** | How to execute tasks | On-demand |
| **Domain** | Technical expertise | On-demand (keyword-triggered) |
| **Project** | Project-specific workflows | Project-level only |

### 6.2 Meta Skills (Always Loaded)

| Skill | Source | Purpose |
|-------|--------|---------|
| **using-skills** | Superpowers/Peak-Health | How to find and invoke skills (1% rule) |
| **writing-skills** | Superpowers/Peak-Health | How to write new skills (TDD approach) |
| **writing-rules** | Peak-Health | How to write new rules |
| **writing-agents** | Peak-Health | How to write new agents |
| **writing-commands** | Peak-Health | How to write new commands |
| **writing-hooks** | Peak-Health | How to write new hooks |
| **writing-patterns** | Jarvis | How to document reusable patterns |
| **writing-claude-md** | Jarvis | How to write hierarchical CLAUDE.md files |
| **improving-jarvis** | Jarvis | How to identify and implement system improvements |

#### 6.2.1 Writing Guide Contents

Each `writing-*` skill follows a consistent structure:

```markdown
# Writing [Component Type]

## When to Create
[Criteria for when a new component is needed]

## Structure Template
[File structure and required sections]

## Quality Checklist
[What makes a good component of this type]

## Testing Requirements
[How to validate the component works]

## Examples
[Good and bad examples with explanations]

## Common Mistakes
[Anti-patterns to avoid]
```

#### 6.2.2 Component Guide Summaries

| Guide | Key Content |
|-------|-------------|
| **writing-skills** | Trigger conditions, when-to-invoke, TDD testing, bulletproofing against rationalizations |
| **writing-rules** | Confidence thresholds, good/bad examples, false positive prevention, category assignment |
| **writing-agents** | Role definition, model selection, skills to invoke, output format, handoff protocols |
| **writing-commands** | Frontmatter format, skill delegation, user prompts, success criteria |
| **writing-hooks** | Hook types, input/output format, timeout handling, bypass conditions |
| **writing-patterns** | Index entry, keyword triggers, code examples, anti-patterns, versioning |
| **writing-claude-md** | Inheritance rules, token budget, folder detection, template selection |
| **improving-jarvis** | Learning triggers, validation process, rollback procedures, metrics tracking |

#### 6.2.3 The Improving-Jarvis Skill

This special meta-skill guides the auto-improvement system:

```markdown
# Improving Jarvis

## When to Trigger
- Repeated manual guidance (same instruction 3+ times)
- Discovered pattern not in library
- Workflow inefficiency noticed
- User explicitly requests improvement

## Improvement Types

### 1. Add Pattern
- Document in patterns/ with index entry
- Add keywords for skill-activation
- Test with 3 example prompts

### 2. Create Skill
- Follow writing-skills guide
- Run RED-GREEN-REFACTOR tests
- Add to skill-rules.json

### 3. Update Rule
- Modify existing rule with new case
- Test for false positive rate
- Preserve backward compatibility

### 4. Add Hook
- Follow writing-hooks guide
- Test with edge cases
- Add graceful failure handling

## Validation Process
1. Create component following guide
2. Run component-specific tests
3. Monitor for regressions (3 sessions)
4. Auto-rollback if quality drops
5. Mark as stable after validation period

## Rollback Triggers
- False positive rate > 10%
- User reverts change manually
- Component causes degradation
- Test failures after change
```

### 6.3 Process Skills (Always Loaded)

| Skill | Source | Purpose |
|-------|--------|---------|
| **test-driven-development** | Superpowers | Iron Law TDD (no exceptions) |
| **verification-before-completion** | Superpowers/Peak-Health | Mandatory final verification |
| **plan** | Superpowers/Peak-Health | Structured planning methodology |
| **execute** | Superpowers/Peak-Health | Plan execution with checkpoints |
| **debug** | Superpowers/Peak-Health | Root cause analysis, defense in depth |
| **brainstorm** | Superpowers | Ideation and creative thinking |

### 6.4 Execution Skills (On-Demand)

| Skill | Source | Trigger |
|-------|--------|---------|
| **subagent-driven-development** | Superpowers/Peak-Health | Complex features requiring multi-stage review |
| **dispatching-parallel-agents** | Superpowers/Peak-Health | Multiple independent tasks |
| **session** | CodeFast | Multi-phase workflows |
| **sub-agent-invocation** | CodeFast | Agent delegation |

### 6.5 Domain Skills (Keyword-Triggered)

| Skill | Source | Triggers |
|-------|--------|----------|
| **git-expert** | Peak-Health | git, commit, branch, PR, merge |
| **submit-pr** | Peak-Health | submit, PR, pull request, review |
| **coderabbit** | Peak-Health | review, coderabbit |
| **frontend-design** | CodeFast | UI, design, component, styling |
| **payment-processing** | CodeFast | payment, stripe, polar, checkout |
| **seo-content-generation** | CodeFast | SEO, content, blog, article |
| **analytics** | CodeFast | analytics, tracking, metrics |
| **infra-ops** | CodeFast | deploy, docker, server, VPS |
| **documentation-research** | CodeFast | docs, documentation, library |
| **browser-debugging** | CodeFast | browser, devtools, frontend debug |
| **crawl-cli** | CodeFast | crawl, scrape, extract |
| **idea-to-product** | CodeFast | idea, product, SaaS, startup |

### 6.6 Project Skills (Project-Specific)

| Skill | Source | When to Include |
|-------|--------|-----------------|
| **domain-expert** | Peak-Health | Projects with domain expertise |
| **build-in-public** | Peak-Health | Content/marketing projects |
| **new-skills** | CodeFast | Skill creation workflows |
| **archon** | CodeFast | Task management with Kanban |

---

### 6.7 Skill Consolidation Analysis (COMPLETE)

#### 6.7.1 All Skills Inventory

**CodeFast (16 skills):**
analytics, archon, browser-debugging, codebase-navigation, crawl-cli, documentation-research, frontend-design, git-commits, idea-to-product, infra-ops-clean, new-skills, payment-processing-clean, seo-content-generation, session, sub-agent-invocation

**Superpowers (14 skills):**
brainstorm, dispatching-parallel-agents, execute, finishing-a-development-branch, receiving-code-review, requesting-code-review, subagent-driven-development, debug, test-driven-development, using-git-worktrees, using-superpowers, verification-before-completion, plan, writing-skills

**Peak-Health (19 skills):**
brainstorm, build-in-public, coderabbit, dispatching-parallel-agents, domain-expert, execute, git-expert, subagent-driven-development, debug, test-driven-development, using-skills, verification-before-completion, writing-agents, writing-commands, writing-design, writing-hooks, plan, writing-rules, writing-skills

**TOTAL: 49 skills (with significant overlap)**

---

#### 6.7.2 Consolidation Decisions

##### META SKILLS (Always Loaded - ~10)

| Skill | Sources | Decision | Notes |
|-------|---------|----------|-------|
| **using-skills** | Superpowers, Peak-Health | **KEEP Peak-Health** | Cleaner, 1% rule |
| **writing-skills** | Superpowers, Peak-Health | **KEEP Superpowers** | More comprehensive, TDD approach |
| **plan** | Superpowers, Peak-Health | **KEEP Superpowers** | Well-structured |
| **writing-design** | Peak-Health | **KEEP** | Unique, valuable |
| **writing-rules** | Peak-Health | **KEEP** | Unique, needed |
| **writing-agents** | Peak-Health | **KEEP** | Unique, needed |
| **writing-commands** | Peak-Health | **KEEP** | Unique, needed |
| **writing-hooks** | Peak-Health | **KEEP** | Unique, needed |
| **writing-patterns** | NEW | **CREATE** | For pattern library |
| **improving-jarvis** | NEW | **CREATE** | Auto-improvement guide |

##### PROCESS SKILLS (Always Loaded - ~6)

| Skill | Sources | Decision | Notes |
|-------|---------|----------|-------|
| **test-driven-development** | Superpowers, Peak-Health | **KEEP Superpowers** | Most comprehensive, bulletproofed |
| **verification-before-completion** | Superpowers, Peak-Health | **KEEP Superpowers** | Well-designed |
| **debug** | Superpowers, Peak-Health | **KEEP Superpowers** | Multi-file with pressure tests |
| **brainstorm** | Superpowers, Peak-Health | **MERGE** | Combine best of both |
| **execute** | Superpowers, Peak-Health | **KEEP Peak-Health** | Better integration |
| **session** | CodeFast | **ADAPT** | Simplify, remove embedded agents |

##### EXECUTION SKILLS (On-Demand - ~5)

| Skill | Sources | Decision | Notes |
|-------|---------|----------|-------|
| **subagent-driven-development** | Superpowers, Peak-Health | **KEEP Peak-Health** | Better structured |
| **dispatching-parallel-agents** | Superpowers, Peak-Health | **KEEP Superpowers** | Cleaner |
| **sub-agent-invocation** | CodeFast | **MERGE** | Into subagent-driven-development |
| **codebase-navigation** | CodeFast | **DROP** | Explore agent does this |
| **documentation-research** | CodeFast | **DROP** | Context7 MCP handles this |

##### GIT SKILLS (On-Demand - ~3)

| Skill | Sources | Decision | Notes |
|-------|---------|----------|-------|
| **git-expert** | Peak-Health | **KEEP** | Lean, has sub-skills |
| **submit-pr** | Peak-Health (sub-skill) | **KEEP** | Full PR pipeline |
| **git-commits** | CodeFast | **MERGE** | Into git-expert |
| **using-git-worktrees** | Superpowers | **MERGE** | Into git-expert |
| **finishing-a-development-branch** | Superpowers | **MERGE** | Into git-expert |

##### CODE REVIEW SKILLS (On-Demand - ~2)

| Skill | Sources | Decision | Notes |
|-------|---------|----------|-------|
| **coderabbit** | Peak-Health | **KEEP** | Integration skill |
| **receiving-code-review** | Superpowers | **DROP** | Agents handle this |
| **requesting-code-review** | Superpowers | **DROP** | submit-pr handles this |

##### DOMAIN SKILLS (Keyword-Triggered - ~12)

| Skill | Source | Decision | Triggers |
|-------|--------|----------|----------|
| **frontend-design** | CodeFast | **KEEP (ADAPT)** | UI, design, component |
| **payment-processing** | CodeFast | **KEEP (ADAPT)** | payment, stripe, polar |
| **seo-content-generation** | CodeFast | **KEEP (ADAPT)** | SEO, content, blog |
| **analytics** | CodeFast | **KEEP (ADAPT)** | analytics, tracking |
| **infra-ops** | CodeFast | **KEEP (ADAPT)** | deploy, docker, VPS |
| **browser-debugging** | CodeFast | **KEEP (ADAPT)** | browser, devtools |
| **crawl-cli** | CodeFast | **KEEP (ADAPT)** | crawl, scrape |
| **idea-to-product** | CodeFast | **KEEP (ADAPT)** | idea, product, SaaS |
| **domain-expert** | Peak-Health | **KEEP** | Project-specific |
| **build-in-public** | Peak-Health | **KEEP** | Content, marketing |
| **archon** | CodeFast | **EVALUATE** | Task management |
| **new-skills** | CodeFast | **MERGE** | Into writing-skills |

---

#### 6.7.3 Final Skill Count

| Category | Count | Skills |
|----------|-------|--------|
| **Meta (Always)** | 10 | using-skills, writing-skills, plan, writing-design, writing-rules, writing-agents, writing-commands, writing-hooks, writing-patterns, improving-jarvis |
| **Process (Always)** | 6 | test-driven-development, verification-before-completion, debug, brainstorm, execute, session |
| **Execution** | 3 | subagent-driven-development, dispatching-parallel-agents |
| **Git** | 2 | git-expert (with sub-skills: submit-pr, worktrees, branch-finishing) |
| **Code Review** | 1 | coderabbit |
| **Domain** | 10 | frontend-design, payment-processing, seo-content, analytics, infra-ops, browser-debugging, crawl-cli, idea-to-product, domain-expert, build-in-public |
| **TOTAL** | 32 | Down from 49 (35% reduction) |

---

#### 6.7.4 Skill Style Guidelines

Based on the best examples:

**Superpowers Style (for Process Skills):**
- Comprehensive, bulletproofed against rationalizations
- Includes "Common Rationalizations" section
- Includes "Red Flags - STOP and Start Over"
- Examples with Good/Bad comparisons
- Verification checklists

**Peak-Health Style (for Domain Skills):**
- Lean and focused (50-150 lines)
- References rules files
- Has sub-skills for complex workflows
- Quick reference tables
- Clear triggers in description

**Skill Structure Template:**

```markdown
---
name: skill-name
description: [When to use this skill - include trigger phrases]
---

# Skill Title

## Overview
[Brief description - what and why]

## When to Use
[Explicit conditions that trigger this skill]

## Core Process
[Main workflow/steps]

## Examples
[Good and bad examples if applicable]

## Common Rationalizations
[For process skills - counter-arguments]

## Red Flags
[Signs you're not following the skill]

## Verification Checklist
[Before marking complete]

## Sub-Skills
[If applicable - reference related skills]
```

---

#### 6.7.5 Skill Loading Strategy

| Category | Loading | Token Budget |
|----------|---------|--------------|
| **Meta** | Session start | ~500 tokens total (summaries) |
| **Process** | Always in context | ~2000 tokens total |
| **Execution** | When orchestrating | ~500 tokens each |
| **Git** | When git commands detected | ~300 tokens |
| **Code Review** | When review requested | ~200 tokens |
| **Domain** | Keyword triggered | ~500 tokens each |

**Optimization:**
- Load skill summaries always (~100 tokens each)
- Load full skill on explicit invocation
- Skills with supporting files: load SKILL.md first, supporting docs on demand
