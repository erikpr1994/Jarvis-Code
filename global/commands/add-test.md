---
name: add-test
description: Add test files for existing code, detecting test framework and creating appropriate test structure
disable-model-invocation: false
---

# /add-test - Add Tests for Existing Code

Create test files for existing code, automatically detecting the test framework and generating appropriate test structure with meaningful test cases.

## What It Does

1. **Analyzes code** - Reads and understands the target code
2. **Detects framework** - Identifies test framework in use
3. **Creates tests** - Generates test file with proper structure
4. **Writes test cases** - Creates meaningful tests based on code analysis
5. **Includes setup** - Adds mocks, fixtures, and setup as needed

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | File path or pattern to test | "src/utils/format.ts", "src/services/*" |

## Process

### Phase 1: Framework Detection

1. **Detect test framework**
   - Check package.json for test dependencies
   - Look for config files (jest.config.js, vitest.config.ts, pytest.ini)
   - Identify test runner (Jest, Vitest, Mocha, pytest, etc.)

2. **Identify test patterns**
   - Test file location (co-located, `__tests__/`, `tests/`)
   - Naming convention (`.test.ts`, `.spec.ts`, `test_*.py`)
   - Import style (ESM, CommonJS)

3. **Load existing test examples**
   - Find similar tests in codebase
   - Extract patterns and conventions
   - Note assertion style and helpers

### Phase 2: Code Analysis

4. **Parse target code**
   - Identify exports (functions, classes, constants)
   - Understand function signatures
   - Note dependencies and imports
   - Identify side effects

5. **Classify testable units**
   - Pure functions (easy to test)
   - Functions with side effects (need mocking)
   - Classes (need instantiation)
   - React components (need render tests)
   - API handlers (need request mocking)

6. **Identify test scenarios**
   - Happy path cases
   - Edge cases
   - Error conditions
   - Boundary values
   - Invalid inputs

### Phase 3: Test Generation

7. **Create test file structure**

   **JavaScript/TypeScript (Vitest/Jest):**
   ```typescript
   import { describe, it, expect, beforeEach, vi } from 'vitest';
   // or: import { jest } from '@jest/globals';

   import { functionToTest } from './module';

   describe('functionToTest', () => {
     describe('when given valid input', () => {
       it('should return expected result', () => {
         // Arrange
         const input = 'test';

         // Act
         const result = functionToTest(input);

         // Assert
         expect(result).toBe('expected');
       });
     });

     describe('when given invalid input', () => {
       it('should throw an error', () => {
         expect(() => functionToTest(null)).toThrow();
       });
     });

     describe('edge cases', () => {
       it('should handle empty string', () => {
         expect(functionToTest('')).toBe('');
       });
     });
   });
   ```

   **Python (pytest):**
   ```python
   import pytest
   from module import function_to_test

   class TestFunctionToTest:
       def test_valid_input_returns_expected(self):
           # Arrange
           input_value = "test"

           # Act
           result = function_to_test(input_value)

           # Assert
           assert result == "expected"

       def test_invalid_input_raises_error(self):
           with pytest.raises(ValueError):
               function_to_test(None)

       @pytest.mark.parametrize("input,expected", [
           ("", ""),
           ("a", "a"),
       ])
       def test_edge_cases(self, input, expected):
           assert function_to_test(input) == expected
   ```

8. **Generate test cases based on code**

   For each function/method:
   - Test normal operation
   - Test with boundary values
   - Test error conditions
   - Test with mocked dependencies

9. **Add mocks and fixtures**

   **Vitest/Jest mocking:**
   ```typescript
   import { vi } from 'vitest';

   // Mock module
   vi.mock('./dependency', () => ({
     externalCall: vi.fn().mockResolvedValue('mocked'),
   }));

   // Mock specific function
   const mockFn = vi.fn();
   ```

   **pytest fixtures:**
   ```python
   @pytest.fixture
   def mock_service(mocker):
       return mocker.patch('module.external_service')

   def test_with_mock(mock_service):
       mock_service.return_value = 'mocked'
       # test code
   ```

### Phase 4: React Component Tests

10. **For React components, generate:**

    ```typescript
    import { describe, it, expect } from 'vitest';
    import { render, screen, fireEvent } from '@testing-library/react';
    import userEvent from '@testing-library/user-event';
    import { Component } from './Component';

    describe('Component', () => {
      it('renders without crashing', () => {
        render(<Component />);
        expect(screen.getByRole('...')).toBeInTheDocument();
      });

      it('displays correct content', () => {
        render(<Component title="Test" />);
        expect(screen.getByText('Test')).toBeInTheDocument();
      });

      it('handles user interaction', async () => {
        const user = userEvent.setup();
        const onClick = vi.fn();

        render(<Component onClick={onClick} />);
        await user.click(screen.getByRole('button'));

        expect(onClick).toHaveBeenCalled();
      });
    });
    ```

### Phase 5: API/Integration Tests

11. **For API handlers:**

    ```typescript
    import { describe, it, expect, beforeAll, afterAll } from 'vitest';
    import request from 'supertest';
    import { app } from './app';

    describe('GET /api/resource', () => {
      it('returns 200 with valid data', async () => {
        const response = await request(app)
          .get('/api/resource')
          .expect(200);

        expect(response.body).toHaveProperty('data');
      });

      it('returns 404 for non-existent resource', async () => {
        await request(app)
          .get('/api/resource/nonexistent')
          .expect(404);
      });
    });
    ```

### Phase 6: Output

12. **Report created tests**

```markdown
## Tests Added

**Target**: [file/pattern]
**Framework**: [Vitest/Jest/pytest/etc.]
**Test File**: [path]

### Test Coverage
| Function/Component | Tests Added |
|-------------------|-------------|
| `functionA` | 4 tests |
| `functionB` | 3 tests |
| `ComponentC` | 5 tests |

### Test Categories
- Happy path: 6 tests
- Edge cases: 4 tests
- Error handling: 3 tests
- Integration: 2 tests

### Mocks Created
- `./dependency` module mock
- `fetch` global mock

### Next Steps
1. Review generated tests
2. Run tests: `npm test [file]`
3. Add additional edge cases
4. Check coverage: `npm run test:coverage`
```

## Flags

| Flag | Description |
|------|-------------|
| `--unit` | Generate unit tests only |
| `--integration` | Generate integration tests |
| `--coverage` | Aim for high coverage |
| `--tdd` | Generate failing tests first |
| `--watch` | Run tests in watch mode after creation |

## Examples

**Add tests for a single file:**
```
/add-test src/utils/format.ts
```

**Add tests for all services:**
```
/add-test src/services/*.ts
```

**Add tests with high coverage focus:**
```
/add-test src/lib/parser.ts --coverage
```

**Add integration tests:**
```
/add-test src/api/routes.ts --integration
```

**TDD style (failing tests first):**
```
/add-test src/features/auth/login.ts --tdd
```

## Framework Support

| Framework | File Pattern | Config Detection |
|-----------|--------------|------------------|
| Vitest | `*.test.ts` | `vitest.config.ts` |
| Jest | `*.test.ts` | `jest.config.js` |
| Mocha | `*.spec.ts` | `mocharc.json` |
| pytest | `test_*.py` | `pytest.ini` |
| Go | `*_test.go` | `go.mod` |
| Rust | `#[test]` | `Cargo.toml` |

## Test Quality Guidelines

Generated tests follow these principles:

1. **Arrange-Act-Assert** structure
2. **Single assertion per test** when practical
3. **Descriptive test names** that explain intent
4. **Isolated tests** that don't depend on each other
5. **Fast execution** with mocked dependencies
6. **Meaningful assertions** not just "doesn't throw"

## Notes

- Analyzes code to understand what needs testing
- Uses existing test patterns from your codebase
- Creates appropriate mocks for external dependencies
- Generates tests that actually verify behavior
- Does not overwrite existing test files
- Flags TODO comments where manual review needed
