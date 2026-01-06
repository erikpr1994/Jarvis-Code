---
name: api-error-handling
category: pattern
language: typescript
description: Comprehensive API error handling pattern with structured errors, type safety, and graceful degradation
keywords: [api, error, handling, exception, http, response, typescript]
---

# API Error Handling Pattern

## Overview

A robust error handling pattern for APIs that provides:
- Type-safe error responses
- Consistent error structure
- Graceful degradation
- Security (no internal error leakage)
- Easy debugging

## Error Class Definition

```typescript
// lib/api-errors.ts

/**
 * Base API error class with structured error information.
 */
export class ApiError extends Error {
  constructor(
    public statusCode: number,
    message: string,
    public code?: string,
    public details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = 'ApiError';
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Standard error codes for consistency across APIs.
 */
export const ErrorCode = {
  // Authentication & Authorization
  UNAUTHORIZED: 'UNAUTHORIZED',
  FORBIDDEN: 'FORBIDDEN',
  TOKEN_EXPIRED: 'TOKEN_EXPIRED',
  INVALID_TOKEN: 'INVALID_TOKEN',

  // Resource errors
  NOT_FOUND: 'NOT_FOUND',
  ALREADY_EXISTS: 'ALREADY_EXISTS',
  CONFLICT: 'CONFLICT',

  // Validation errors
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  INVALID_INPUT: 'INVALID_INPUT',
  MISSING_FIELD: 'MISSING_FIELD',

  // Rate limiting
  RATE_LIMITED: 'RATE_LIMITED',
  TOO_MANY_REQUESTS: 'TOO_MANY_REQUESTS',

  // Server errors
  INTERNAL_ERROR: 'INTERNAL_ERROR',
  SERVICE_UNAVAILABLE: 'SERVICE_UNAVAILABLE',
  EXTERNAL_SERVICE_ERROR: 'EXTERNAL_SERVICE_ERROR',
} as const;

export type ErrorCodeType = typeof ErrorCode[keyof typeof ErrorCode];
```

## Response Types

```typescript
// lib/api-types.ts

/**
 * Successful API response wrapper.
 */
export interface ApiResponse<T> {
  data: T;
  success: true;
}

/**
 * Error API response wrapper.
 */
export interface ApiErrorResponse {
  error: {
    message: string;
    code: string;
    field?: string;
    details?: Record<string, unknown>;
  };
  success: false;
}

/**
 * Union type for all API responses.
 */
export type ApiResult<T> = ApiResponse<T> | ApiErrorResponse;

/**
 * Paginated response with metadata.
 */
export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    pageSize: number;
    total: number;
    totalPages: number;
  };
  success: true;
}
```

## Central Error Handler

```typescript
// lib/error-handler.ts
import { NextResponse } from 'next/server';
import { z } from 'zod';
import { ApiError, ErrorCode } from './api-errors';

/**
 * Central error handler that converts any error to a structured API response.
 * NEVER exposes internal error details to clients.
 */
export function handleApiError(error: unknown): NextResponse {
  // Log full error for debugging (server-side only)
  console.error('API Error:', error);

  // Handle known ApiError
  if (error instanceof ApiError) {
    return NextResponse.json(
      {
        error: {
          message: error.message,
          code: error.code,
          ...(error.details && { details: error.details }),
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
          code: ErrorCode.VALIDATION_ERROR,
          details: {
            errors: error.errors.map(e => ({
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

  // Handle Prisma/database errors
  if (error && typeof error === 'object' && 'code' in error) {
    const dbError = error as { code: string };

    if (dbError.code === 'P2002') {
      return NextResponse.json(
        {
          error: {
            message: 'Resource already exists',
            code: ErrorCode.ALREADY_EXISTS,
          },
          success: false,
        },
        { status: 409 },
      );
    }

    if (dbError.code === 'P2025') {
      return NextResponse.json(
        {
          error: {
            message: 'Resource not found',
            code: ErrorCode.NOT_FOUND,
          },
          success: false,
        },
        { status: 404 },
      );
    }
  }

  // NEVER expose internal errors - return generic message
  return NextResponse.json(
    {
      error: {
        message: 'An unexpected error occurred',
        code: ErrorCode.INTERNAL_ERROR,
      },
      success: false,
    },
    { status: 500 },
  );
}
```

## Helper Functions

```typescript
// lib/api-helpers.ts
import { NextResponse } from 'next/server';
import { ApiError, ErrorCode } from './api-errors';

/**
 * Create a success response.
 */
export function success<T>(data: T, status = 200): NextResponse {
  return NextResponse.json({ data, success: true }, { status });
}

/**
 * Create a paginated success response.
 */
export function paginated<T>(
  data: T[],
  page: number,
  pageSize: number,
  total: number,
): NextResponse {
  return NextResponse.json({
    data,
    pagination: {
      page,
      pageSize,
      total,
      totalPages: Math.ceil(total / pageSize),
    },
    success: true,
  });
}

/**
 * Require authentication - throws if not authenticated.
 */
export async function requireAuth(session: unknown): asserts session {
  if (!session) {
    throw new ApiError(401, 'Authentication required', ErrorCode.UNAUTHORIZED);
  }
}

/**
 * Require specific role - throws if not authorized.
 */
export function requireRole(userRole: string, requiredRole: string): void {
  if (userRole !== requiredRole) {
    throw new ApiError(403, 'Insufficient permissions', ErrorCode.FORBIDDEN);
  }
}

/**
 * Require resource exists - throws if not found.
 */
export function requireResource<T>(
  resource: T | null | undefined,
  resourceName = 'Resource',
): asserts resource is T {
  if (!resource) {
    throw new ApiError(404, `${resourceName} not found`, ErrorCode.NOT_FOUND);
  }
}
```

## Usage in API Routes

### Basic GET Endpoint

```typescript
// app/api/users/[id]/route.ts
import { NextRequest } from 'next/server';
import { z } from 'zod';
import { handleApiError } from '@/lib/error-handler';
import { success, requireAuth, requireResource } from '@/lib/api-helpers';
import { getServerSession } from '@/lib/auth';
import { db } from '@/lib/db';

const paramsSchema = z.object({
  id: z.string().uuid(),
});

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } },
) {
  try {
    // Validate params
    const { id } = paramsSchema.parse(params);

    // Check authentication
    const session = await getServerSession();
    requireAuth(session);

    // Fetch resource
    const user = await db.user.findUnique({
      where: { id },
      select: {
        id: true,
        name: true,
        email: true,
        createdAt: true,
      },
    });

    // Ensure resource exists
    requireResource(user, 'User');

    return success(user);
  } catch (error) {
    return handleApiError(error);
  }
}
```

### POST Endpoint with Validation

```typescript
// app/api/users/route.ts
import { NextRequest } from 'next/server';
import { z } from 'zod';
import { handleApiError } from '@/lib/error-handler';
import { success, requireAuth } from '@/lib/api-helpers';
import { ApiError, ErrorCode } from '@/lib/api-errors';

const createUserSchema = z.object({
  email: z.string().email('Invalid email format'),
  name: z.string().min(1, 'Name is required').max(100),
  role: z.enum(['user', 'admin']).default('user'),
});

export async function POST(request: NextRequest) {
  try {
    // Check authentication
    const session = await getServerSession();
    requireAuth(session);

    // Parse and validate body
    const body = await request.json();
    const validatedData = createUserSchema.parse(body);

    // Check for existing user
    const existingUser = await db.user.findUnique({
      where: { email: validatedData.email },
    });

    if (existingUser) {
      throw new ApiError(
        409,
        'User with this email already exists',
        ErrorCode.ALREADY_EXISTS,
        { field: 'email' },
      );
    }

    // Create user
    const user = await db.user.create({
      data: validatedData,
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        createdAt: true,
      },
    });

    return success(user, 201);
  } catch (error) {
    return handleApiError(error);
  }
}
```

### Paginated List Endpoint

```typescript
// app/api/users/route.ts (GET)
import { NextRequest } from 'next/server';
import { z } from 'zod';
import { handleApiError } from '@/lib/error-handler';
import { paginated, requireAuth } from '@/lib/api-helpers';

const querySchema = z.object({
  page: z.coerce.number().min(1).default(1),
  pageSize: z.coerce.number().min(1).max(100).default(20),
  search: z.string().optional(),
});

export async function GET(request: NextRequest) {
  try {
    const session = await getServerSession();
    requireAuth(session);

    // Parse query params
    const { searchParams } = new URL(request.url);
    const query = querySchema.parse({
      page: searchParams.get('page'),
      pageSize: searchParams.get('pageSize'),
      search: searchParams.get('search'),
    });

    // Build where clause
    const where = query.search
      ? {
          OR: [
            { name: { contains: query.search, mode: 'insensitive' } },
            { email: { contains: query.search, mode: 'insensitive' } },
          ],
        }
      : {};

    // Fetch with pagination
    const [users, total] = await Promise.all([
      db.user.findMany({
        where,
        skip: (query.page - 1) * query.pageSize,
        take: query.pageSize,
        orderBy: { createdAt: 'desc' },
      }),
      db.user.count({ where }),
    ]);

    return paginated(users, query.page, query.pageSize, total);
  } catch (error) {
    return handleApiError(error);
  }
}
```

## Client-Side Usage

```typescript
// lib/api-client.ts
import type { ApiResult } from './api-types';

/**
 * Type-safe API client wrapper.
 */
export async function apiCall<T>(
  url: string,
  options?: RequestInit,
): Promise<ApiResult<T>> {
  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  });

  return response.json() as Promise<ApiResult<T>>;
}

/**
 * Usage example with type narrowing.
 */
async function getUser(id: string) {
  const result = await apiCall<User>(`/api/users/${id}`);

  if (!result.success) {
    // Handle error - TypeScript knows this is ApiErrorResponse
    console.error(result.error.message);
    throw new Error(result.error.message);
  }

  // TypeScript knows this is User
  return result.data;
}
```

## Testing

```typescript
// __tests__/api/users.test.ts
import { describe, it, expect, vi } from 'vitest';
import { GET } from '@/app/api/users/[id]/route';

describe('GET /api/users/[id]', () => {
  it('returns 401 when not authenticated', async () => {
    vi.mocked(getServerSession).mockResolvedValue(null);

    const response = await GET(
      new Request('http://localhost/api/users/123'),
      { params: { id: '123' } },
    );

    expect(response.status).toBe(401);
    const json = await response.json();
    expect(json.success).toBe(false);
    expect(json.error.code).toBe('UNAUTHORIZED');
  });

  it('returns 404 when user not found', async () => {
    vi.mocked(getServerSession).mockResolvedValue({ user: { id: '1' } });
    vi.mocked(db.user.findUnique).mockResolvedValue(null);

    const response = await GET(
      new Request('http://localhost/api/users/123'),
      { params: { id: '123' } },
    );

    expect(response.status).toBe(404);
    const json = await response.json();
    expect(json.error.code).toBe('NOT_FOUND');
  });

  it('returns user when found', async () => {
    const mockUser = { id: '123', name: 'Test', email: 'test@example.com' };
    vi.mocked(getServerSession).mockResolvedValue({ user: { id: '1' } });
    vi.mocked(db.user.findUnique).mockResolvedValue(mockUser);

    const response = await GET(
      new Request('http://localhost/api/users/123'),
      { params: { id: '123' } },
    );

    expect(response.status).toBe(200);
    const json = await response.json();
    expect(json.success).toBe(true);
    expect(json.data).toEqual(mockUser);
  });
});
```

## Best Practices

### Do

- Use structured error codes for programmatic handling
- Log full errors server-side for debugging
- Validate all inputs with Zod
- Return consistent response shapes
- Use helper functions for common patterns
- Include request IDs for tracing

### Don't

- Expose internal error messages to clients
- Use string concatenation for error messages
- Forget to handle edge cases
- Return inconsistent status codes
- Skip validation "because it's internal"
- Catch errors and ignore them

## Checklist

- [ ] All endpoints use try-catch with handleApiError
- [ ] All inputs validated with Zod schemas
- [ ] Authentication checked where required
- [ ] Resources verified to exist before use
- [ ] No internal errors exposed to clients
- [ ] Consistent response structure
- [ ] Appropriate HTTP status codes
- [ ] Error codes used for all errors
