# {{PACKAGE_NAME}} - Shared Package

> Inherits from: project root CLAUDE.md > packages/CLAUDE.md
> Level: L2 (packages/{{PACKAGE_NAME}})
> Token budget: ~400 tokens

## Purpose

Shared package providing reusable {{PACKAGE_TYPE}} for consumption by apps and other packages in this monorepo.

## Exports

```typescript
// Main entry point: packages/{{PACKAGE_NAME}}/src/index.ts
{{EXPORTS_SUMMARY}}
```

## Key Patterns

### Export Structure

- Use named exports for all public APIs
- Re-export from index.ts for clean imports
- Use `export type` for type-only exports

```typescript
// src/index.ts
export { ComponentA, ComponentB } from './components';
export { utilFunction } from './utils';
export type { TypeA, TypeB } from './types';
```

### Internal Organization

```
src/
├── index.ts        # Public exports
├── components/     # If UI package
├── utils/          # Utility functions
├── types/          # Type definitions
├── hooks/          # React hooks (if applicable)
└── internal/       # Private, not exported
```

### Versioning

- This package uses `workspace:*` for internal dependencies
- Breaking changes require version bump in package.json
- Update changelog when making significant changes

## Dependencies

### Depends On

{{INTERNAL_DEPENDENCIES}}

### Depended By

{{DEPENDENT_PACKAGES}}

## Testing

```bash
# Run package tests
{{TEST_CMD}}

# Run with coverage
{{COVERAGE_CMD}}
```

### Test Requirements

- Unit tests for all exported functions
- Test edge cases and error conditions
- Mock external dependencies

## DO NOT

- Import from app code (packages should be dependency-free)
- Add app-specific logic
- Create circular dependencies with other packages
- Use relative imports outside the package
- Export internal implementation details

## Build

```bash
# Build this package
{{BUILD_CMD}}

# Build in watch mode
{{WATCH_CMD}}
```

## Common Tasks

| Task | Command |
|------|---------|
| Add to consumer | `{{ADD_DEP_CMD}}` |
| Update exports | Edit `src/index.ts` then rebuild |
| Add dependency | `{{ADD_PACKAGE_DEP_CMD}}` |
