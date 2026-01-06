# With Skill: test-driven-development

## Scenario
When user asks to implement a new function or feature...

## Expected Behavior (With Skill)

### Improved Response Pattern
1. Claude first discusses requirements and clarifies edge cases
2. Claude writes test cases BEFORE implementation
3. Claude runs tests to verify they fail (RED phase)
4. Claude writes minimal code to pass tests (GREEN phase)
5. Claude refactors with test safety net (REFACTOR phase)

### Example Interaction

**User**: Implement a function that validates email addresses

**Improved Response**:

First, let me clarify some requirements and edge cases:

**Questions to consider:**
- What constitutes a "valid" email? RFC 5322 strict or common patterns?
- Should we handle international characters (e.g., accents, unicode)?
- What should happen with empty string, null, undefined?
- Should we validate domain existence or just format?

Let me write the tests first to capture these requirements:

```javascript
describe('validateEmail', () => {
  // Valid emails
  test('accepts standard email format', () => {
    expect(validateEmail('user@example.com')).toBe(true);
  });

  test('accepts email with subdomain', () => {
    expect(validateEmail('user@mail.example.com')).toBe(true);
  });

  test('accepts email with plus addressing', () => {
    expect(validateEmail('user+tag@example.com')).toBe(true);
  });

  // Invalid emails
  test('rejects email without @', () => {
    expect(validateEmail('userexample.com')).toBe(false);
  });

  test('rejects email without domain', () => {
    expect(validateEmail('user@')).toBe(false);
  });

  // Edge cases
  test('returns false for empty string', () => {
    expect(validateEmail('')).toBe(false);
  });

  test('returns false for null', () => {
    expect(validateEmail(null)).toBe(false);
  });

  test('returns false for undefined', () => {
    expect(validateEmail(undefined)).toBe(false);
  });
});
```

Now let me run these tests to verify they fail (RED phase)...

[Implementation follows after tests pass the RED phase]

## Improvements Achieved

1. **Requirements Clarity**: Edge cases explicitly documented in tests
2. **Test Coverage**: All behaviors verified before coding
3. **Safe Refactoring**: Can confidently modify code with test safety net
4. **Living Documentation**: Tests describe expected behavior
5. **Design Pressure**: TDD forces better interface design

## Key Behaviors to Verify

When the test-driven-development skill is active, Claude should:

- [ ] Ask clarifying questions about edge cases
- [ ] Write test cases before implementation
- [ ] Show the RED phase (tests fail initially)
- [ ] Write minimal code for GREEN phase
- [ ] Suggest refactoring opportunities
- [ ] Run tests after each change
- [ ] Document any assumptions made

## Anti-Patterns to Avoid

Even with the skill, watch for these regressions:

1. Writing implementation "to help understand" before tests
2. Writing tests that pass immediately (not TRUE TDD)
3. Skipping edge case tests "to save time"
4. Writing too many tests at once instead of iteratively
5. Not running tests between RED-GREEN-REFACTOR phases
