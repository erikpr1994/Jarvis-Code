# Jarvis Agents

Reusable agent configurations that can be invoked across projects. Agents run in separate context windows with specialized expertise.

## Native vs Custom Agents

**Use native Claude Code subagents first** when they fit your needs:

| Task | Native Subagent | Custom Agent |
|------|-----------------|--------------|
| Codebase exploration | `Task(subagent_type='Explore')` | - |
| Implementation planning | `Task(subagent_type='Plan')` | - |
| General research | `Task(subagent_type='general-purpose')` | - |
| External web research | - | `deep-researcher` |
| Code review with project rules | - | `code-reviewer` |
| TDD implementation | - | `implementer` |
| Security audit | - | `security-reviewer` |

**When to use custom agents:**
- Need project-specific rules/context
- Specialized domain knowledge (security, a11y, SEO)
- Multi-step workflows with specific output formats
- Integration with Jarvis skills and patterns

## Agent Categories

| Category | Purpose | Model | Examples |
|----------|---------|-------|----------|
| **Core** | Always available, essential workflows | Opus/Sonnet | orchestrator, implementer, reviewer |
| **Review** | On-demand code quality checks | Sonnet | security, performance, accessibility |
| **Utility** | Specialized tasks | Sonnet/Opus | debug, refactor, test-generator |

## Core Agents (Always Available)

### master-orchestrator
**Model:** Opus | **Purpose:** Complex task coordination and multi-agent workflows

Use for: Planning features, breaking down complex tasks, coordinating multi-phase implementations.

**Triggers:** "plan this feature", "coordinate this implementation", "break down this project"

---

### implementer
**Model:** Sonnet | **Purpose:** TDD-based feature implementation

Use for: Building new features, creating components, implementing functionality using test-driven development.

**Triggers:** "implement this feature", "build this component", "create this API endpoint"

---

### code-reviewer
**Model:** Opus | **Purpose:** Comprehensive multi-file code review

Use for: Pre-merge reviews, validating implementations, catching issues before production.

**Triggers:** "review my changes", "check this PR", "code review before merge"

---

### spec-reviewer
**Model:** Sonnet | **Purpose:** Verify implementation matches specification

Use for: Validating feature completeness, catching deviations from requirements, detecting scope creep.

**Triggers:** "verify this matches spec", "check implementation against requirements", "does this match the plan"

---

### deep-researcher
**Model:** Opus | **Purpose:** External research with multi-source validation

Use for: Technology evaluation, best practices research, comparing solutions, documentation analysis.

**Triggers:** "research best practices for X", "compare technologies", "investigate external solutions"

---

## Utility Agents

### debug
**Model:** Opus | **Purpose:** Systematic root cause analysis

Use for: Investigating test failures, production bugs, unexpected behavior, performance issues.

**Triggers:** "debug this issue", "why is this failing", "find the bug", "investigate this error"

---

### refactor
**Model:** Sonnet | **Purpose:** Safe code restructuring with test verification

Use for: Improving code structure, extracting functions, renaming symbols, file reorganization.

**Triggers:** "refactor this code", "clean up this module", "extract this logic", "rename across codebase"

---

### test-generator
**Model:** Sonnet | **Purpose:** Adding test coverage to existing code

Use for: Writing tests for existing features, adding coverage to legacy code, TDD for bug fixes.

**Triggers:** "write tests for this feature", "add test coverage", "generate tests"

---

## Review Agents (On-Demand)

Located in `review/` subdirectory. Load as needed for specialized quality checks.

| Agent | Purpose | Triggers |
|-------|---------|----------|
| **security-reviewer** | XSS, injection, auth vulnerabilities | "security review", "audit security", "OWASP check" |
| **accessibility-auditor** | WCAG 2.1 AA compliance | "accessibility review", "a11y audit", "WCAG check" |
| **performance-reviewer** | Rendering, bundle size, queries | "performance review", "check performance", "optimize" |
| **test-coverage-analyzer** | Test adequacy and gaps | "analyze test coverage", "find test gaps" |
| **i18n-validator** | Translation coverage | "i18n review", "translation check", "localization audit" |
| **type-design-analyzer** | TypeScript patterns | "review types", "TypeScript audit", "type design review" |
| **silent-failure-hunter** | Unhandled errors | "find silent failures", "error handling audit" |
| **structure-reviewer** | File organization | "review structure", "file organization audit" |
| **dependency-reviewer** | Dependency health | "review dependencies", "audit packages", "npm audit" |
| **seo-specialist** | SEO and content optimization | "SEO review", "check SEO", "schema markup review" |

---

## Model Selection Guide

| Model | Use When | Cost | Speed |
|-------|----------|------|-------|
| **opus** | Complex multi-step operations, critical reviews, orchestration | High | Slower |
| **sonnet** | General-purpose, implementation, most reviews | Medium | Balanced |
| **haiku** | Fast read-only exploration, simple checks | Low | Fast |

**Guidelines:**
- Use `opus` for orchestration and critical decision-making (code-reviewer, master-orchestrator, debug, deep-researcher)
- Use `sonnet` for implementation and specialized reviews (implementer, spec-reviewer, all review/* agents)
- Reserve `haiku` for quick, read-only explorations

---

## Agent Format

All agents follow this structure:

```markdown
---
name: agent-name
description: |
  [1-2 sentence description with trigger examples]
model: [opus|sonnet|haiku]
tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob"]
---

You are a [role] with expertise in [domain].

## Review/Implementation Scope
[What this agent focuses on]

## Key Checks/Tasks
[Bulleted list of specific checks or tasks]

## Output Format
[How to structure output]
```

---

## When to Use Agents vs Skills

| Use Agent When | Use Skill When |
|----------------|----------------|
| Need separate context window | Need shared context |
| Need tool isolation | Need guidance/knowledge |
| Delegated complex work | Multi-file documentation |
| Need specialized personality | Need standards/best practices |

---

## Directory Structure

```
agents/
├── README.md                    # This file
├── master-orchestrator.md       # Core: task coordination
├── implementer.md               # Core: TDD implementation
├── code-reviewer.md             # Core: comprehensive review
├── spec-reviewer.md             # Core: spec compliance
├── deep-researcher.md           # Core: external research
├── debug.md                     # Utility: debugging
├── refactor.md                  # Utility: code restructuring
├── test-generator.md            # Utility: test creation
└── review/                      # On-demand review specialists
    ├── security-reviewer.md
    ├── accessibility-auditor.md
    ├── performance-reviewer.md
    ├── test-coverage-analyzer.md
    ├── i18n-validator.md
    ├── type-design-analyzer.md
    ├── silent-failure-hunter.md
    ├── structure-reviewer.md
    ├── dependency-reviewer.md
    └── seo-specialist.md
```
