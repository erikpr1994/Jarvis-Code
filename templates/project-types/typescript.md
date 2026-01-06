# TypeScript Project Additions

> Inherits from: global-claude.md + CLAUDE.md.template
> Override: {{OVERRIDE_PARENT}} (set to true for complete override, false for merge)
> Token budget: ~800 tokens

This template extends the base CLAUDE.md with TypeScript-specific patterns.

## Tech Stack Additions

```yaml
languages:
  - TypeScript {{TS_VERSION}}
  - JavaScript (ES2022+)

tooling:
  - tsc (TypeScript Compiler)
  - {{PACKAGE_MANAGER}} (package manager)
  - {{BUNDLER}} (bundler)
  - {{LINTER}} (linting)
  - {{FORMATTER}} (formatting)
```

## TypeScript Configuration

### Compiler Options

```json
{
  "strict": {{TS_STRICT}},
  "target": "{{TS_TARGET}}",
  "module": "{{TS_MODULE}}",
  "moduleResolution": "{{TS_MODULE_RESOLUTION}}"
}
```

### Path Aliases

{{PATH_ALIASES}}

## Key Patterns

### Type Definitions

- Use explicit return types for exported functions
- Prefer interfaces for object shapes, types for unions/primitives
- Avoid `any` - use `unknown` with type guards instead
- Use branded types for domain primitives (e.g., `UserId`, `Email`)

```typescript
// Branded type example
type UserId = string & { readonly __brand: 'UserId' };
const createUserId = (id: string): UserId => id as UserId;
```

### Imports & Exports

- Use named exports over default exports (better refactoring support)
- Group imports: external -> internal -> relative -> types
- Use `import type` for type-only imports

```typescript
// Correct import order
import { something } from 'external-package';

import { internalUtil } from '@/lib/utils';

import { localHelper } from './helpers';

import type { MyType } from './types';
```

### Error Handling

- Use discriminated unions for result types
- Implement custom error classes with proper inheritance
- Use exhaustive checks with `never` type

```typescript
// Result pattern
type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E };

// Exhaustive check
function assertNever(x: never): never {
  throw new Error(`Unexpected value: ${x}`);
}
```

### Async Patterns

- Always handle Promise rejections
- Use async/await over raw Promises
- Implement proper cancellation with AbortController

```typescript
async function fetchWithTimeout(
  url: string,
  timeoutMs: number
): Promise<Response> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  try {
    return await fetch(url, { signal: controller.signal });
  } finally {
    clearTimeout(timeoutId);
  }
}
```

## Testing Patterns

### Test Framework: {{TEST_FRAMEWORK}}

```typescript
// Unit test structure
describe('ComponentName', () => {
  describe('methodName', () => {
    it('should handle expected case', () => {
      // Arrange
      // Act
      // Assert
    });

    it('should handle edge case', () => {
      // ...
    });
  });
});
```

### Type Testing

```typescript
// Use expectTypeOf for type assertions (if using vitest)
import { expectTypeOf } from 'vitest';

expectTypeOf<MyFunction>().toBeFunction();
expectTypeOf<MyFunction>().returns.toMatchTypeOf<ExpectedReturn>();
```

## Common Commands

```bash
# Type checking
{{TS_CHECK_CMD}}

# Build
{{TS_BUILD_CMD}}

# Watch mode
{{TS_WATCH_CMD}}

# Generate types
{{TS_GENERATE_CMD}}
```

## DO NOT

- Use `any` without explicit justification in comments
- Skip return type annotations on exported functions
- Use `// @ts-ignore` without `// @ts-expect-error` + explanation
- Mix CommonJS and ESM syntax in the same file
- Forget to handle `null` and `undefined` cases
- Use `as` casting without type guards (prefer type predicates)

## File Conventions

| Pattern | Purpose |
|---------|---------|
| `*.ts` | TypeScript source files |
| `*.tsx` | TypeScript with JSX |
| `*.d.ts` | Type declaration files |
| `*.test.ts` | Unit test files |
| `*.spec.ts` | Integration/spec test files |
| `*.types.ts` | Shared type definitions |

## Dependency Management

### Package Manager: {{PACKAGE_MANAGER}}

```bash
# Install dependencies
{{INSTALL_CMD}}

# Add dependency
{{ADD_DEP_CMD}}

# Add dev dependency
{{ADD_DEV_DEP_CMD}}

# Update dependencies
{{UPDATE_CMD}}
```

### Version Management

- Use exact versions for critical dependencies
- Use caret (^) for regular dependencies
- Lock file must be committed
- Audit dependencies regularly: `{{AUDIT_CMD}}`
