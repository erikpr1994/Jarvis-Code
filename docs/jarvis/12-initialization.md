# Initialization Flow

> Part of the [Jarvis Specification](./README.md)

## 14. Initialization Flow

### 14.1 New Project Initialization

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      jarvis init (or first session)                      │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         AUTO-DETECT PHASE                                │
│  • Scan project structure                                               │
│  • Detect package.json, tsconfig, etc.                                  │
│  • Identify tech stack (Next.js, Supabase, etc.)                        │
│  • Check for existing .claude/ folder                                   │
│  • Detect monorepo structure                                            │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        INTERVIEW PHASE                                   │
│  • Confirm detected stack                                               │
│  • Ask about project type (SaaS, client, OSS)                          │
│  • Ask about testing preferences                                        │
│  • Ask about git workflow                                               │
│  • Ask about documentation structure                                    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       TEMPLATE PHASE                                     │
│  • Select base template (web, mobile, backend, etc.)                    │
│  • Merge with detected stack requirements                               │
│  • Apply interview preferences                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       GENERATION PHASE                                   │
│  • Create .claude/ folder structure                                     │
│  • Generate CLAUDE.md with project-specific rules                       │
│  • Link global skills (symlink or copy)                                │
│  • Create project-specific skills if needed                            │
│  • Set up hooks                                                         │
│  • Create docs/ structure                                               │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      VALIDATION PHASE                                    │
│  • Verify all components installed                                      │
│  • Run test hook execution                                              │
│  • Confirm global + local merge works                                   │
│  • Create initial session file                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 14.2 Auto-Detection Logic

#### 14.2.1 File-Based Detection

| Tech Stack | Detection Files | Detection Patterns |
|------------|-----------------|-------------------|
| **Next.js** | `next.config.*`, `app/layout.tsx` | `"next"` in package.json |
| **React** | `src/App.tsx`, `vite.config.*` | `"react"` in dependencies |
| **Flutter** | `pubspec.yaml`, `lib/main.dart` | `flutter:` in pubspec |
| **iOS/Swift** | `*.xcodeproj`, `Package.swift` | `.swift` files in project |
| **Supabase** | `supabase/config.toml` | `"@supabase/supabase-js"` in deps |
| **Prisma** | `prisma/schema.prisma` | `"prisma"` in devDeps |
| **Drizzle** | `drizzle.config.*` | `"drizzle-orm"` in deps |
| **Tailwind** | `tailwind.config.*` | `"tailwindcss"` in devDeps |
| **TypeScript** | `tsconfig.json` | `"typescript"` in devDeps |
| **Vitest** | `vitest.config.*` | `"vitest"` in devDeps |
| **Playwright** | `playwright.config.*` | `"@playwright/test"` in devDeps |

#### 14.2.2 Structure Detection

```javascript
// Detection heuristics
const detectProjectType = (files) => {
  // Monorepo detection
  if (files.includes('turbo.json') || files.includes('pnpm-workspace.yaml')) {
    return 'monorepo';
  }

  // App detection by framework
  if (files.some(f => f.match(/next\.config\.(js|ts|mjs)/))) {
    return 'next-app';
  }

  // Package detection
  if (files.includes('packages/') && !files.includes('apps/')) {
    return 'library';
  }

  return 'standalone';
};
```

### 14.3 Interview Questions

#### 14.3.1 Project Type (If Not Auto-Detected)

```markdown
## Q1: Project Type
What type of project is this?

Options:
- [ ] SaaS Product (user accounts, billing, dashboard)
- [ ] Client Project (defined requirements, external stakeholder)
- [ ] Open Source (community, contributions)
- [ ] Internal Tool (company use)
- [ ] Other: _______________

→ Affects: Agent selection, workflow strictness, documentation level
```

#### 14.3.2 Development Workflow

```markdown
## Q2: Git Workflow
How do you manage git branches?

Options:
- [ ] GitHub Flow (feature branches) ← Default
- [ ] GitFlow (develop/release/hotfix)
- [ ] Trunk-based (main only)

→ Affects: git-expert skill, branch naming rules, PR workflow
```

```markdown
## Q3: Code Review Integration
What code review tools do you use?

Options:
- [ ] CodeRabbit (automated AI review)
- [ ] GitHub Reviews only
- [ ] Both CodeRabbit + GitHub
- [ ] None (solo project)

→ Affects: coderabbit skill, review agent configuration
```

#### 14.3.3 Testing Preferences

```markdown
## Q4: Testing Strategy
How strict should TDD enforcement be?

Options:
- [ ] Iron Law (no exceptions - write tests first ALWAYS)
- [ ] Strong (tests required, but can write code first for exploration)
- [ ] Flexible (tests encouraged but not required)

→ Affects: test-driven-development skill strictness, verification gates
```

```markdown
## Q5: Test Types
Which test types should be enforced?

Options (multi-select):
- [ ] Unit tests (isolated functions)
- [ ] Integration tests (API, database)
- [ ] E2E tests (Playwright/Cypress)
- [ ] Visual regression tests
- [ ] Performance tests

→ Affects: verification pipeline, agent checks
```

#### 14.3.4 Documentation Preferences

```markdown
## Q6: Documentation Structure
How should project documentation be organized?

Options:
- [ ] Full Lifecycle (specs/ → plans/ → design/ → decisions/)
- [ ] Simple (just README and docs/)
- [ ] Minimal (README only)

→ Affects: docs/ folder generation, spec/plan skills
```

### 14.4 Templates

| Template | Stack | Agents | Skills |
|----------|-------|--------|--------|
| **web-fullstack** | Next.js, Supabase, Tailwind | Full web stack | All web skills |
| **mobile-flutter** | Flutter, Firebase | Mobile specialists | Mobile skills |
| **mobile-ios** | Swift, iOS | iOS specialists | iOS skills |
| **backend-api** | Node/Python, PostgreSQL | Backend specialists | Backend skills |
| **minimal** | Any | Core only | Core skills only |

#### 14.4.1 Template: web-fullstack

```yaml
# Template configuration
name: web-fullstack
description: Full-stack web application with Next.js, Supabase, Tailwind

detection:
  requires_all:
    - next.config.*
    - supabase/config.toml
  requires_any:
    - tailwind.config.*
    - app/layout.tsx

agents:
  core:
    - master-orchestrator
    - implementer
    - code-reviewer
    - spec-reviewer
    - deep-researcher
  domain:
    - frontend-specialist
    - backend-engineer
    - supabase-specialist
  review:
    - security-reviewer
    - accessibility-auditor
    - performance-reviewer
    - seo-specialist

skills:
  always:
    - test-driven-development
    - verification-before-completion
    - debug
    - git-expert
  domain:
    - frontend-design
    - payment-processing  # If Polar/Stripe detected
    - analytics           # If Umami detected
    - seo-content-generation

hooks:
  - session-start
  - skill-activation-prompt
  - require-isolation
  - block-direct-submit
  - coderabbit-review    # If CodeRabbit detected

rules:
  - typescript-strict
  - react-patterns
  - supabase-patterns
  - tailwind-conventions

claude_md:
  generate:
    - root: full-stack-template
    - apps/web: next-app-template
    - packages/ui: component-library-template
    - packages/database: supabase-template
    - supabase/migrations: migrations-template
    - docs: documentation-template
```

#### 14.4.2 Template: mobile-flutter

```yaml
name: mobile-flutter
description: Cross-platform mobile app with Flutter

detection:
  requires_all:
    - pubspec.yaml
    - lib/main.dart

agents:
  core:
    - master-orchestrator
    - implementer
    - code-reviewer
    - spec-reviewer
  domain:
    - flutter-expert

skills:
  always:
    - test-driven-development
    - verification-before-completion
    - git-expert
  domain:
    - domain-expert  # Flutter patterns

hooks:
  - session-start
  - skill-activation-prompt
  - require-isolation

rules:
  - dart-conventions
  - flutter-patterns
  - widget-testing
```

#### 14.4.3 Template: minimal

```yaml
name: minimal
description: Minimal setup for any project type

detection:
  default: true  # Fallback if no other template matches

agents:
  core:
    - implementer
    - code-reviewer

skills:
  always:
    - test-driven-development
    - verification-before-completion
    - git-expert

hooks:
  - session-start
  - skill-activation-prompt

rules: []  # No default rules
```

### 14.5 Generated Files Reference

#### 14.5.1 .claude/ Structure Created

```
.claude/
├── settings.json              # Project settings (merged with global)
├── agents/                    # Project-specific agents (if any)
├── skills/                    # Project-specific skills (if any)
├── commands/                  # Project commands
│   └── init.md                # Re-run initialization
├── hooks/                     # Project hooks (symlinks to global + local)
├── rules/                     # Project-specific rules
│   └── project-patterns.md    # Auto-detected patterns
└── tasks/
    └── session-current.md     # Initial session file
```

#### 14.5.2 settings.json Structure

```json
{
  "project": {
    "name": "my-project",
    "type": "saas",
    "template": "web-fullstack",
    "initialized": "2026-01-04T10:00:00Z"
  },
  "stack": {
    "detected": ["next.js", "supabase", "tailwind", "typescript"],
    "confirmed": true
  },
  "workflow": {
    "git": "github-flow",
    "review": "coderabbit",
    "tdd": "iron-law"
  },
  "agents": {
    "core": ["master-orchestrator", "implementer", "code-reviewer"],
    "domain": ["frontend-specialist", "supabase-specialist"],
    "review": ["security-reviewer", "accessibility-auditor"]
  },
  "skills": {
    "always": ["test-driven-development", "git-expert"],
    "domain": ["frontend-design", "payment-processing"]
  },
  "hooks": {
    "active": ["session-start", "require-isolation", "coderabbit-review"],
    "disabled": []
  }
}
```

#### 14.5.3 Root CLAUDE.md Generation

Uses Section 4 templates. Generated content includes:

```markdown
# [Project Name]

## Tech Stack
[Auto-detected and confirmed during interview]

## Commands
[Standard Jarvis commands + project-specific]

## Patterns
[Initial patterns based on template]

## Testing
[Based on interview answers]

## Git Workflow
[Based on interview answers]

---
*Generated by Jarvis on [date]. Edit as needed.*
```

### 14.6 Global Installation

```bash
# Install global Jarvis system
jarvis install

# Creates:
# ~/.claude/
#   ├── settings.json
#   ├── agents/
#   ├── skills/
#   ├── commands/
#   ├── hooks/
#   ├── patterns/
#   └── rules/
```

### 14.7 Init Command Variants

```bash
# Interactive initialization (full interview)
jarvis init

# Quick init with template (skip interview)
jarvis init --template web-fullstack

# Re-initialize (preserve customizations)
jarvis init --refresh

# Generate missing CLAUDE.md files only
jarvis init --claude-md-only

# Validate existing setup
jarvis doctor
```
