# Generated Directory

> Inherits from: parent CLAUDE.md
> Level: L2 (generated/, dist/, build/, .next/, node_modules/)
> Token budget: ~100 tokens

## ⚠️ DO NOT MODIFY

This directory contains **generated code** that will be overwritten.

**Never:**
- Edit files in this directory manually
- Commit modified generated files
- Debug issues by changing generated code
- Add new files here

**Instead:**
- Modify the source files that generate this output
- Check build/generation configuration
- Regenerate after source changes

## Common Generated Directories

| Directory | Source | Regenerate Command |
|-----------|--------|-------------------|
| `dist/` | TypeScript/build | `pnpm build` |
| `build/` | Build output | `pnpm build` |
| `.next/` | Next.js cache | `pnpm dev` / `pnpm build` |
| `generated/` | Codegen tools | `pnpm codegen` |
| `node_modules/` | Package manager | `pnpm install` |
| `.turbo/` | Turborepo cache | `turbo run build` |
| `coverage/` | Test coverage | `pnpm test:coverage` |

## Troubleshooting

### Stale Generated Code

```bash
# Clear and regenerate
rm -rf dist/ .next/ generated/
pnpm build
pnpm codegen  # If applicable
```

### Type Errors in Generated Code

The issue is in the source:
1. Check source TypeScript files
2. Verify codegen configuration
3. Update dependencies if needed
4. Regenerate

### Build Artifacts Not Updating

```bash
# Force clean rebuild
pnpm clean  # If script exists
rm -rf dist/ .next/
pnpm build
```

## Git Ignore

These directories should be in `.gitignore`:

```gitignore
# Build outputs
dist/
build/
.next/
out/

# Generated code (if regenerated in CI)
generated/

# Dependencies
node_modules/

# Caches
.turbo/
.cache/
coverage/
```

## When Generated Code is Committed

Some projects commit generated code (GraphQL types, API clients). In that case:

1. **Never edit manually** - changes will be lost
2. **Regenerate in CI** - verify no drift
3. **Review generated diffs** - catch schema changes
4. **Document regeneration** - in project README
