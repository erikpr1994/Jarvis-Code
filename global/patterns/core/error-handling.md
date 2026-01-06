---
name: Error Handling
category: core
language: any
framework: none
keywords: [error, exception, handling, try-catch, result, graceful-degradation]
confidence: 0.9
---

# Error Handling Pattern

## Problem

Inconsistent error handling across the codebase leads to:
- Unhandled exceptions causing crashes
- Internal error details leaking to users
- Difficulty debugging production issues
- Inconsistent user experience when things go wrong

## Solution

Implement a structured error handling approach with custom error classes, centralized error handlers, and consistent error response formats.

## Implementation

### Custom Error Classes

```typescript
// lib/errors.ts

export class AppError extends Error {
  constructor(
    public statusCode: number,
    message: string,
    public code: string,
    public details?: Record<string, unknown>,
    public isOperational: boolean = true,
  ) {
    super(message);
    this.name = 'AppError';
    Error.captureStackTrace(this, this.constructor);
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, identifier?: string) {
    super(
      404,
      identifier ? `${resource} not found: ${identifier}` : `${resource} not found`,
      'NOT_FOUND',
      { resource, identifier },
    );
    this.name = 'NotFoundError';
  }
}

export class ValidationError extends AppError {
  constructor(message: string, field?: string) {
    super(422, message, 'VALIDATION_ERROR', { field });
    this.name = 'ValidationError';
  }
}

export class UnauthorizedError extends AppError {
  constructor(message: string = 'Authentication required') {
    super(401, message, 'UNAUTHORIZED');
    this.name = 'UnauthorizedError';
  }
}

export class ForbiddenError extends AppError {
  constructor(message: string = 'Insufficient permissions') {
    super(403, message, 'FORBIDDEN');
    this.name = 'ForbiddenError';
  }
}

export class ConflictError extends AppError {
  constructor(message: string, details?: Record<string, unknown>) {
    super(409, message, 'CONFLICT', details);
    this.name = 'ConflictError';
  }
}
```

### Result Type Pattern

```typescript
// lib/result.ts

export type Result<T, E = AppError> =
  | { success: true; data: T }
  | { success: false; error: E };

export function ok<T>(data: T): Result<T, never> {
  return { success: true, data };
}

export function err<E>(error: E): Result<never, E> {
  return { success: false, error };
}

// Usage
async function findUser(id: string): Promise<Result<User, AppError>> {
  try {
    const user = await db.user.findUnique({ where: { id } });
    if (!user) {
      return err(new NotFoundError('User', id));
    }
    return ok(user);
  } catch (error) {
    return err(new AppError(500, 'Database error', 'DB_ERROR'));
  }
}

// Consuming Result
const result = await findUser(userId);
if (!result.success) {
  // Handle error - TypeScript knows this is the error case
  console.error(result.error.message);
  return;
}
// Use result.data - TypeScript knows this is User
console.log(result.data.name);
```

### Centralized Error Handler

```typescript
// lib/error-handler.ts

import { NextResponse } from 'next/server';
import { z } from 'zod';
import { AppError } from './errors';

export interface ErrorResponse {
  error: {
    message: string;
    code: string;
    details?: Record<string, unknown>;
  };
  success: false;
}

export function handleError(error: unknown): NextResponse<ErrorResponse> {
  // Always log for debugging
  console.error('Error:', error);

  // Handle our custom errors
  if (error instanceof AppError) {
    return NextResponse.json(
      {
        error: {
          message: error.message,
          code: error.code,
          details: error.details,
        },
        success: false,
      },
      { status: error.statusCode },
    );
  }

  // Handle Zod validation errors
  if (error instanceof z.ZodError) {
    return NextResponse.json(
      {
        error: {
          message: 'Validation failed',
          code: 'VALIDATION_ERROR',
          details: {
            errors: error.errors.map((e) => ({
              field: e.path.join('.'),
              message: e.message,
            })),
          },
        },
        success: false,
      },
      { status: 422 },
    );
  }

  // Never expose internal errors to clients
  return NextResponse.json(
    {
      error: {
        message: 'An unexpected error occurred',
        code: 'INTERNAL_ERROR',
      },
      success: false,
    },
    { status: 500 },
  );
}
```

### Try-Catch Wrapper

```typescript
// lib/try-catch.ts

export async function tryCatch<T>(
  fn: () => Promise<T>,
): Promise<Result<T, Error>> {
  try {
    const data = await fn();
    return { success: true, data };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error : new Error(String(error)),
    };
  }
}

// Usage
const result = await tryCatch(() => fetchExternalApi(data));
if (!result.success) {
  logger.error('API call failed', { error: result.error });
  return fallbackValue;
}
```

## When to Use

- All external API calls
- Database operations
- User input processing
- File system operations
- Any operation that can fail

## Anti-patterns

```typescript
// BAD: Silent error swallowing
try {
  await riskyOperation();
} catch (error) {
  // Do nothing - errors disappear
}

// BAD: Exposing internal errors
catch (error) {
  return { error: error.message }; // May contain sensitive info
}

// BAD: Using generic Error
throw new Error('Something went wrong'); // No structure, no code

// BAD: String-based error handling
if (error.message.includes('not found')) { // Fragile string matching
  // Handle not found
}

// BAD: Not logging before transforming
catch (error) {
  throw new UserFacingError('Something went wrong'); // Original error lost
}
```

```typescript
// GOOD: Proper error handling
try {
  await riskyOperation();
} catch (error) {
  logger.error('Operation failed', { error, context });
  throw new AppError(500, 'Operation failed', 'OPERATION_FAILED');
}

// GOOD: Structured errors with codes
throw new NotFoundError('User', userId);

// GOOD: Code-based error handling
if (error instanceof NotFoundError) {
  // Handle not found
}

// GOOD: Log before transform
catch (error) {
  logger.error('Database error', { error });
  throw new AppError(500, 'Database operation failed', 'DB_ERROR');
}
```

## Related Patterns

- Logging Pattern - For recording errors
- Validation Pattern - For input validation errors
- API Error Handling Pattern - Specific to HTTP APIs
