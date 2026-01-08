---
name: code-quality
category: quality
confidence: 0.8
description: Code quality standards (most enforced by ESLint)
---

# Code Quality Standards

## Enforcement

Most code quality rules are now enforced by **ESLint** at the project level.

See: `templates/project-configs/eslint.config.js`

Install in your project:
```bash
~/.claude/templates/project-configs/setup-enforcement.sh --eslint
```

---

## What ESLint Enforces

| Rule | ESLint Rule |
|------|-------------|
| No `any` types | `@typescript-eslint/no-explicit-any` |
| No `@ts-ignore` without comment | `@typescript-eslint/ban-ts-comment` |
| Cyclomatic complexity < 10 | `complexity` |
| Function length < 30 lines | `max-lines-per-function` |
| File length < 300 lines | `max-lines` |
| No nested ternaries | `no-nested-ternary` |
| No magic numbers | `no-magic-numbers` |
| Naming conventions | `@typescript-eslint/naming-convention` |
| Import order | `import/order` |
| No floating promises | `@typescript-eslint/no-floating-promises` |

---

## Guidelines That Can't Be Automated

### Type Guards for Runtime Validation

When working with unknown data (API responses, user input), use type guards:

```typescript
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'email' in value
  );
}

// Usage
if (isUser(data)) {
  console.log(data.email); // TypeScript knows data is User
}
```

### Guard Clauses (Early Returns)

Prefer early returns over nested conditionals:

```typescript
// GOOD
function processOrder(order: Order | null): Result {
  if (!order) return { error: 'No order' };
  if (order.status !== 'pending') return { error: 'Already processed' };
  
  // Main logic here
  return { success: true };
}

// BAD
function processOrder(order: Order | null): Result {
  if (order) {
    if (order.status === 'pending') {
      // Deeply nested
    }
  }
}
```

### Pure Functions When Possible

Functions should not have side effects when avoidable:

```typescript
// GOOD: Pure function
function calculateTotal(items: CartItem[]): number {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

// BAD: Side effect
let total = 0;
function addToTotal(item: CartItem): void {
  total += item.price * item.quantity; // Modifies external state
}
```

### Comments Explain WHY, Not WHAT

```typescript
// GOOD: Explains why
// Rate limit to prevent abuse - max 10 requests per minute per IP
const rateLimiter = createRateLimiter({ max: 10, window: '1m' });

// BAD: Explains what (obvious from code)
// Loop through users
for (const user of users) { }
```

---

## Before Commit Checklist

These are enforced by husky pre-commit hook:

- [ ] `npm run type-check` passes
- [ ] `npm run lint` passes
- [ ] `npm test` passes (if enabled)

If checks fail, the commit is blocked.
