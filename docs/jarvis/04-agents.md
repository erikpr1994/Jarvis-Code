# Agent Taxonomy

> Part of the [Jarvis Specification](./README.md)

## 5. Agent Taxonomy

### 5.1 Agent Categories

Based on analysis of all three systems, agents should be organized into:

| Category | Purpose | Model | Count |
|----------|---------|-------|-------|
| **Orchestration** | Coordination and delegation | Opus | 1 |
| **Implementation** | Writing code | Sonnet | 1 |
| **Review (Quality)** | Code quality, standards | Opus | 1 |
| **Review (Spec)** | Specification alignment | Sonnet | 1 |
| **Review (Domain)** | Specialized concerns | Sonnet | 8-12 |
| **Research** | External information | Opus | 1 |
| **Domain Expert** | Domain-specific knowledge | Sonnet | Variable |

### 5.2 Core Agents (Always Available)

| Agent | Source | Purpose | Model |
|-------|--------|---------|-------|
| **master-orchestrator** | CodeFast | Overall coordination, complex task delegation | Opus |
| **implementer** | Peak-Health | TDD specialist, writes tests first, implements minimal code | Sonnet |
| **code-reviewer** | Peak-Health | Comprehensive pre-PR review, high-confidence filtering | Opus |
| **spec-reviewer** | Peak-Health | Healthy skepticism, verifies code matches spec exactly | Sonnet |
| **deep-researcher** | CodeFast | External research, multiple source validation | Opus |

### 5.3 Domain Review Agents (Load on Demand)

| Agent | Source | Specialty |
|-------|--------|-----------|
| **security-reviewer** | Peak-Health | XSS, injection, auth vulnerabilities |
| **accessibility-auditor** | Peak-Health | WCAG 2.1 AA compliance |
| **performance-reviewer** | Peak-Health | Rendering, bundle size, queries |
| **test-coverage-analyzer** | Peak-Health | Test adequacy and gaps |
| **i18n-validator** | Peak-Health | Translation coverage |
| **type-design-analyzer** | Peak-Health | TypeScript patterns |
| **silent-failure-hunter** | Peak-Health | Unhandled errors |
| **structure-reviewer** | Peak-Health | File organization |
| **dependency-reviewer** | Peak-Health | Dependency health |
| **seo-specialist** | CodeFast | SEO and content strategy |

### 5.4 Specialized Domain Agents (Project-Specific)

| Agent | Source | When to Include |
|-------|--------|-----------------|
| **backend-engineer** | CodeFast | Backend-heavy projects |
| **frontend-specialist** | CodeFast | Complex UI projects |
| **flutter-expert** | CodeFast | Flutter projects |
| **ios-expert** | CodeFast | iOS projects |
| **supabase-specialist** | CodeFast | Supabase projects |
| **debugger-detective** | CodeFast | Complex debugging scenarios |
| **content-writer** | CodeFast | Content-heavy projects |
| **domain-expert** | Peak-Health | Domain-specific knowledge (fitness, etc.) |

### 5.5 Agent Consolidation Analysis (COMPLETE)

#### 5.5.1 Key Differences Between Systems

| Aspect | CodeFast | Peak-Health | Superpowers |
|--------|----------|-------------|-------------|
| **Style** | Verbose (400-500 lines) | Lean (50-100 lines) | Balanced (~50 lines) |
| **Focus** | Implementation/building | Review/validation | Plan alignment |
| **Session** | Mandatory session file | Optional | Optional |
| **Skills** | Embedded triggers | Skill-agnostic | Skill-agnostic |
| **Model** | Opus for key agents | Opus for main reviewer | Inherit |

#### 5.5.2 Consolidation Decisions

**DECISION FRAMEWORK**:
- **KEEP (Peak-Health)**: Lean, focused agents are easier to maintain and use less context
- **MERGE**: Combine best aspects of overlapping agents
- **DROP**: Remove redundant or overly specialized agents
- **ADAPT**: Convert CodeFast implementation agents to use Peak-Health lean style

---

##### CORE AGENTS (5 - Always Available)

| Agent | Source | Decision | Rationale |
|-------|--------|----------|-----------|
| **master-orchestrator** | CodeFast | **KEEP (ADAPT)** | Essential for complex task coordination. Adapt to lean style. |
| **implementer** | Peak-Health | **KEEP** | TDD specialist. Clean, focused design. |
| **code-reviewer** | Peak-Health | **KEEP** | High-quality Opus reviewer with confidence scoring. |
| **spec-reviewer** | Peak-Health | **KEEP** | Healthy skepticism verification. Unique role. |
| **deep-researcher** | CodeFast | **KEEP (ADAPT)** | External research capability. Adapt to lean style. |

---

##### REVIEW AGENTS (10 - Load on Demand)

| Agent | CodeFast | Peak-Health | Decision | Notes |
|-------|----------|-------------|----------|-------|
| **security** | security-auditor | security-reviewer | **KEEP Peak-Health** | Lean, focused, OWASP-oriented |
| **performance** | performance-optimizer | performance-reviewer | **MERGE** | PH for review, CF for optimization |
| **accessibility** | - | accessibility-auditor | **KEEP Peak-Health** | Unique, well-designed |
| **test-coverage** | quality-engineer | test-coverage-analyzer | **KEEP Peak-Health** | PH is more focused |
| **i18n** | - | i18n-validator | **KEEP Peak-Health** | Unique, specialized |
| **type-design** | - | type-design-analyzer | **KEEP Peak-Health** | Unique, TypeScript focus |
| **silent-failure** | - | silent-failure-hunter | **KEEP Peak-Health** | Unique, valuable |
| **structure** | - | structure-reviewer | **KEEP Peak-Health** | File organization |
| **dependency** | - | dependency-reviewer | **KEEP Peak-Health** | Dependency health |
| **seo** | seo-specialist | - | **KEEP CodeFast (ADAPT)** | Unique SEO capability |

---

##### SPECIALIZED DOMAIN AGENTS (Project-Specific)

| Agent | Source | Decision | When to Include |
|-------|--------|----------|-----------------|
| **backend-engineer** | CodeFast | **KEEP (ADAPT)** | Backend-heavy projects |
| **frontend-specialist** | CodeFast | **KEEP (ADAPT)** | Complex UI projects |
| **supabase-specialist** | CodeFast | **KEEP (ADAPT)** | Supabase projects |
| **flutter-expert** | CodeFast | **KEEP (ADAPT)** | Flutter projects |
| **ios-expert** | CodeFast | **KEEP (ADAPT)** | iOS projects |
| **content-writer** | CodeFast | **KEEP (ADAPT)** | Content-heavy projects |
| **debugger-detective** | CodeFast | **MERGE with systematic-debugging** | Complex debugging |

---

##### AGENTS TO DROP

| Agent | Source | Reason |
|-------|--------|--------|
| **session-librarian** | CodeFast | Replaced by Memory MCP + session files |
| **quality-engineer** | CodeFast | Overlaps with test-coverage-analyzer |
| **quick-code-reviewer** | Peak-Health | Redundant with code-reviewer model selection |
| **comment-analyzer** | Peak-Health | Too specialized, can be a rule instead |
| **code-simplifier** | Peak-Health | Can be part of code-reviewer |
| **claude-native-reviewer** | Peak-Health | Too specialized |
| **code-explorer** | Peak-Health | Replaced by Explore subagent |
| **code-architect** | Peak-Health | Can be part of master-orchestrator |
| **plan-alignment-reviewer** | Peak-Health | Merge into spec-reviewer |

---

#### 5.5.3 Final Agent Count

| Category | Count | Agents |
|----------|-------|--------|
| **Core (Always)** | 5 | master-orchestrator, implementer, code-reviewer, spec-reviewer, deep-researcher |
| **Review (On-Demand)** | 10 | security, performance, accessibility, test-coverage, i18n, type-design, silent-failure, structure, dependency, seo |
| **Domain (Project)** | 7 | backend, frontend, supabase, flutter, ios, content, debugger |
| **TOTAL** | 22 | Down from 35 (37% reduction) |

---

#### 5.5.4 Claude Code Official Recommendations

Per Claude Code documentation, agents should:

1. **Single responsibility** - One clear purpose per agent
2. **Detailed descriptions** - Include trigger terms users would naturally say
3. **Restrict tools appropriately** - Only grant what's needed
4. **Model selection**:
   - `sonnet` (default) - General-purpose, complex reasoning
   - `haiku` - Fast read-only exploration
   - `opus` - Complex multi-step operations
   - `inherit` - Match user's model choice

**Agent vs Skill Decision:**

| Use Agent When | Use Skill When |
|----------------|----------------|
| Need separate context window | Need shared context |
| Need tool isolation | Need guidance/knowledge |
| Need specialized personality | Need standards/best practices |
| Delegated complex work | Multi-file documentation |

#### 5.5.5 Agent Adaptation Guidelines

When adapting CodeFast agents to Jarvis lean style:

1. **Remove embedded skill triggers** - Skills are loaded by hooks, not agents
2. **Remove session file boilerplate** - Session management is a skill
3. **Remove pattern references** - Patterns are loaded by hooks
4. **Keep core expertise** - Preserve the valuable domain knowledge
5. **Add confidence scoring** - Use Peak-Health's confidence model
6. **Target 50-100 lines** - Lean and focused

**Template for adapted agents:**

```markdown
---
name: agent-name
description: [1-2 sentence description with trigger examples]
model: [opus|sonnet|haiku]
tools: [optional - restrict if needed]
skills: [optional - preload relevant skills]
---

You are a [role] with expertise in [domain].

## Review/Implementation Scope
[What this agent focuses on]

## Key Checks/Tasks
[Bulleted list of specific checks or tasks]

## Output Format
[How to structure output]

## Project-Specific Context
[Any project-specific notes]
```

#### 5.5.6 Skill Structure with Supporting Documents

Skills can have supporting documents for complex topics (Superpowers pattern):

```
skills/
├── systematic-debugging/
│   ├── SKILL.md                    # Main skill file
│   ├── condition-based-waiting.md  # Supporting: async patterns
│   ├── test-pressure-1.md          # Supporting: pressure scenario 1
│   ├── test-pressure-2.md          # Supporting: pressure scenario 2
│   ├── defense-in-depth.md         # Supporting: multi-layer testing
│   └── find-polluter.sh            # Supporting: helper script
```

This allows:
- **Main skill** stays concise and focused
- **Supporting docs** provide depth when needed
- **Scripts** can be included for automation
- **Examples** can be extensive without bloating main skill
