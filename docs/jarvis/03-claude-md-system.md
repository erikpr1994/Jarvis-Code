# Hierarchical CLAUDE.md System

> Part of the [Jarvis Specification](./README.md)

## 4. Hierarchical CLAUDE.md System

### 4.1 Philosophy

Every meaningful folder in a project should have its own `CLAUDE.md` file that provides contextual guidance. This creates a **layered context system** where:

- **Root CLAUDE.md** is always loaded (global rules)
- **Subfolder CLAUDE.md** files are loaded when working in that directory
- **Inheritance**: Child files can override or extend parent rules
- **Most specific wins**: Deeper rules take precedence

### 4.2 What Makes a Folder "Meaningful"

A folder deserves its own CLAUDE.md if it:

| Criterion | Example |
|-----------|---------|
| **Has domain-specific patterns** | `packages/ui/` - component patterns |
| **Has different testing requirements** | `apps/web/` - E2E vs unit |
| **Has unique dependencies** | `packages/database/` - Supabase patterns |
| **Has special conventions** | `supabase/migrations/` - naming rules |
| **Is a feature boundary** | `features/auth/` - auth-specific logic |
| **Contains generated code** | `generated/` - don't modify rules |

### 4.3 Folder Types & Templates

Jarvis auto-generates CLAUDE.md files from templates based on detected folder type:

| Folder Type | Detection | Template Content |
|-------------|-----------|------------------|
| **App** | `apps/*/`, has `package.json` with framework | Routing, pages, layouts, app-specific patterns |
| **Package** | `packages/*/`, has `package.json` | Export patterns, testing, dependencies |
| **UI Library** | Contains `components/`, shadcn config | Component patterns, accessibility, styling |
| **Database** | `supabase/`, `prisma/`, `drizzle/` | Migration naming, query patterns, seeds |
| **API** | `api/`, `routes/`, server actions | Endpoint patterns, auth, validation |
| **Feature** | `features/*/`, `modules/*/` | Feature-specific logic, boundaries |
| **Config** | `.github/`, `.husky/`, config files | CI/CD patterns, hook rules |
| **Docs** | `docs/`, contains `.md` files | Documentation standards, structure |
| **Tests** | `__tests__/`, `*.test.*`, `*.spec.*` | Testing patterns, fixtures, mocks |
| **Generated** | `generated/`, `dist/`, `build/` | DO NOT MODIFY warnings |

### 4.4 Template Structure

Each template follows this structure:

```markdown
# [Folder Name]

## Purpose
[What this folder contains and why]

## Key Patterns
[Folder-specific conventions]

## Dependencies
[What this folder depends on and what depends on it]

## Testing
[How to test code in this folder]

## Common Tasks
[Frequent operations and how to do them]

## DO NOT
[Anti-patterns and things to avoid]
```

### 4.5 Example: Monorepo Structure

```
project/
├── CLAUDE.md                    # L0: Tech stack, global rules, commands
│
├── apps/
│   ├── CLAUDE.md               # L1: Shared app patterns
│   ├── web/
│   │   ├── CLAUDE.md           # L2: Web app (Next.js pages, routing)
│   │   ├── app/
│   │   │   └── CLAUDE.md       # L3: App router conventions
│   │   └── components/
│   │       └── CLAUDE.md       # L3: Web-specific components
│   └── admin/
│       └── CLAUDE.md           # L2: Admin app patterns
│
├── packages/
│   ├── CLAUDE.md               # L1: Package conventions
│   ├── ui/
│   │   ├── CLAUDE.md           # L2: Component library
│   │   └── src/
│   │       └── CLAUDE.md       # L3: Component implementation rules
│   ├── database/
│   │   └── CLAUDE.md           # L2: Supabase patterns
│   └── auth/
│       └── CLAUDE.md           # L2: Auth patterns
│
├── supabase/
│   ├── CLAUDE.md               # L1: Supabase project rules
│   ├── migrations/
│   │   └── CLAUDE.md           # L2: Migration naming, patterns
│   └── functions/
│       └── CLAUDE.md           # L2: Edge function patterns
│
├── docs/
│   ├── CLAUDE.md               # L1: Documentation standards
│   ├── specs/
│   │   └── CLAUDE.md           # L2: Spec writing format
│   └── plans/
│       └── CLAUDE.md           # L2: Plan writing format
│
└── .claude/
    └── CLAUDE.md               # Meta: About the .claude folder itself
```

### 4.6 Auto-Generation Workflow

```
1. DETECTION
   ├── Scan project structure
   ├── Identify folder types by heuristics
   └── Find folders without CLAUDE.md

2. GENERATION
   ├── Select appropriate template
   ├── Fill placeholders from context
   │   ├── Folder name
   │   ├── Parent CLAUDE.md context
   │   ├── Package.json info (if exists)
   │   └── Detected patterns (imports, exports)
   └── Create CLAUDE.md file

3. VALIDATION
   ├── Check for conflicts with parent rules
   ├── Verify no duplicate definitions
   └── Warn if orphaned (no parent CLAUDE.md)

4. MAINTENANCE
   ├── Detect stale content (references removed files)
   ├── Suggest updates when folder changes significantly
   └── Preserve user customizations
```

### 4.7 Context Loading Strategy

When working in a folder, Claude loads CLAUDE.md files in this order:

```
1. ~/.claude/CLAUDE.md           (global, always)
2. project/CLAUDE.md             (project root, always)
3. project/apps/CLAUDE.md        (if working in apps/)
4. project/apps/web/CLAUDE.md    (if working in apps/web/)
5. project/apps/web/app/CLAUDE.md (if working in apps/web/app/)
```

**Token Budget**: Each level should be ~500-1000 tokens max to prevent context bloat.

### 4.8 Inheritance & Override Rules

```yaml
# Parent: project/CLAUDE.md
testing:
  framework: vitest
  coverage: 80%

# Child: project/packages/ui/CLAUDE.md
testing:
  framework: vitest          # Inherited (not specified)
  coverage: 95%              # Override: UI needs higher coverage
  visual: true               # Extension: UI-specific requirement
```

**Rules**:
1. Child keys override parent keys
2. Missing keys are inherited
3. Arrays can extend (`+patterns`) or replace (`patterns`)
4. Conflicts are logged and flagged for review

### 4.9 Commands

| Command | Purpose |
|---------|---------|
| `/generate-claude-md` | Generate CLAUDE.md for current folder |
| `/generate-claude-md --all` | Generate for all meaningful folders |
| `/validate-claude-md` | Check for conflicts and staleness |
| `/update-claude-md` | Refresh from current folder state |
