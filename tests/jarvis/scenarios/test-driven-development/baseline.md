# Baseline: test-driven-development

## Scenario
When user asks to implement a new function or feature...

## Observed Behavior (Without Skill)

### Typical Response Pattern
1. Claude jumps directly to writing implementation code
2. No discussion of edge cases or requirements clarification
3. Tests are written after implementation (if at all)
4. Code may be difficult to test due to tight coupling
5. No verification that requirements are correctly understood

### Example Interaction

**User**: Implement a function that validates email addresses

**Baseline Response**:
```javascript
function validateEmail(email) {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return regex.test(email);
}
```

### What's Missing
- No discussion of what constitutes a "valid" email
- No edge case consideration (empty string, null, etc.)
- No test cases to verify behavior
- No explanation of the regex pattern choice
- No consideration of international email formats

## Problems This Skill Should Fix

1. **Requirements Ambiguity**: Implementation may not match user's actual needs
2. **Untested Code**: Bugs discovered later in development cycle
3. **Rigid Design**: Code may be hard to refactor or extend
4. **Documentation Gap**: No test cases documenting expected behavior
5. **False Confidence**: Code appears to work but has hidden edge case bugs

## Metrics for Improvement

| Metric | Baseline | Target |
|--------|----------|--------|
| Tests written first | 0% | 100% |
| Edge cases discussed | 0-1 | 3+ |
| RED-GREEN-REFACTOR followed | No | Yes |
| Refactoring safety | Low | High |
