---
name: test
description: Run tests with TDD guidance, coverage analysis, and intelligent test generation
disable-model-invocation: false
---

# /test - Test Command with TDD Guidance

Run tests, analyze coverage, generate missing tests, and guide Test-Driven Development workflows.

## What It Does

1. **Runs test suite** - Executes tests with detailed output
2. **Analyzes coverage** - Identifies untested code paths
3. **Generates tests** - Creates tests for uncovered functionality
4. **TDD guidance** - Helps write tests before implementation
5. **Validates quality** - Ensures tests are meaningful and maintainable

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | Test scope or mode | "unit", "e2e", "coverage", "tdd", "generate" |

## Modes

### Run Mode (Default)
Execute existing tests with detailed output.

### Coverage Mode
Analyze test coverage and identify gaps.

### Generate Mode
Create tests for untested code.

### TDD Mode
Guide test-first development workflow.

## Process

### Phase 1: Environment Detection

1. **Detect test framework**
   - Jest, Vitest, Mocha (JavaScript/TypeScript)
   - pytest, unittest (Python)
   - go test (Go)
   - cargo test (Rust)
   - Other framework detection

2. **Identify test configuration**
   - Config files (jest.config, vitest.config, etc.)
   - Test directories and patterns
   - Coverage thresholds
   - Custom test scripts

3. **Load testing patterns**
   - Project test conventions
   - Mocking strategies in use
   - Fixture patterns
   - Assertion styles

### Phase 2: Test Execution

4. **Run appropriate tests**
   ```bash
   # Based on arguments
   npm run test              # All tests
   npm run test:unit         # Unit only
   npm run test:integration  # Integration
   npm run test:e2e          # End-to-end
   npm run test -- --watch   # Watch mode
   ```

5. **Capture results**
   - Test counts (passed, failed, skipped)
   - Failure details and stack traces
   - Timing information
   - Coverage metrics

6. **Analyze failures**
   - Categorize failure types
   - Identify flaky tests
   - Suggest fixes for common issues

### Phase 3: Coverage Analysis

7. **Generate coverage report**
   ```bash
   npm run test -- --coverage
   ```

8. **Analyze coverage gaps**
   - Files with low coverage
   - Untested functions/methods
   - Missing edge case coverage
   - Critical paths without tests

9. **Prioritize coverage needs**
   - Business-critical code first
   - Complex logic second
   - Error handling third
   - Edge cases fourth

### Phase 4: Test Generation (if requested)

10. **Identify untested code**
    - Parse coverage report
    - Find functions without tests
    - Identify untested branches
    - Locate missing edge cases

11. **Generate test scaffolds**
    ```typescript
    describe('FunctionName', () => {
      it('should handle normal case', () => {
        // TODO: Implement
      });

      it('should handle edge case', () => {
        // TODO: Implement
      });

      it('should throw on invalid input', () => {
        // TODO: Implement
      });
    });
    ```

12. **Follow testing patterns**
    - Match existing test style
    - Use project's assertion library
    - Apply consistent mocking approach
    - Follow naming conventions

### Phase 5: TDD Workflow (if requested)

13. **TDD cycle guidance**
    ```markdown
    ## TDD Cycle

    ### Red Phase (Write Failing Test)
    1. Describe the behavior you want
    2. Write a test that fails
    3. Verify test fails for the right reason

    ### Green Phase (Make It Pass)
    4. Write minimal code to pass
    5. Don't optimize yet
    6. Run tests - should pass

    ### Refactor Phase (Improve)
    7. Clean up the code
    8. Ensure tests still pass
    9. Commit the change
    ```

14. **Interactive TDD mode**
    - Prompt for feature description
    - Help write initial failing test
    - Guide implementation
    - Suggest refactoring opportunities

### Phase 6: Quality Validation

15. **Test quality checks**
    - Tests have meaningful assertions
    - No false positives (tests that always pass)
    - Proper isolation (no test interdependence)
    - Appropriate use of mocks

16. **Test smell detection**
    - Overly complex tests
    - Too many assertions per test
    - Brittle tests (break easily)
    - Slow tests that should be fast

## Output

```markdown
## Test Results

**Suite**: [framework]
**Duration**: [time]

### Summary
| Status | Count |
|--------|-------|
| Passed | 42 |
| Failed | 2 |
| Skipped | 3 |
| Total | 47 |

### Coverage
| Metric | Coverage |
|--------|----------|
| Statements | 85.2% |
| Branches | 78.4% |
| Functions | 91.0% |
| Lines | 84.8% |

### Failures
#### test-name.test.ts
**Test**: should handle edge case
**Error**: Expected X but received Y
**Suggestion**: Check input validation logic

### Coverage Gaps
- `src/utils/validator.ts`: Lines 45-67 untested
- `src/api/handler.ts`: Branch at line 23 untested

### Recommendations
1. Add tests for validator edge cases
2. Test error handling in API handler
3. Consider adding integration tests for auth flow
```

## Examples

**Run all tests:**
```
/test
```

**Run unit tests only:**
```
/test unit
```

**Run with coverage analysis:**
```
/test coverage
```

**Generate tests for uncovered code:**
```
/test generate src/utils/
```

**TDD mode for new feature:**
```
/test tdd user-authentication
```

**Run E2E tests:**
```
/test e2e
```

**Run specific test file:**
```
/test src/components/Button.test.tsx
```

**Watch mode:**
```
/test watch
```

## Test Quality Guidelines

### Good Tests
- Test behavior, not implementation
- One assertion focus per test
- Descriptive test names
- Proper setup/teardown
- Isolated and independent

### Test Naming
```typescript
// Pattern: should [expected behavior] when [condition]
it('should return error when email is invalid', () => {});
it('should update state when button is clicked', () => {});
it('should retry request when network fails', () => {});
```

### Mocking Best Practices
- Mock external dependencies
- Use realistic test data
- Avoid mocking internal implementation
- Reset mocks between tests

## Integration with CI/CD

The command respects CI environment:
- Runs with `--ci` flag when appropriate
- Uses proper exit codes for pipelines
- Generates machine-readable reports
- Integrates with coverage services

## Notes

- Detects test framework automatically
- Respects existing test configuration
- Works with monorepo test setups
- Supports parallel test execution
- Caches test results when appropriate
