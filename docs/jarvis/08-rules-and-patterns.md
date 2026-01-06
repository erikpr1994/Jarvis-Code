# Rules & Standards + Pattern Library

> Part of the [Jarvis Specification](./README.md)

## 9. Rules & Standards

### 9.1 Rule Categories

| Category | Purpose | Confidence Threshold |
|----------|---------|----------------------|
| **Critical** | Bugs, security, data loss | 90% |
| **Quality** | Code standards, patterns | 80% |
| **Style** | Formatting, naming | 70% |
| **Suggestion** | Improvements, optimizations | 60% |

### 9.2 Core Rules (Global)

| Rule | Category | Enforcement |
|------|----------|-------------|
| **No `any` types** | Critical | Block |
| **No `@ts-ignore`** | Critical | Block |
| **TDD required** | Critical | Block |
| **Tests must pass** | Critical | Block |
| **Workspace isolation** | Critical | Block |
| **i18n for user text** | Quality | Warn |
| **<300 line PRs** | Quality | Warn |
| **Conventional commits** | Quality | Warn |

### 9.3 Project Rules (Overridable)

| Rule | Default | Override |
|------|---------|----------|
| **Framework patterns** | Next.js 15 + React 19 | Project-specific |
| **Database patterns** | Supabase | Project-specific |
| **Auth patterns** | Clerk | Project-specific |
| **Styling patterns** | Tailwind v4 | Project-specific |

### 9.4 Rule File Format

```markdown
---
name: rule-name
category: critical|quality|style|suggestion
confidence: 80
---

# Rule Name

## Description
What this rule enforces and why.

## Examples

### Good
```typescript
// Correct example
```

### Bad
```typescript
// Incorrect example
```

## Rationale
Why this rule matters.
```

---

## 10. Pattern Library

### 10.1 Pattern Organization

```
patterns/
├── index.json                    # Index with summaries (always loaded)
├── core/                         # Always-relevant patterns
│   ├── typescript-patterns.md
│   └── project-organization.md
├── framework/                    # Framework-specific
│   ├── nextjs-react-patterns.md
│   ├── supabase-database-patterns.md
│   └── tailwind-styling.md
├── feature/                      # Feature patterns
│   ├── api-auth-patterns.md
│   ├── forms-state-patterns.md
│   └── payment-processing.md
└── integration/                  # Integration patterns
    ├── docker-deployment.md
    └── ci-cd-patterns.md
```

### 10.2 Index Format

```json
{
  "patterns": {
    "typescript-patterns": {
      "path": "core/typescript-patterns.md",
      "summary": "TypeScript best practices: strict typing, discriminated unions, type guards",
      "keywords": ["typescript", "types", "interface", "generic"],
      "size": "15KB",
      "lastUpdated": "2026-01-04"
    }
  }
}
```

### 10.3 Loading Strategy

1. **Always**: Load index.json (summaries only)
2. **On-demand**: Fetch full pattern when:
   - Skill triggers that pattern
   - User explicitly requests
   - Keyword match in prompt
3. **Cache**: Keep recently-used patterns in context
