# System Architecture

> Part of the [Jarvis Specification](./README.md)

## 3. System Architecture

### 3.1 Directory Structure

```
~/.claude/                              # GLOBAL (shared across all projects)
├── settings.json                       # Global settings
├── agents/                             # Shared agents
│   └── core/                           # Core agents (always available)
├── skills/                             # Shared skills
│   ├── meta/                           # Meta-skills (using-skills, writing-*)
│   ├── process/                        # Process skills (TDD, verification, debugging)
│   └── domain/                         # Domain skills (git, patterns)
├── commands/                           # Shared commands
├── hooks/                              # Shared hooks
│   └── lib/                            # Hook utilities
├── patterns/                           # Pattern library (indexed)
│   ├── index.json                      # Pattern index with summaries
│   └── full/                           # Full pattern files
├── rules/                              # Global rules
└── lib/                                # Shared utilities
    └── skills-core.js                  # Skill discovery library

<project>/.claude/                      # LOCAL (project-specific overrides)
├── CLAUDE.md                           # Project-specific instructions
├── settings.json                       # Project settings (merged with global)
├── agents/                             # Project-specific agents
├── skills/                             # Project-specific skills
├── commands/                           # Project-specific commands
├── hooks/                              # Project-specific hooks
├── rules/                              # Project-specific rules
└── tasks/                              # Session tracking
    ├── session-current.md              # Current session state
    └── session-history/                # Archived sessions

<project>/docs/                         # Documentation structure
├── specs/                              # Feature specifications
├── plans/                              # Implementation plans
├── design/                             # Design documents
├── inbox/                              # Quick capture (ideas, bugs, notes)
└── business/                           # Vision, strategy, decisions
```

### 3.2 Configuration Layering

```
Priority (highest to lowest):
1. Project .claude/settings.json
2. Global ~/.claude/settings.json
3. Built-in defaults

Merge Strategy:
- Arrays: concatenate (project + global)
- Objects: deep merge (project overrides global)
- Primitives: project wins
```

### 3.3 Component Interaction

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           USER PROMPT                                    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         SESSION START HOOK                               │
│  • Load using-skills content                                            │
│  • Detect session continuation vs fresh start                           │
│  • Load relevant context (smart detect)                                 │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      SKILL ACTIVATION HOOK                               │
│  • Analyze prompt for skill triggers (keywords + intent)                │
│  • Check skill-rules.json for matches                                   │
│  • Recommend skills by priority (critical → high → medium → low)        │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         ROUTING DECISION                                 │
│  Simple Task ──────────────────────────────────► Direct Agent           │
│  Complex Task ─────────────────────────────────► Master Orchestrator    │
│  Multi-phase ──────────────────────────────────► Session Management     │
└─────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           EXECUTION                                      │
│  • Load relevant skills                                                 │
│  • Apply TDD discipline (Iron Law)                                      │
│  • Execute with verification checkpoints                                │
│  • Track progress in session file                                       │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      PRE-TOOL USE HOOKS                                  │
│  • require-isolation.sh (worktree/Conductor enforcement)                │
│  • block-direct-submit.sh (must use submit-pr skill)                    │
│  • coderabbit-review.sh (automated review integration)                  │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        VERIFICATION                                      │
│  • Tests pass                                                           │
│  • Code review (5+ parallel agents)                                     │
│  • Build check                                                          │
│  • Explicit user confirmation                                           │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      LEARNING CAPTURE                                    │
│  • Detect new patterns                                                  │
│  • Update skill-rules.json                                              │
│  • Create/update skills automatically                                   │
│  • Archive session learnings                                            │
└─────────────────────────────────────────────────────────────────────────┘
```
