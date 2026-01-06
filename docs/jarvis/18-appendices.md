# Appendices

> Part of the [Jarvis Specification](./README.md)

## 21. Open Questions

### 21.1 Technical Decisions Needed

| Question | Options | Recommendation |
|----------|---------|----------------|
| **Skill loading**: How to handle large skills? | Lazy load / Summarize / Chunk | Summarize + lazy load full on use |
| **Memory MCP bloat**: How to prevent? | Tiered / Prune / Limit | Tiered system (hot/warm/cold) |
| **Agent conflicts**: Multiple agents disagree? | Vote / Priority / Ask user | Priority + ask if critical |
| **Pattern freshness**: How to keep patterns current? | Manual / Auto-detect / Version | Auto-detect staleness + prompt |

### 21.2 Consolidation Analysis (COMPLETE)

**Status**: Completed in Sections 5.5 and 6.7

| Component | Before | After | Reduction |
|-----------|--------|-------|-----------|
| **Agents** | 35 | 23 | 34% |
| **Skills** | 49 | 32 | 35% |
| **Hooks** | 8 (overlapping) | 8 (unified) | Deduplicated |

Key decisions documented in:
- Section 5.5: Agent Consolidation Analysis (with KEEP/MERGE/DROP decisions)
- Section 6.7: Skill Consolidation Analysis (with source attributions)
- Section 8.7: Hook System Consolidation (with bypass mechanisms)

### 21.3 Future Considerations

- Multi-user team support
- CI/CD integration for skill testing
- Plugin/extension system
- Claude model version compatibility

---

## 22. Appendices

### A. Interview Summary

| Topic | Decision |
|-------|----------|
| **Audience** | Personal (distributable later) |
| **Tech Stack** | All (full-stack, mobile, backend, DevOps) |
| **Project Types** | Mixed (SaaS, client, OSS) |
| **Skill Triggering** | Hybrid (auto for domain, explicit for process) |
| **TDD Discipline** | Iron Law (no exceptions) |
| **Learning** | Fully automatic (with rollback) |
| **Agent Usage** | Task-dependent (single → orchestrated) |
| **Verification** | Full (tests + review + build + confirm) |
| **Patterns** | Index only (load full on demand) |
| **Session Persistence** | Full lifecycle (spec → plan → track → archive) |
| **Git Workflow** | Graphite + worktrees + CodeRabbit |
| **Memory Management** | Tiered: hot (session), warm (7d), cold (30d+) with auto-archival |
| **Code Review** | All dimensions (arch, security, perf, a11y, SEO) |
| **Init Flow** | Hybrid (auto-detect + interview + templates) |
| **Multi-project** | Shared core + local overrides |
| **Error Handling** | Smart fallback (escalate if critical) |
| **Task Granularity** | Adaptive (based on complexity/risk) |
| **Docs Integration** | Full lifecycle |
| **Notifications** | Progress milestones |
| **Conflict Resolution** | Most specific wins |
| **Metrics** | Yes, detailed tracking |
| **Timeline** | Iterative releases |
| **Session Start** | Smart detect (continue vs fresh) |

### B. Source System Inventory

| System | Agents | Skills | Commands | Hooks | Patterns |
|--------|--------|--------|----------|-------|----------|
| **CodeFast** | 15 | 16+ | 0 | 1 | 26 |
| **Superpowers** | 1 | 14 | 3 | 1 | 0 |
| **Peak-Health** | 19 | 35+ | 18 | 6 | 0 (via rules) |
| **Jarvis (target)** | ~20 | ~40 | ~15 | ~6 | ~30 |

### C. File References

| File | Location | Purpose |
|------|----------|---------|
| CodeFast agents | `codefast/.claude/agents/` | Domain specialists |
| CodeFast skills | `codefast/.claude/skills/` | Domain skills |
| CodeFast patterns | `codefast/.claude/context/Rules+Examples/` | Pattern library |
| Superpowers skills | `superpowers/skills/` | Process skills |
| Superpowers tests | `superpowers/tests/` | Skill validation |
| Peak-Health agents | Referenced in exploration | Production agents |
| Peak-Health skills | Referenced in exploration | Production skills |

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0-draft | 2026-01-04 | Initial spec from interview |
| 1.0.0 | 2026-01-04 | Completed all sections: agent consolidation (34% reduction), skill consolidation (35% reduction), hook system unification, context optimization, testing strategy, error recovery, hierarchical CLAUDE.md system |

---

*This document represents the complete specification for Jarvis. Ready for Phase 1 implementation.*
