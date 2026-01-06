# Monorepo Project Additions

> Inherits from: global-claude.md + CLAUDE.md.template
> Override: {{OVERRIDE_PARENT}} (set to true for complete override, false for merge)
> Token budget: ~1000 tokens (larger due to structure complexity)

This template extends the base CLAUDE.md with monorepo-specific patterns.

## Tech Stack Additions

```yaml
monorepo:
  tool: {{MONOREPO_TOOL}}
  package_manager: {{PACKAGE_MANAGER}}
  workspaces: {{WORKSPACE_PATHS}}

structure:
  apps: {{APPS_PATH}}
  packages: {{PACKAGES_PATH}}
  shared: {{SHARED_PATH}}
```

## Monorepo Configuration

### Workspace Setup

{{WORKSPACE_CONFIG}}

### Turborepo Configuration (if applicable)

```json
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": {{GLOBAL_DEPS}},
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": {{BUILD_OUTPUTS}}
    },
    "test": {
      "dependsOn": ["build"],
      "outputs": []
    },
    "lint": {
      "outputs": []
    },
    "dev": {
      "cache": false,
      "persistent": true
    }
  }
}
```

## Project Structure

```
{{PROJECT_NAME}}/
├── CLAUDE.md                    # L0: Tech stack, global rules, commands
│
├── apps/
│   ├── CLAUDE.md               # L1: Shared app patterns
{{APPS_STRUCTURE}}
│
├── packages/
│   ├── CLAUDE.md               # L1: Package conventions
{{PACKAGES_STRUCTURE}}
│
├── {{CONFIG_FOLDER}}/
│   └── CLAUDE.md               # L1: Shared configuration
│
└── .claude/
    └── CLAUDE.md               # Meta: About the .claude folder itself
```

## Hierarchical CLAUDE.md Strategy

### Level 0: Root (This File)

- Global tech stack and conventions
- Cross-cutting commands
- Monorepo-wide patterns

### Level 1: Workspace Categories

- apps/CLAUDE.md: Shared application patterns
- packages/CLAUDE.md: Shared package patterns
- {{CONFIG_FOLDER}}/CLAUDE.md: Configuration standards

### Level 2: Individual Workspaces

- apps/{{APP_NAME}}/CLAUDE.md: App-specific patterns
- packages/{{PACKAGE_NAME}}/CLAUDE.md: Package-specific patterns

### Level 3: Feature Boundaries

- apps/{{APP_NAME}}/app/CLAUDE.md: App router conventions
- packages/{{PACKAGE_NAME}}/src/CLAUDE.md: Implementation rules

## Key Patterns

### Package Dependencies

- Internal packages use workspace protocol: `"@{{SCOPE}}/package": "workspace:*"`
- Avoid circular dependencies between packages
- Use dependency graph analysis before changes

```bash
# Check dependency graph
{{DEP_GRAPH_CMD}}

# Find circular dependencies
{{CIRCULAR_DEP_CMD}}
```

### Code Sharing

| Pattern | Use Case |
|---------|----------|
| `packages/ui` | Shared UI components |
| `packages/utils` | Shared utilities |
| `packages/types` | Shared TypeScript types |
| `packages/config` | Shared configuration |
| `packages/database` | Database client and schemas |

### Versioning Strategy

{{VERSIONING_STRATEGY}}

## Commands Reference

### Global Commands (Run from root)

```bash
# Install all dependencies
{{INSTALL_CMD}}

# Build all packages
{{BUILD_ALL_CMD}}

# Test all packages
{{TEST_ALL_CMD}}

# Lint all packages
{{LINT_ALL_CMD}}

# Type check all packages
{{TYPECHECK_ALL_CMD}}
```

### Workspace-Specific Commands

```bash
# Run command in specific workspace
{{WORKSPACE_RUN_CMD}}

# Build specific package
{{BUILD_PACKAGE_CMD}}

# Test specific app
{{TEST_APP_CMD}}

# Dev mode for specific app
{{DEV_APP_CMD}}
```

### Filtering Commands

```bash
# Run only affected packages
{{AFFECTED_CMD}}

# Run only changed packages since main
{{CHANGED_CMD}}

# Run for specific scope
{{SCOPE_CMD}}
```

## Cross-Workspace Development

### Adding Internal Dependencies

```bash
# Add internal package dependency
{{ADD_INTERNAL_DEP_CMD}}
```

### Building Dependencies

When modifying a shared package:

1. Make changes in the package
2. Build the package: `{{BUILD_PACKAGE_CMD}}`
3. TypeScript will auto-resolve in consuming apps (if using project references)
4. For runtime: ensure build artifacts are current

### Hot Reload Setup

{{HOT_RELOAD_CONFIG}}

## Testing Strategy

### Test Hierarchy

| Level | Scope | Location |
|-------|-------|----------|
| Unit | Single function/component | `packages/*/src/**/*.test.ts` |
| Integration | Package API surface | `packages/*/__tests__/` |
| E2E | Full app flows | `apps/*/e2e/` |

### Running Tests

```bash
# Unit tests only
{{UNIT_TEST_CMD}}

# Integration tests
{{INTEGRATION_TEST_CMD}}

# E2E tests
{{E2E_TEST_CMD}}

# All tests with coverage
{{FULL_TEST_CMD}}
```

## CI/CD Patterns

### Pipeline Stages

```yaml
stages:
  - install    # Install dependencies (cached)
  - lint       # Parallel: lint all packages
  - typecheck  # Parallel: type check all packages
  - test       # Parallel: unit tests
  - build      # Topological: build in dependency order
  - e2e        # Sequential: E2E tests
  - deploy     # Conditional: deploy affected apps
```

### Caching Strategy

{{CACHE_STRATEGY}}

## DO NOT

- Create circular dependencies between packages
- Import from app code in shared packages
- Skip building dependencies before testing consumers
- Modify package.json without running install
- Commit without building affected packages
- Use relative imports across workspace boundaries
- Duplicate types that should be shared

## Workspace Templates

### New App Checklist

```markdown
- [ ] Create app folder in apps/
- [ ] Initialize with framework boilerplate
- [ ] Add internal package dependencies
- [ ] Create app-specific CLAUDE.md
- [ ] Add to CI/CD pipeline
- [ ] Configure environment variables
```

### New Package Checklist

```markdown
- [ ] Create package folder in packages/
- [ ] Initialize package.json with correct scope
- [ ] Set up TypeScript configuration
- [ ] Create package-specific CLAUDE.md
- [ ] Add exports to package.json
- [ ] Document public API
- [ ] Add to build pipeline
```

## Dependency Graph

{{DEPENDENCY_GRAPH}}

## Apps Overview

{{APPS_OVERVIEW}}

## Packages Overview

{{PACKAGES_OVERVIEW}}

---

*Monorepo structure auto-detected. Edit as needed.*
