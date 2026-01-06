---
name: tdd-workflow
description: Use when implementing any feature or fix. Red-Green-Refactor discipline.
triggers: ["test", "implement", "feature", "fix", "tdd", "red-green-refactor"]
---

# TDD Workflow

**Iron Law:** No production code without a failing test first.

## The Cycle

```
RED    -> Write ONE failing test
VERIFY -> Run it, confirm correct failure (not error, not typo)
GREEN  -> Write MINIMAL code to pass
VERIFY -> Run all tests, confirm pass
REFACTOR -> Clean up, stay green
REPEAT -> Next behavior
```

## RED: Write Failing Test

```typescript
test('calculates total with tax', () => {
  const cart = new Cart([{ price: 100 }]);
  expect(cart.totalWithTax(0.1)).toBe(110);
});
```

**Requirements:** One behavior. Descriptive name. Real assertions.

## VERIFY RED

```bash
npm test -- --testPathPattern="cart"
# Expected: FAIL - totalWithTax is not a function
```

- Test passes? Wrong test. Fix it.
- Test errors? Fix syntax. Re-run.
- Fails correctly? Proceed to GREEN.

## GREEN: Minimal Code

```typescript
totalWithTax(rate: number): number {
  return this.items.reduce((sum, i) => sum + i.price, 0) * (1 + rate);
}
```

**Not allowed:** Extra parameters, untested edge cases, premature optimization.

## VERIFY GREEN

```bash
npm test  # All tests pass, exit 0
```

- Fails? Fix implementation, not test.
- Other tests broke? Fix before proceeding.

## REFACTOR

Only when green: Remove duplication, improve names, extract helpers.

**Run tests after each change.** Stay green.

## Decision Criteria

| Situation | Action |
|-----------|--------|
| Test passes immediately | Testing existing behavior. Write different test. |
| Tempted to write code first | STOP. Delete code. Write test first. |
| Multiple behaviors | One test at a time. One cycle at a time. |

## Red Flags

- Writing code before test -> Delete it. Start over.
- Test passes without implementation -> Wrong test.
- Skipping VERIFY steps -> Never skip.

## Integration

**Pairs with:** verification, systematic-debugging, commit-discipline
