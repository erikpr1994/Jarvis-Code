# Tests Directory

> Inherits from: parent CLAUDE.md
> Level: L2-L3 (varies: __tests__/, tests/, src/**/*.test.*)
> Token budget: ~450 tokens

## Purpose

Test files ensuring code correctness, preventing regressions, and documenting expected behavior.

## Organization

```
tests/                       # Or __tests__/ or colocated
├── unit/                    # Isolated function/component tests
│   ├── services/
│   └── utils/
├── integration/             # Multi-component/API tests
│   ├── api/
│   └── database/
├── e2e/                     # End-to-end user flow tests
│   ├── auth.spec.ts
│   └── checkout.spec.ts
├── fixtures/                # Test data
│   └── users.json
├── mocks/                   # Mock implementations
│   └── api.mock.ts
└── helpers/                 # Test utilities
    └── setup.ts
```

## Naming Conventions

| Pattern | Purpose |
|---------|---------|
| `*.test.ts` | Unit tests (Vitest/Jest) |
| `*.spec.ts` | E2E tests (Playwright/Cypress) |
| `*.integration.test.ts` | Integration tests |
| `__mocks__/*.ts` | Manual mocks |

## Test Structure (AAA Pattern)

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { UserService } from '../services/user.service';

describe('UserService', () => {
  let service: UserService;
  let mockRepo: MockUserRepository;

  beforeEach(() => {
    mockRepo = new MockUserRepository();
    service = new UserService(mockRepo);
    vi.clearAllMocks();
  });

  describe('findById', () => {
    it('returns user when found', async () => {
      // Arrange
      const expectedUser = { id: '1', name: 'Test User' };
      mockRepo.findById.mockResolvedValue(expectedUser);

      // Act
      const result = await service.findById('1');

      // Assert
      expect(result).toEqual(expectedUser);
      expect(mockRepo.findById).toHaveBeenCalledWith('1');
    });

    it('throws NotFoundError when user does not exist', async () => {
      // Arrange
      mockRepo.findById.mockResolvedValue(null);

      // Act & Assert
      await expect(service.findById('999'))
        .rejects.toThrow('User not found');
    });
  });
});
```

## Key Patterns

### Mocking

```typescript
// Mock module
vi.mock('../lib/api', () => ({
  fetchUser: vi.fn(),
}));

// Mock implementation
const mockFetch = vi.fn().mockResolvedValue({ data: [] });

// Spy on method
const spy = vi.spyOn(service, 'validate');

// Mock return values
mockFn.mockReturnValue('value');
mockFn.mockResolvedValue(asyncValue);
mockFn.mockRejectedValue(new Error('Failed'));
```

### Component Testing (React)

```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ProfileForm } from './ProfileForm';

describe('ProfileForm', () => {
  it('submits form with valid data', async () => {
    const onSubmit = vi.fn();
    const user = userEvent.setup();

    render(<ProfileForm onSubmit={onSubmit} />);

    await user.type(screen.getByLabelText(/name/i), 'John Doe');
    await user.type(screen.getByLabelText(/email/i), 'john@example.com');
    await user.click(screen.getByRole('button', { name: /submit/i }));

    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith({
        name: 'John Doe',
        email: 'john@example.com',
      });
    });
  });
});
```

### API Testing

```typescript
import request from 'supertest';
import { app } from '../app';
import { db } from '../db';

describe('GET /api/users/:id', () => {
  beforeEach(async () => {
    await db.user.create({ data: { id: '1', name: 'Test' } });
  });

  afterEach(async () => {
    await db.user.deleteMany();
  });

  it('returns 200 with user data', async () => {
    const res = await request(app).get('/api/users/1');

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ id: '1', name: 'Test' });
  });

  it('returns 404 for non-existent user', async () => {
    const res = await request(app).get('/api/users/999');

    expect(res.status).toBe(404);
  });
});
```

### E2E Testing (Playwright)

```typescript
import { test, expect } from '@playwright/test';

test.describe('Authentication', () => {
  test('user can log in', async ({ page }) => {
    await page.goto('/login');

    await page.fill('[data-testid="email"]', 'user@example.com');
    await page.fill('[data-testid="password"]', 'password123');
    await page.click('[data-testid="submit"]');

    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('h1')).toContainText('Welcome');
  });
});
```

## Commands

```bash
# Run all tests
{{TEST_CMD}}

# Run with coverage
{{COVERAGE_CMD}}

# Run specific file
{{TEST_FILE_CMD}}

# Run in watch mode
{{WATCH_CMD}}

# Run E2E tests
{{E2E_CMD}}
```

## Coverage Requirements

| Type | Target |
|------|--------|
| Unit | {{UNIT_COVERAGE}}% |
| Integration | {{INTEGRATION_COVERAGE}}% |
| Overall | {{OVERALL_COVERAGE}}% |

## DO NOT

- Test implementation details (test behavior)
- Share state between tests
- Use arbitrary timeouts (use waitFor)
- Skip error case testing
- Mock what you don't own (wrap first)
- Write flaky tests (fix or delete)
- Test third-party code
- Ignore test failures in CI
