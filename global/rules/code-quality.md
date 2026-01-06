---
name: code-quality
category: quality
confidence: 80
description: Code quality standards for maintainable, readable, and correct code
---

# Code Quality Standards

## Overview

Code quality is not optional. These standards ensure code is maintainable, readable, and correct across all projects.

## Type Safety Standards

### TypeScript Configuration

```json
{
  "compilerOptions": {
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "resolveJsonModule": true,
    "isolatedModules": true
  }
}
```

### Type Definitions

```typescript
// GOOD: Explicit interfaces for domain objects
interface User {
  id: string;
  email: string;
  name: string;
  createdAt: Date;
}

// GOOD: Type inference for derived types
type PublicUser = Omit<User, 'password' | 'internalId'>;

// GOOD: Discriminated unions for state
type ApiResult<T> =
  | { success: true; data: T }
  | { success: false; error: string };

// BAD: any type
const user: any = getData();

// BAD: Type assertions without validation
const user = data as User; // No runtime check
```

### Type Guards

```typescript
// GOOD: Type guard for runtime validation
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'email' in value &&
    typeof (value as any).email === 'string'
  );
}

// Usage with type narrowing
if (isUser(data)) {
  console.log(data.email); // TypeScript knows data is User
}
```

## Code Organization

### File Structure

```
src/
├── app/                    # Application entry points
├── components/             # Reusable UI components
│   ├── ui/                 # Base components
│   ├── forms/              # Form components
│   └── layouts/            # Layout components
├── lib/                    # Utilities and helpers
├── hooks/                  # Custom React hooks
├── types/                  # Type definitions
└── services/               # External service integrations
```

### Import Order

```typescript
// 1. React/Framework imports
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

// 2. External libraries
import { z } from 'zod';
import { useForm } from 'react-hook-form';

// 3. Internal packages (monorepo)
import { Button } from '@turbostarter/ui/button';
import { api } from '@/trpc/react';

// 4. Relative imports
import { DashboardHeader } from './dashboard-header';
import type { DashboardProps } from './types';
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Components | PascalCase | `UserProfile.tsx` |
| Utilities | camelCase | `formatDate.ts` |
| Constants | SCREAMING_SNAKE | `MAX_RETRY_COUNT` |
| Types/Interfaces | PascalCase | `UserInput` |
| Enums | PascalCase + SCREAMING_SNAKE values | `UserRole.ADMIN` |
| Files | lowercase-with-dashes | `api-error-handling.md` |

## Function Design

### Single Responsibility

```typescript
// GOOD: Each function does one thing
async function validateEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

async function createUser(input: UserInput): Promise<User> {
  const validated = await validateUserInput(input);
  return await db.user.create(validated);
}

// BAD: Function does too many things
async function createUserAndSendEmail(input: any): Promise<any> {
  // Validation, creation, email sending, logging...
}
```

### Guard Clauses

```typescript
// GOOD: Early returns for error conditions
function processOrder(order: Order | null): Result {
  if (!order) {
    return { success: false, error: 'No order provided' };
  }

  if (order.status !== 'pending') {
    return { success: false, error: 'Order already processed' };
  }

  // Main logic here
  return { success: true, data: processedOrder };
}

// BAD: Nested conditionals
function processOrder(order: Order | null): Result {
  if (order) {
    if (order.status === 'pending') {
      // Deeply nested logic
    }
  }
}
```

### Pure Functions

```typescript
// GOOD: Pure function - no side effects
function calculateTotal(items: CartItem[]): number {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

// BAD: Impure - modifies external state
let total = 0;
function addToTotal(item: CartItem): void {
  total += item.price * item.quantity;
}
```

## Error Handling

### Structured Errors

```typescript
// Define error types
class AppError extends Error {
  constructor(
    public statusCode: number,
    message: string,
    public code?: string,
  ) {
    super(message);
    this.name = 'AppError';
  }
}

const ErrorCode = {
  UNAUTHORIZED: 'UNAUTHORIZED',
  FORBIDDEN: 'FORBIDDEN',
  NOT_FOUND: 'NOT_FOUND',
  VALIDATION_ERROR: 'VALIDATION_ERROR',
} as const;

// Usage
throw new AppError(401, 'Authentication required', ErrorCode.UNAUTHORIZED);
```

### Error Boundaries

```typescript
// Error handler that never leaks internal details
function handleApiError(error: unknown): ApiErrorResponse {
  console.error('API Error:', error);

  if (error instanceof AppError) {
    return {
      error: { message: error.message, code: error.code },
      status: error.statusCode,
    };
  }

  if (error instanceof z.ZodError) {
    return {
      error: { message: 'Validation failed', code: 'VALIDATION_ERROR', details: error.errors },
      status: 422,
    };
  }

  // Never expose internal errors
  return {
    error: { message: 'Internal server error', code: 'INTERNAL_ERROR' },
    status: 500,
  };
}
```

## Documentation

### JSDoc Comments

```typescript
/**
 * Creates a new user in the database.
 *
 * @param input - User creation data
 * @param input.email - Must be a valid email address
 * @param input.name - User's display name
 * @returns The created user object
 * @throws {AppError} If email already exists
 *
 * @example
 * const user = await createUser({ email: 'user@example.com', name: 'John' });
 */
async function createUser(input: UserInput): Promise<User> {
  // Implementation
}
```

### Inline Comments

```typescript
// GOOD: Explain WHY, not WHAT
// Rate limit to prevent abuse - max 10 requests per minute per IP
const rateLimiter = createRateLimiter({ max: 10, window: '1m' });

// BAD: Explains what code does (obvious from reading)
// Loop through users
for (const user of users) {
  // ...
}
```

## Code Quality Checklist

### Before Writing Code

- [ ] Understand requirements fully
- [ ] Check existing patterns in codebase
- [ ] Identify integration points
- [ ] Plan test cases

### During Implementation

- [ ] TDD: Write test first
- [ ] Single responsibility per function
- [ ] Guard clauses for error conditions
- [ ] No magic numbers (use named constants)
- [ ] Meaningful variable/function names

### Before Commit

- [ ] All tests pass
- [ ] No TypeScript errors
- [ ] No linting errors
- [ ] No `any` types
- [ ] No `@ts-ignore`
- [ ] Code reviewed by self

## Anti-Patterns to Avoid

### Don't Do This

```typescript
// 1. Magic numbers
if (retryCount > 3) { } // BAD
if (retryCount > MAX_RETRIES) { } // GOOD

// 2. Nested ternaries
const result = a ? (b ? c : d) : (e ? f : g); // BAD

// 3. Mutating function parameters
function process(items: Item[]) {
  items.push(newItem); // BAD - mutates input
}

// 4. God functions
async function doEverything(data: any): Promise<any> {
  // 200 lines of mixed responsibilities
}

// 5. Boolean trap
createUser('john@example.com', true, false, true); // What do these mean?

// 6. Stringly typed
function setStatus(status: string) { } // BAD
function setStatus(status: 'pending' | 'active' | 'done') { } // GOOD
```

## Metrics

### Targets

| Metric | Target | Rationale |
|--------|--------|-----------|
| Function length | <30 lines | Readability |
| File length | <300 lines | Maintainability |
| Cyclomatic complexity | <10 | Testability |
| Test coverage | >80% | Confidence |
| PR size | <300 lines | Review quality |

## Rationale

Good code quality:

1. **Reduces bugs** - Clear code has fewer hiding places for bugs
2. **Enables refactoring** - Understandable code can be safely changed
3. **Speeds up development** - Less time debugging, more time building
4. **Improves collaboration** - Others can understand and modify code
5. **Reduces maintenance cost** - Future you will thank present you
