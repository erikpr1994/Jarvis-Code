---
name: testing
category: critical
confidence: 0.9
description: TDD rules - the core principle that cannot be automated
---

# Testing Rules (TDD)

## What Can Be Automated

| Rule | Enforcement |
|------|-------------|
| Tests pass before commit | husky pre-commit hook |
| Coverage > 80% | vitest/jest thresholds |
| No floating promises in tests | ESLint |

Install: `~/.claude/templates/project-configs/setup-enforcement.sh --vitest --husky`

---

## What Cannot Be Automated: TDD

> **The Iron Law:** Write the test first. Watch it fail.

This cannot be enforced by tools because the *temporal order* of writing test vs code cannot be verified by static analysis.

**This is the one rule that requires discipline.**

---

## The Cycle

```
RED     → Write failing test
        → Run it, VERIFY it fails
GREEN   → Write minimal code to pass
        → Run it, VERIFY it passes
REFACTOR → Clean up
        → Keep tests green
```

### RED: Write Failing Test

```typescript
test('rejects empty email', async () => {
  const result = await submitForm({ email: '' });
  expect(result.error).toBe('Email required');
});
```

**Run the test. Watch it fail.** If it passes immediately, you're testing existing behavior—fix the test.

### GREEN: Minimal Code

Write ONLY what the test requires:

```typescript
function submitForm(data: FormData) {
  if (!data.email?.trim()) {
    return { error: 'Email required' };
  }
  // ...
}
```

Don't add features the test didn't ask for.

### REFACTOR: Only After Green

- Remove duplication
- Improve names
- Extract helpers
- **Keep tests green throughout**

---

## Red Flags - STOP and Start Over

If you catch yourself:
- Writing code before the test
- Test passes immediately (not testing new behavior)
- Can't explain why the test failed
- Rationalizing "just this once"

**Delete the code. Start over with the test.**

---

## Common Rationalizations (Don't Fall For These)

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Already manually tested" | No record, can't re-run. |
| "Keep code as reference" | You'll adapt it. That's testing after. Delete. |

---

## Exceptions (Require Human Approval)

- Throwaway prototypes
- Generated code (Prisma client, OpenAPI)
- Configuration files

**These are the ONLY exceptions. "It's simple" is not an exception.**
