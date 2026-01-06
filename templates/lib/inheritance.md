# Template Inheritance System

> Documentation for the CLAUDE.md template inheritance and merge system in Jarvis.
> Last updated: 2025

This document describes how templates inherit, merge, and override each other to create the final CLAUDE.md file.

## Inheritance Hierarchy

The Jarvis template system uses a multi-level inheritance hierarchy:

```
┌─────────────────────────────────────────────────────────┐
│  Level 1: Global (global-claude.md)                     │
│  Token Budget: 2000 tokens                              │
│  Scope: All projects                                    │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│  Level 2: Base Template (CLAUDE.md.template)            │
│  Token Budget: 1500 tokens (cumulative)                 │
│  Scope: Shared patterns across project types            │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│  Level 3: Project Type (typescript.md, python.md, etc.) │
│  Token Budget: 800 tokens                               │
│  Scope: Language/framework-specific patterns            │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│  Level 4: Folder Type (components/, api/, etc.)         │
│  Token Budget: 500 tokens                               │
│  Scope: Directory-specific patterns                     │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│  Level 5: Local Override (.claude/CLAUDE.local.md)      │
│  Token Budget: 300 tokens                               │
│  Scope: User-specific, not committed                    │
└─────────────────────────────────────────────────────────┘
```

## Token Budget Management

### Budget Allocation

Each level has a target token budget to ensure the final CLAUDE.md remains efficient:

| Level | Budget | Cumulative Max | Purpose |
|-------|--------|----------------|---------|
| Global | 2000 | 2000 | Core rules, identity, safety |
| Base | 1500 | 3500 | Shared conventions, workflow |
| Project Type | 800 | 4300 | Language/framework specifics |
| Folder Type | 500 | 4800 | Directory patterns |
| Local | 300 | 5100 | Personal preferences |

### Budget Enforcement

Templates should stay within their token budget. When a template exceeds its budget:

1. **Warning**: Generation logs a warning about budget overflow
2. **Truncation**: Content may be truncated in priority order
3. **Optimization**: Consider breaking into sub-templates

### Measuring Tokens

Token count is estimated using the formula:

```
tokens ≈ words × 1.3 + code_tokens
```

Where `code_tokens` are calculated based on actual code block lengths.

## Merge Strategies

### Default: Additive Merge

By default, templates merge additively - child templates add to parent content:

```yaml
# Parent (typescript.md)
patterns:
  - Use named exports
  - Prefer interfaces for objects

# Child (nextjs.md)
patterns:
  - Use Server Components by default
  - Add 'use client' only when needed

# Result (merged)
patterns:
  - Use named exports
  - Prefer interfaces for objects
  - Use Server Components by default
  - Add 'use client' only when needed
```

### Section Override

To completely replace a parent section, use the `# @override` directive:

```markdown
## Key Patterns
# @override

- These patterns replace parent patterns entirely
- Parent patterns are NOT inherited
```

### Section Extend

To explicitly extend (default behavior, useful for clarity):

```markdown
## Key Patterns
# @extend

- These patterns are added to parent patterns
```

### Section Prepend

To add content before parent content:

```markdown
## Key Patterns
# @prepend

- These patterns appear BEFORE parent patterns
```

## Conflict Resolution

### Last-Write-Wins (Default)

When the same key/section appears at multiple levels, the most specific (deepest) level wins:

```yaml
# Level 2: Base
test_cmd: "npm test"

# Level 3: Project Type (typescript)
test_cmd: "pnpm test"

# Level 4: Folder Type (components)
test_cmd: "pnpm test --filter=components"

# Result
test_cmd: "pnpm test --filter=components"
```

### Explicit Merge

For sections that should merge instead of override:

```markdown
## DO NOT
# @merge

- Child-specific DON'Ts
```

This combines with parent DON'Ts rather than replacing them.

### Priority Tags

Use priority tags to control merge order:

```markdown
## Rules
# @priority: high

High-priority rules that override lower-priority ones.
```

Priority levels: `critical` > `high` > `normal` > `low`

## Inheritance Declaration

Each template declares its inheritance chain:

```markdown
> Inherits from: global-claude.md + CLAUDE.md.template + typescript.md
> Override: {{OVERRIDE_PARENT}}
> Token budget: ~800 tokens
```

### Inheritance Syntax

```markdown
# Single parent
> Inherits from: typescript.md

# Multiple parents (merged in order)
> Inherits from: global-claude.md + CLAUDE.md.template + typescript.md

# Skip a level
> Inherits from: global-claude.md + typescript.md
> Skip: CLAUDE.md.template
```

### Override Flag

The `{{OVERRIDE_PARENT}}` variable controls whether this template:

- `false` (default): Merges with parent content
- `true`: Completely replaces parent content

## Folder-Level Inheritance

### Automatic Detection

Jarvis automatically applies folder-type templates based on directory names:

```
src/
├── components/  → applies folder-types/components.md
├── hooks/       → applies folder-types/hooks.md
├── lib/         → applies folder-types/lib.md
├── api/         → applies folder-types/api.md
└── tests/       → applies folder-types/tests.md
```

### Custom Folder Templates

Create custom folder templates in `.claude/folders/`:

```
.claude/
└── folders/
    ├── feature-flags.md   # Custom template for feature-flags/
    └── analytics.md       # Custom template for analytics/
```

### Folder Template Format

```markdown
# Feature Flags Directory

> Inherits from: parent + typescript.md
> Token budget: ~300 tokens

## Purpose
This directory contains feature flag implementations.

## Patterns
- Use typed flag definitions
- Implement proper fallbacks
- Add analytics tracking

## File Structure
| File | Purpose |
|------|---------|
| `flags.ts` | Flag definitions |
| `provider.tsx` | React context provider |
| `hooks.ts` | Custom hooks for flags |
```

## Composite Templates

### Multi-Framework Projects

When a project uses multiple frameworks, templates are combined:

```markdown
# Next.js + Supabase Project

> Inherits from: global-claude.md + CLAUDE.md.template + typescript.md + nextjs.md + supabase.md
> Merge strategy: additive
```

### Conflict Resolution in Composites

When composing multiple templates:

1. Templates are applied left-to-right
2. Later templates override earlier ones for conflicts
3. Use explicit directives for complex merges

```markdown
> Inherits from: typescript.md + nextjs.md + supabase.md
> Conflicts:
>   - auth: supabase.md (use Supabase auth patterns)
>   - routing: nextjs.md (use Next.js routing)
```

## Implementation Examples

### Example 1: Basic Inheritance

```markdown
# React Component Template
> Inherits from: typescript.md
> Token budget: ~400 tokens

## Component Patterns
# @extend

- Use functional components with hooks
- Implement proper prop types
- Add display names for debugging
```

### Example 2: Override Section

```markdown
# Monorepo Apps Template
> Inherits from: monorepo.md
> Token budget: ~300 tokens

## Project Structure
# @override

Monorepo app packages have a different structure than shared packages.

```
apps/my-app/
├── src/
│   ├── app/        # Next.js app router
│   └── components/ # App-specific components
└── package.json
```
```

### Example 3: Complex Merge

```markdown
# Full-Stack Next.js + Supabase Template
> Inherits from: nextjs.md + supabase.md
> Token budget: ~600 tokens

## Authentication
# @override

Use Supabase Auth with Next.js middleware:

```typescript
// middleware.ts
import { createServerClient } from '@supabase/ssr';
// ... Supabase-specific Next.js auth setup
```

## API Patterns
# @extend

- Use Next.js route handlers for API endpoints
- Connect to Supabase for data operations
```

## Best Practices

### 1. Respect Token Budgets

Keep templates focused and within budget:

```markdown
# Good: Focused template
## Key Patterns
- Pattern 1: Brief explanation
- Pattern 2: Brief explanation

# Avoid: Verbose template
## Key Patterns
Pattern 1 is a fundamental concept that originated in...
[500 words of explanation]
```

### 2. Use Clear Inheritance

Document the inheritance chain explicitly:

```markdown
> Inherits from: global-claude.md + CLAUDE.md.template + typescript.md
```

### 3. Minimize Overrides

Prefer extension over override:

```markdown
# Preferred
## DO NOT
# @extend
- Project-specific rule

# Avoid unless necessary
## DO NOT
# @override
- Complete list of rules (loses parent context)
```

### 4. Test Inheritance

Verify the merged output:

```bash
jarvis template preview --project-type=nextjs
jarvis template validate --path=./templates/project-types/my-template.md
```

### 5. Document Conflicts

When inheriting from multiple sources, document conflict resolutions:

```markdown
> Conflicts resolved:
>   - Styling: Uses Tailwind (from nextjs.md) over styled-components (from react.md)
>   - State: Uses React Query (from api.md) over Redux (from default)
```

## Template Metadata

Each template should include metadata for the inheritance system:

```yaml
---
name: "Next.js Template"
version: "1.0.0"
inherits:
  - global-claude.md
  - CLAUDE.md.template
  - typescript.md
token_budget: 800
override_parent: false
tags:
  - frontend
  - react
  - nextjs
---
```

## Debugging Inheritance

### View Inheritance Chain

```bash
jarvis template chain --file=CLAUDE.md
# Output:
# 1. global-claude.md (2000 tokens)
# 2. CLAUDE.md.template (1500 tokens)
# 3. typescript.md (800 tokens)
# 4. nextjs.md (800 tokens)
# Total: 5100 tokens
```

### View Merged Output

```bash
jarvis template merge --dry-run
# Shows the final merged CLAUDE.md without writing
```

### Identify Conflicts

```bash
jarvis template conflicts
# Lists all sections with conflicting definitions
```
