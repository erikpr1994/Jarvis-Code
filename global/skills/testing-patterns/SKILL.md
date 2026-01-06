---
name: testing-patterns
description: Vitest, Playwright, and testing strategies. Use when writing tests, setting up test infrastructure, or debugging test failures.
---

# Testing Patterns

## Overview

Decision guide for testing strategies focusing on Vitest for unit/integration and Playwright for E2E tests.

## Test Type Decision

| Test Type | Tool | Use When |
|-----------|------|----------|
| Unit | Vitest | Pure functions, utilities, hooks |
| Integration | Vitest | Components with dependencies |
| E2E | Playwright | Critical user flows |
| Visual | Playwright | UI regression |

## Testing Strategy

Strategy is auto-detected based on project type and can be configured per-directory.

### Automatic Strategy Detection

Check current project strategy:
```bash
# Via detect.sh
source ~/.claude/lib/testing/strategy-detector.sh
detect_testing_strategy "."              # Project-level
detect_directory_strategy "." "src/lib"  # Directory-level
```

Or check `settings.json` → `testing.strategy` if explicitly set.

### Per-Directory Strategy Rules

| Directory Pattern | Strategy | Rationale |
|-------------------|----------|-----------|
| `lib/**`, `packages/**`, `utils/**` | Pyramid | Pure functions, edge cases |
| `src/components/**`, `app/**` | Trophy | User-facing, integration |
| `api/**`, `server/**` | Trophy | Test real queries |
| `algorithms/**`, `core/**` | Pyramid | Complex logic, fast feedback |

### Testing Pyramid (Traditional)
```
     /  E2E  \        Few - slow, brittle, high confidence
    /   Int   \       Some - moderate speed/confidence
   /   Unit    \      Many - fast, isolated, low confidence
```
**Best for:** Libraries, utilities, pure logic, microservices

**Guidance:**
- Test every public function with unit tests
- Cover edge cases extensively (null, empty, boundaries)
- Mock external dependencies
- Aim for >80% unit test coverage

### Testing Trophy (Kent C. Dodds)
```
       E2E            Few - critical paths only
   Integration        MOST - best confidence/speed ratio
      Unit            Some - complex logic only
     Static           TypeScript, ESLint, etc.
```
**Best for:** React apps, user-facing features, full-stack apps

**Guidance:**
- Test user workflows, not implementation details
- Use Testing Library patterns (query by role, text)
- Mock only network/external services
- Unit test only complex business logic

### When to Use Each

| Project Type | Auto-Detected | Reasoning |
|--------------|---------------|-----------|
| UI-heavy app | Trophy | Integration tests catch real user issues |
| Pure library | Pyramid | Unit tests cover edge cases efficiently |
| API/Backend with DB | Trophy | Integration tests verify real queries |
| API/Backend pure | Pyramid | Unit + contract tests are faster |
| Full-stack | Trophy | Integration through API boundaries |
| Monorepo | Balanced | Per-directory strategy applies |

### Override Strategy

**Project-level** - Add to `.claude/settings.json`:
```json
{
  "testing": {
    "strategy": "pyramid"
  }
}
```

**Directory-level** - Add frontmatter to folder's `CLAUDE.md`:
```markdown
---
testing_strategy: trophy
---
```

## Vitest Patterns

### Basic Test Structure

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';

describe('UserService', () => {
  let service: UserService;

  beforeEach(() => {
    service = new UserService();
    vi.clearAllMocks();
  });

  it('creates user with valid data', async () => {
    const user = await service.create({ email: 'test@example.com' });
    expect(user).toMatchObject({ email: 'test@example.com' });
  });

  it('throws on duplicate email', async () => {
    await service.create({ email: 'test@example.com' });
    await expect(service.create({ email: 'test@example.com' }))
      .rejects.toThrow('already exists');
  });
});
```

### Mocking

```typescript
// Mock module
vi.mock('@/lib/db', () => ({
  db: {
    user: {
      create: vi.fn(),
      findUnique: vi.fn(),
    },
  },
}));

// Mock implementation per test
it('handles not found', async () => {
  vi.mocked(db.user.findUnique).mockResolvedValue(null);
  await expect(getUser('123')).rejects.toThrow('Not found');
});

// Spy on existing function
const spy = vi.spyOn(console, 'error').mockImplementation(() => {});
expect(spy).toHaveBeenCalledWith('Error message');
```

### React Component Testing

```typescript
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

it('submits form with valid data', async () => {
  const onSubmit = vi.fn();
  render(<LoginForm onSubmit={onSubmit} />);

  await userEvent.type(screen.getByLabelText(/email/i), 'test@example.com');
  await userEvent.type(screen.getByLabelText(/password/i), 'password123');
  await userEvent.click(screen.getByRole('button', { name: /submit/i }));

  await waitFor(() => {
    expect(onSubmit).toHaveBeenCalledWith({
      email: 'test@example.com',
      password: 'password123',
    });
  });
});
```

## Playwright Patterns

### Page Object Model

```typescript
// tests/pages/login.page.ts
export class LoginPage {
  constructor(private page: Page) {}

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.page.fill('[name="email"]', email);
    await this.page.fill('[name="password"]', password);
    await this.page.click('button[type="submit"]');
  }

  async expectError(message: string) {
    await expect(this.page.getByText(message)).toBeVisible();
  }
}

// tests/auth.spec.ts
test('user can login', async ({ page }) => {
  const loginPage = new LoginPage(page);
  await loginPage.goto();
  await loginPage.login('user@example.com', 'password');
  await expect(page).toHaveURL('/dashboard');
});
```

### Fixtures

```typescript
// tests/fixtures.ts
import { test as base } from '@playwright/test';
import { LoginPage } from './pages/login.page';

type Fixtures = {
  loginPage: LoginPage;
  authenticatedPage: Page;
};

export const test = base.extend<Fixtures>({
  loginPage: async ({ page }, use) => {
    await use(new LoginPage(page));
  },
  authenticatedPage: async ({ page }, use) => {
    await page.goto('/login');
    await page.fill('[name="email"]', 'test@example.com');
    await page.click('button[type="submit"]');
    await page.waitForURL('/dashboard');
    await use(page);
  },
});
```

## Anti-Patterns

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| Testing implementation | Brittle tests | Test behavior/output |
| No test isolation | Flaky tests | Reset state in beforeEach |
| Hardcoded delays | Slow, flaky | Use waitFor/polling |
| Testing third-party code | Wasted effort | Mock at boundary |
| Snapshot abuse | Meaningless diffs | Use for specific UI |

```typescript
// BAD: Testing implementation
expect(component.state.isLoading).toBe(true);

// GOOD: Testing behavior
expect(screen.getByRole('status')).toHaveTextContent('Loading...');

// BAD: Hardcoded delay
await page.waitForTimeout(2000);

// GOOD: Wait for condition
await page.waitForSelector('[data-loaded="true"]');
```

## Test Organization

```
tests/
├── unit/              # Pure function tests
├── integration/       # Component + dependency tests
├── e2e/              # Playwright tests
│   ├── fixtures/
│   ├── pages/        # Page objects
│   └── *.spec.ts
└── setup.ts          # Global setup
```

## Red Flags

- Tests that pass when code is broken
- Tests that fail intermittently (flaky)
- Tests longer than 50 lines (decompose)
- Mocking everything (test becomes meaningless)
- No assertions (test does nothing)
- Duplicated setup across tests (use fixtures)

## Quick Reference

```typescript
// Vitest config
export default defineConfig({
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./tests/setup.ts'],
    coverage: { reporter: ['text', 'html'] },
  },
});

// Playwright config
export default defineConfig({
  testDir: './tests/e2e',
  use: { baseURL: 'http://localhost:3000' },
  webServer: { command: 'npm run dev', port: 3000 },
});

// Fast feedback: watch mode
vitest --watch
playwright test --ui
```
