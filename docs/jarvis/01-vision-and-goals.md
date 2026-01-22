# Vision & Goals

> Part of the [Jarvis Specification](./README.md)

## 1. Vision & Goals

### 1.1 Vision Statement

Jarvis is an AI development system that provides **disciplined speed through expert processes**. It combines domain expertise (knowing HOW to build) with process discipline (knowing WHEN to verify) to produce high-quality software faster.

### 1.2 Core Goals

| Goal | Description | Success Metric |
|------|-------------|----------------|
| **Perfect Memory** | Never lose context across sessions | Zero "remind me what we were doing" requests |
| **Self-Improving** | Gets better over time automatically | New patterns captured without manual intervention |
| **Seamless Handoffs** | Continue perfectly from previous session | <30 seconds to productive state on session resume |
| **Consistent Quality** | Same high standards every time | <5% variation in code review scores |
| **Reduced Guidance** | Minimal manual reminders needed | <1 pattern reminder per session |
| **Fast Iteration** | Idea to working code quickly | Measurable time reduction per feature type |

### 1.3 Target Audience

**Primary**: Personal use by the creator
**Future**: Distributable (paid or open source) if system proves effective

### 1.4 Design Principles

1. **Skills-First Workflow**: Always check for applicable skills before responding
2. **Iron Law TDD**: No code without failing tests first (no exceptions)
3. **Full Verification**: Tests + code review + build + explicit confirmation
4. **Most Specific Wins**: Project > domain > global for conflict resolution
5. **Automatic Learning**: System improves without manual training
6. **Smart Context**: Load index/summaries, fetch full content on demand
7. **Adaptive Granularity**: Task size depends on complexity and risk

---

## 2. User Profile & Requirements

### 2.1 Tech Stack Coverage

| Domain | Technologies | Priority |
|--------|--------------|----------|
| **Full-stack Web** | Next.js 15, React 19, TypeScript, Tailwind v4 | Critical |
| **Backend** | Supabase, PostgreSQL, Server Actions | Critical |
| **Mobile** | Flutter, iOS/Swift | High |
| **DevOps** | Docker, Vercel, AWS, Coolify | High |
| **Authentication** | Clerk, Supabase Auth | High |
| **Payments** | Polar.sh, Dodo Payments | Medium |
| **Analytics** | Umami | Medium |
| **Feature Flags** | Hypertune | Medium |
| **i18n** | next-intl, Crowdin | Medium |

### 2.2 Project Types

- SaaS products (full idea-to-product workflow)
- Client projects (defined requirements)
- Open source (community workflows)
- Mixed/varied

### 2.3 Workflow Preferences

| Aspect | Preference | Details |
|--------|------------|---------|
| **Git Workflow** | GitHub CLI + Worktrees | Feature branches, worktree isolation, submit-pr skill |
| **Code Review** | CodeRabbit + Multi-agent | 5+ specialized review agents running in parallel |
| **Testing** | TDD (Iron Law) | Red-Green-Refactor, no exceptions |
| **Task Granularity** | Adaptive | Micro for risky, larger for straightforward |
| **Error Handling** | Smart fallback | Auto-recovery based on error type, escalate if critical |
| **Notifications** | Progress milestones | Not too verbose, not too silent |

### 2.4 Pain Points to Solve

1. **Context Loss** - Losing context when sessions end or compact
2. **Inconsistent Quality** - Sometimes great, sometimes misses important things
3. **Too Much Manual Guidance** - Having to remind Claude of patterns/preferences
4. **Slow Iteration** - Takes too long to get from idea to working code

### 2.5 Magic Features Desired

1. **Perfect Memory** - Remembers everything across sessions
2. **Self-Improving** - Gets better over time without manual training
3. **Seamless Handoffs** - Continues perfectly from previous session state
