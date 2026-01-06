---
name: generate-claude-md
description: Generate CLAUDE.md files for folders in the project hierarchy. Creates context-specific documentation for meaningful directories.
disable-model-invocation: false
---

# /generate-claude-md - Hierarchical CLAUDE.md Generation

Generate CLAUDE.md files for meaningful folders in your project, creating a layered context system.

## What It Does

1. **Scans project structure** - Identifies meaningful folders deserving CLAUDE.md files
2. **Detects folder types** - Matches against known patterns (app, api, components, tests, etc.)
3. **Selects templates** - Uses appropriate template for each folder type
4. **Fills context** - Populates templates with project-specific information
5. **Validates** - Checks for conflicts and inheritance issues

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `$ARGUMENTS` | Target path or `--all` for entire project | Current directory |
| `--all` | Generate for all meaningful folders | false |
| `--dry-run` | Show what would be generated without creating | false |
| `--force` | Overwrite existing CLAUDE.md files | false |

## Folder Type Detection

| Folder Pattern | Type | Template |
|----------------|------|----------|
| `apps/*/`, `app/` | App | app.md |
| `packages/ui/`, `ui/` | UI Library | ui-library.md |
| `features/*/`, `modules/*/` | Feature | feature.md |
| `components/`, `src/components/` | Components | src-components.md |
| `api/`, `routes/`, `server/` | API | src-api.md |
| `tests/`, `__tests__/` | Tests | tests.md |
| `docs/` | Documentation | docs.md |
| `scripts/` | Scripts | scripts.md |
| `supabase/migrations/` | Migrations | supabase-migrations.md |
| `packages/*/` | Package | packages-shared.md |
| `.github/`, `.husky/`, `config/` | Config | config.md |
| `dist/`, `build/`, `generated/` | Generated | generated.md |

## Process

### Phase 1: Scan

```
1. SCAN project directory tree
   ├── Find all directories
   ├── Identify folders without CLAUDE.md
   └── Filter to meaningful folders only
```

### Phase 2: Detect Types

```
2. DETECT folder types for each candidate
   ├── Match against folder patterns
   ├── Check for type indicators (package.json, tsconfig, etc.)
   └── Assign appropriate template
```

### Phase 3: Generate

```
3. GENERATE CLAUDE.md for each folder
   ├── Load template for folder type
   ├── Extract context from:
   │   ├── Parent CLAUDE.md (inheritance)
   │   ├── Package.json (if exists)
   │   ├── Existing files (patterns)
   │   └── Detected conventions
   └── Create CLAUDE.md file
```

### Phase 4: Validate

```
4. VALIDATE generated files
   ├── Check inheritance chain is complete
   ├── Verify no conflicts with parent rules
   └── Warn about orphaned files
```

## Template Placeholders

Templates use these placeholders filled from context:

| Placeholder | Source |
|-------------|--------|
| `{{FOLDER_NAME}}` | Folder name |
| `{{FOLDER_PATH}}` | Relative path from root |
| `{{PARENT_CONTEXT}}` | Inherited from parent CLAUDE.md |
| `{{PACKAGE_NAME}}` | From package.json |
| `{{DEPENDENCIES}}` | Key dependencies detected |
| `{{STYLING_APPROACH}}` | Detected CSS framework |
| `{{TEST_FRAMEWORK}}` | Detected test framework |

## Inheritance Rules

CLAUDE.md files inherit context from parents:

```
project/CLAUDE.md           # L0: Project root (always loaded)
  └── apps/CLAUDE.md        # L1: Apps context
      └── web/CLAUDE.md     # L2: Web app context
          └── app/CLAUDE.md # L3: App router context
```

**Rules:**
- Child keys override parent keys
- Missing keys are inherited
- Arrays can extend (`+patterns`) or replace (`patterns`)
- Max depth: 4 levels recommended

## Output

### Single Folder

```markdown
## CLAUDE.md Generated

**Path**: apps/web/
**Type**: App
**Template**: app.md
**Inherits from**: apps/CLAUDE.md

### Content Preview
- Purpose section
- Routing patterns
- Data fetching conventions
- Testing requirements
```

### Full Project (--all)

```markdown
## CLAUDE.md Files Generated

| Path | Type | Status |
|------|------|--------|
| apps/ | Apps | Created |
| apps/web/ | App | Created |
| apps/web/components/ | Components | Created |
| packages/ui/ | UI Library | Created |
| tests/ | Tests | Skipped (exists) |

**Created**: 4 files
**Skipped**: 1 file (already exists)
**Orphaned**: 0 (all have parent)

### Next Steps
1. Review generated CLAUDE.md files
2. Customize as needed for your project
3. Run `/validate-claude-md` to check for issues
```

## Examples

**Generate for current folder:**
```
/generate-claude-md
```

**Generate for specific folder:**
```
/generate-claude-md apps/web/
```

**Generate for entire project:**
```
/generate-claude-md --all
```

**Preview without creating:**
```
/generate-claude-md --all --dry-run
```

**Force overwrite existing:**
```
/generate-claude-md apps/web/ --force
```

## Validation Checks

After generation, validates:

- [ ] All meaningful folders have CLAUDE.md
- [ ] Inheritance chain is complete (no orphans)
- [ ] No duplicate rule definitions
- [ ] Token budget per file (< 1000 tokens recommended)
- [ ] Template placeholders all filled

## Maintenance

**Update existing CLAUDE.md:**
```
/generate-claude-md --force
```

**Check for staleness:**
- References to removed files
- Outdated dependency information
- Missing new patterns

## Related Commands

| Command | Purpose |
|---------|---------|
| `/init` | Initial project setup (includes CLAUDE.md) |
| `/validate-claude-md` | Check for conflicts and issues |
| `/update-claude-md` | Refresh from current folder state |

## Notes

- Run from project root for best detection
- Generated files should be reviewed and customized
- Preserves user customizations when updating
- Use `--dry-run` first to preview changes
- Token budget: ~500-1000 tokens per file recommended
