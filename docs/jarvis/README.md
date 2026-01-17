# Jarvis Specification

> **Version**: 1.0.0
> **Status**: Complete, Ready for Implementation

**Jarvis** is an advanced AI assistant system for Claude Code that merges the best of three mature systems:

1. **CodeFast** - Domain expertise + automation = speed
2. **Superpowers** - Discipline + verification = reliability
3. **Peak-Health** - Production-grade implementation

## Quick Stats

| Metric | Value |
|--------|-------|
| **Agents** | 23 (34% reduction from 35) |
| **Skills** | 32 (35% reduction from 49) |
| **Hooks** | 8 (unified) |
| **Sections** | 22 |

---

## Specification Files

### Foundation
| File | Sections | Description |
|------|----------|-------------|
| [01-vision-and-goals.md](./01-vision-and-goals.md) | 1-2 | Vision, goals, user profile, requirements |
| [02-architecture.md](./02-architecture.md) | 3 | Directory structure, layering, component flow |
| [03-claude-md-system.md](./03-claude-md-system.md) | 4 | Hierarchical CLAUDE.md system |

### Components
| File | Sections | Description |
|------|----------|-------------|
| [04-agents.md](./04-agents.md) | 5 | Agent taxonomy, consolidation analysis |
| [05-skills.md](./05-skills.md) | 6 | Skill taxonomy, consolidation analysis |
| [06-commands.md](./06-commands.md) | 7 | Command system design |
| [07-hooks.md](./07-hooks.md) | 8 | Hook system, consolidation, implementation |

### Configuration
| File | Sections | Description |
|------|----------|-------------|
| [08-rules-and-patterns.md](./08-rules-and-patterns.md) | 9-10 | Rules, standards, pattern library |
| [09-session.md](./09-session.md) | 11 | Session state, context persistence |
| [10-context-optimization.md](./10-context-optimization.md) | 12 | Tool output compression, wrappers |
| [11-learning-system.md](./11-learning-system.md) | 13 | Auto-learning, self-improvement |

### Operations
| File | Sections | Description |
|------|----------|-------------|
| [12-initialization.md](./12-initialization.md) | 14 | Init flow, detection, templates |
| [13-verification.md](./13-verification.md) | 15 | Quality gates, review pipeline |
| [14-metrics.md](./14-metrics.md) | 16 | Tracking, analytics |
| [15-testing.md](./15-testing.md) | 17 | Testing Jarvis components |
| [16-error-recovery.md](./16-error-recovery.md) | 18 | Graceful degradation, self-healing |
| [17-distribution.md](./17-distribution.md) | 19-20 | Distribution, roadmap |
| [18-appendices.md](./18-appendices.md) | 21-22 | Open questions, references |

---

## Implementation Phases

### Phase 1: Foundation (MVP)
- Global ~/.claude/ structure
- Core skills (TDD, verification, git-expert)
- Session-start and skill-activation hooks
- CLAUDE.md template generator

### Phase 2: Core Features
- All core agents
- Process skills
- Require-isolation hook
- Pattern library

### Phase 3: Advanced Features
- Learning capture
- Auto-update system
- Metrics tracking
- Memory management

### Phase 4: Distribution
- Init wizard
- Templates
- Documentation
- Packaging

---

## Key Design Decisions

| Decision | Choice |
|----------|--------|
| TDD Discipline | Iron Law (no exceptions) |
| Git Workflow | Graphite + worktrees |
| Code Review | CodeRabbit + multi-agent |
| Memory | Tiered (hot/warm/cold) |
| Skill Loading | Summarize + lazy load |
| Error Handling | Smart fallback + escalate |

---

*Split from single 3,175-line SPEC.md for better readability and context efficiency.*
