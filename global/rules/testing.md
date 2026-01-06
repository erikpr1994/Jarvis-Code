---
name: testing
category: critical
confidence: 0.9
description: Testing rules based on Iron Law TDD - no production code without failing tests first
---

# Testing Rules (Iron Law TDD)

## Overview

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? **Delete it. Start over.**

**No exceptions:**
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete

Implement fresh from tests. Period.

## When to Use TDD

### Always

- New features
- Bug fixes
- Refactoring
- Behavior changes

### Exceptions (Require Human Approval)

- Throwaway prototypes
- Generated code (Prisma, OpenAPI)
- Configuration files

Thinking "skip TDD just this once"? Stop. That's rationalization.

## Red-Green-Refactor Cycle

```
RED     → Write failing test
        → Verify it fails correctly
GREEN   → Write minimal code to pass
        → Verify all tests pass
REFACTOR → Clean up code
        → Keep tests green
REPEAT  → Next feature
```

## RED: Write Failing Test

Write one minimal test showing what should happen:

```typescript
// GOOD: Clear name, tests real behavior, one thing
test('retries failed operations 3 times', async () => {
  let attempts = 0;
  const operation = () => {
    attempts++;
    if (attempts < 3) throw new Error('fail');
    return 'success';
  };

  const result = await retryOperation(operation);

  expect(result).toBe('success');
  expect(attempts).toBe(3);
});
```

```typescript
// BAD: Vague name, tests mock not code
test('retry works', async () => {
  const mock = jest.fn()
    .mockRejectedValueOnce(new Error())
    .mockResolvedValueOnce('success');
  await retryOperation(mock);
  expect(mock).toHaveBeenCalledTimes(2);
});
```

### Requirements for RED Phase

- Test ONE behavior
- Clear, descriptive name
- Test real code (no mocks unless unavoidable)
- Shows desired API

## Verify RED: Watch It Fail

**MANDATORY. Never skip.**

```bash
npm test path/to/test.test.ts
```

Confirm:
1. Test fails (not errors)
2. Failure message is expected
3. Fails because feature missing (not typos)

**Test passes?** You're testing existing behavior. Fix test.

**Test errors?** Fix error, re-run until it fails correctly.

## GREEN: Write Minimal Code

Write the simplest code that makes the test pass:

```typescript
// GOOD: Just enough to pass
async function retryOperation<T>(fn: () => Promise<T>): Promise<T> {
  for (let i = 0; i < 3; i++) {
    try {
      return await fn();
    } catch (e) {
      if (i === 2) throw e;
    }
  }
  throw new Error('unreachable');
}
```

```typescript
// BAD: Over-engineered, YAGNI
async function retryOperation<T>(
  fn: () => Promise<T>,
  options?: {
    maxRetries?: number;
    backoff?: 'linear' | 'exponential';
    onRetry?: (attempt: number) => void;
  }
): Promise<T> {
  // Features no test asked for
}
```

### Rules for GREEN Phase

- Write ONLY what the test requires
- Don't add features
- Don't refactor other code
- Don't "improve" beyond the test

## Verify GREEN: Watch It Pass

**MANDATORY.**

```bash
npm test path/to/test.test.ts
```

Confirm:
1. Test passes
2. Other tests still pass
3. Output pristine (no errors, warnings)

**Test fails?** Fix code, not test.

**Other tests fail?** Fix now.

## REFACTOR: Clean Up

After green only:
- Remove duplication
- Improve names
- Extract helpers

**Rules:**
- Keep tests green
- Don't add behavior
- Run tests after each change

## Good Test Qualities

| Quality | Description | Example |
|---------|-------------|---------|
| **Minimal** | One thing | Split if "and" in name |
| **Clear** | Name describes behavior | `rejectsEmptyEmail` |
| **Intent** | Shows desired API | Demonstrates usage |
| **Independent** | No test order dependency | Each test isolated |
| **Fast** | Runs in milliseconds | No unnecessary I/O |

## Testing Anti-Patterns

### 1. Testing Mock Behavior

```typescript
// BAD: Testing that mock exists
test('renders sidebar', () => {
  render(<Page />);
  expect(screen.getByTestId('sidebar-mock')).toBeInTheDocument();
});

// GOOD: Test real component
test('renders sidebar', () => {
  render(<Page />);
  expect(screen.getByRole('navigation')).toBeInTheDocument();
});
```

### 2. Test-Only Methods in Production

```typescript
// BAD: destroy() only used in tests
class Session {
  async destroy() {
    // Only called in afterEach
  }
}

// GOOD: Test utilities handle cleanup
// test-utils/
export async function cleanupSession(session: Session) {
  // Cleanup logic here
}
```

### 3. Over-Mocking

```typescript
// BAD: Mock breaks test logic
vi.mock('ToolCatalog', () => ({
  discoverAndCacheTools: vi.fn().mockResolvedValue(undefined)
}));
// Test depends on side effect that mock removed!

// GOOD: Mock at correct level
vi.mock('MCPServerManager'); // Just mock slow part
```

### 4. Incomplete Mocks

```typescript
// BAD: Partial mock
const mockResponse = {
  status: 'success',
  data: { userId: '123' }
  // Missing: metadata that downstream code uses
};

// GOOD: Complete mock
const mockResponse = {
  status: 'success',
  data: { userId: '123', name: 'Alice' },
  metadata: { requestId: 'req-789', timestamp: 1234567890 }
};
```

## Bug Fix Flow

**Bug:** Empty email accepted

```typescript
// RED
test('rejects empty email', async () => {
  const result = await submitForm({ email: '' });
  expect(result.error).toBe('Email required');
});

// Verify RED
// $ npm test
// FAIL: expected 'Email required', got undefined

// GREEN
function submitForm(data: FormData) {
  if (!data.email?.trim()) {
    return { error: 'Email required' };
  }
  // ...
}

// Verify GREEN
// $ npm test
// PASS
```

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Already manually tested" | Ad-hoc ≠ systematic. No record, can't re-run. |
| "Deleting X hours is wasteful" | Sunk cost fallacy. Keeping unverified code is debt. |
| "Keep as reference" | You'll adapt it. That's testing after. Delete. |
| "Need to explore first" | Fine. Throw away exploration, start with TDD. |
| "Test hard = skip it" | Test hard = design unclear. Listen to test. |
| "TDD will slow me down" | TDD faster than debugging. |

## Red Flags - STOP and Start Over

- Code before test
- Test after implementation
- Test passes immediately
- Can't explain why test failed
- Tests added "later"
- Rationalizing "just this once"
- "I already manually tested it"
- "Tests after achieve the same purpose"
- "It's about spirit not ritual"
- "This is different because..."

**All of these mean: Delete code. Start over with TDD.**

## Verification Checklist

Before marking work complete:

- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output pristine (no errors, warnings)
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and errors covered

Can't check all boxes? You skipped TDD. Start over.

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API first |
| Test too complicated | Design too complicated. Simplify. |
| Must mock everything | Code too coupled. Use DI. |
| Test setup huge | Extract helpers. Still complex? Simplify design. |

## Quick Reference

```
BEFORE writing any production code:
1. Write test
2. Run test - MUST fail
3. Verify failure is expected
4. Write minimal code
5. Run test - MUST pass
6. Refactor if needed
7. Repeat
```

## The Bottom Line

```
Production code → test exists and failed first
Otherwise → not TDD
```

**No exceptions without human partner's permission.**

TDD IS pragmatic:
- Finds bugs before commit (faster than debugging after)
- Prevents regressions (tests catch breaks immediately)
- Documents behavior (tests show how to use code)
- Enables refactoring (change freely, tests catch breaks)
