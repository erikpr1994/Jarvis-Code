---
name: Next.js API Route
category: framework
language: typescript
framework: nextjs
keywords: [nextjs, api, route, handler, app-router, rest]
confidence: 0.9
---

# Next.js API Route Pattern

## Problem

Building API routes without structure leads to:
- Inconsistent error handling
- Missing validation
- No authentication checks
- Duplicate code across endpoints

## Solution

Create a consistent structure for API routes with middleware-like patterns, proper error handling, and input validation.

## Implementation

### Basic Route Structure

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { handleError } from '@/lib/error-handler';
import { requireAuth } from '@/lib/auth';
import { db } from '@/lib/db';

// Validation schemas
const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: z.enum(['user', 'admin']).default('user'),
});

const querySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  search: z.string().optional(),
});

// GET /api/users
export async function GET(request: NextRequest) {
  try {
    const session = await requireAuth();

    const { searchParams } = new URL(request.url);
    const query = querySchema.parse(Object.fromEntries(searchParams));

    const [users, total] = await Promise.all([
      db.user.findMany({
        where: query.search ? {
          OR: [
            { name: { contains: query.search, mode: 'insensitive' } },
            { email: { contains: query.search, mode: 'insensitive' } },
          ],
        } : undefined,
        skip: (query.page - 1) * query.limit,
        take: query.limit,
        orderBy: { createdAt: 'desc' },
      }),
      db.user.count(),
    ]);

    return NextResponse.json({
      data: users,
      pagination: {
        page: query.page,
        limit: query.limit,
        total,
        totalPages: Math.ceil(total / query.limit),
      },
    });
  } catch (error) {
    return handleError(error);
  }
}

// POST /api/users
export async function POST(request: NextRequest) {
  try {
    const session = await requireAuth();

    const body = await request.json();
    const data = createUserSchema.parse(body);

    const user = await db.user.create({
      data,
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        createdAt: true,
      },
    });

    return NextResponse.json({ data: user }, { status: 201 });
  } catch (error) {
    return handleError(error);
  }
}
```

### Dynamic Route with Parameters

```typescript
// app/api/users/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { handleError, NotFoundError } from '@/lib/errors';
import { requireAuth } from '@/lib/auth';
import { db } from '@/lib/db';

const paramsSchema = z.object({
  id: z.string().uuid(),
});

const updateUserSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  email: z.string().email().optional(),
}).refine(data => Object.keys(data).length > 0, {
  message: 'At least one field must be provided',
});

type RouteContext = {
  params: Promise<{ id: string }>;
};

// GET /api/users/[id]
export async function GET(
  request: NextRequest,
  context: RouteContext,
) {
  try {
    await requireAuth();

    const { id } = paramsSchema.parse(await context.params);

    const user = await db.user.findUnique({
      where: { id },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    if (!user) {
      throw new NotFoundError('User', id);
    }

    return NextResponse.json({ data: user });
  } catch (error) {
    return handleError(error);
  }
}

// PATCH /api/users/[id]
export async function PATCH(
  request: NextRequest,
  context: RouteContext,
) {
  try {
    const session = await requireAuth();
    const { id } = paramsSchema.parse(await context.params);

    // Authorization check
    if (session.user.id !== id && session.user.role !== 'admin') {
      throw new ForbiddenError('Cannot update other users');
    }

    const body = await request.json();
    const data = updateUserSchema.parse(body);

    const user = await db.user.update({
      where: { id },
      data,
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        updatedAt: true,
      },
    });

    return NextResponse.json({ data: user });
  } catch (error) {
    return handleError(error);
  }
}

// DELETE /api/users/[id]
export async function DELETE(
  request: NextRequest,
  context: RouteContext,
) {
  try {
    const session = await requireAuth();
    const { id } = paramsSchema.parse(await context.params);

    // Only admins can delete users
    if (session.user.role !== 'admin') {
      throw new ForbiddenError('Only admins can delete users');
    }

    await db.user.delete({ where: { id } });

    return new NextResponse(null, { status: 204 });
  } catch (error) {
    return handleError(error);
  }
}
```

### Route Handler with Middleware Pattern

```typescript
// lib/api-handler.ts
import { NextRequest, NextResponse } from 'next/server';
import { ZodSchema } from 'zod';
import { handleError } from './error-handler';
import { requireAuth, type Session } from './auth';

type HandlerContext<TParams = unknown, TBody = unknown> = {
  request: NextRequest;
  params: TParams;
  body: TBody;
  session: Session;
};

type RouteHandler<TParams = unknown, TBody = unknown, TResponse = unknown> = (
  ctx: HandlerContext<TParams, TBody>,
) => Promise<TResponse>;

interface CreateHandlerOptions<TParams, TBody> {
  paramsSchema?: ZodSchema<TParams>;
  bodySchema?: ZodSchema<TBody>;
  requireAuth?: boolean;
}

export function createHandler<TParams = unknown, TBody = unknown, TResponse = unknown>(
  handler: RouteHandler<TParams, TBody, TResponse>,
  options: CreateHandlerOptions<TParams, TBody> = {},
) {
  return async (
    request: NextRequest,
    context?: { params: Promise<Record<string, string>> },
  ): Promise<NextResponse> => {
    try {
      // Authentication
      let session: Session | null = null;
      if (options.requireAuth !== false) {
        session = await requireAuth();
      }

      // Parse params
      let params: TParams = {} as TParams;
      if (options.paramsSchema && context?.params) {
        params = options.paramsSchema.parse(await context.params);
      }

      // Parse body
      let body: TBody = {} as TBody;
      if (options.bodySchema) {
        const rawBody = await request.json();
        body = options.bodySchema.parse(rawBody);
      }

      // Call handler
      const result = await handler({
        request,
        params,
        body,
        session: session!,
      });

      // Return response
      if (result === null || result === undefined) {
        return new NextResponse(null, { status: 204 });
      }

      return NextResponse.json({ data: result });
    } catch (error) {
      return handleError(error);
    }
  };
}

// Usage
// app/api/users/[id]/route.ts
import { createHandler } from '@/lib/api-handler';
import { z } from 'zod';

const paramsSchema = z.object({ id: z.string().uuid() });
const updateSchema = z.object({ name: z.string().optional() });

export const GET = createHandler(
  async ({ params }) => {
    const user = await db.user.findUnique({ where: { id: params.id } });
    if (!user) throw new NotFoundError('User', params.id);
    return user;
  },
  { paramsSchema },
);

export const PATCH = createHandler(
  async ({ params, body, session }) => {
    if (session.user.id !== params.id) {
      throw new ForbiddenError();
    }
    return db.user.update({ where: { id: params.id }, data: body });
  },
  { paramsSchema, bodySchema: updateSchema },
);
```

### Response Headers and Options

```typescript
// app/api/download/[id]/route.ts
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;
  const file = await getFile(id);

  return new NextResponse(file.buffer, {
    headers: {
      'Content-Type': file.mimeType,
      'Content-Disposition': `attachment; filename="${file.name}"`,
      'Cache-Control': 'private, max-age=3600',
    },
  });
}

// CORS headers
export async function OPTIONS(request: NextRequest) {
  return new NextResponse(null, {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
}
```

## When to Use

- REST APIs for your application
- Webhook endpoints
- Authentication endpoints
- File upload/download endpoints
- Any server-side data operations

## Anti-patterns

```typescript
// BAD: No error handling
export async function GET() {
  const users = await db.user.findMany(); // Unhandled errors crash
  return NextResponse.json(users);
}

// BAD: No input validation
export async function POST(request: NextRequest) {
  const body = await request.json();
  await db.user.create({ data: body }); // Trusting user input!
}

// BAD: No authentication
export async function DELETE(request: NextRequest, { params }) {
  await db.user.delete({ where: { id: params.id } }); // Anyone can delete!
}

// BAD: Inconsistent response format
export async function GET() {
  return NextResponse.json(users); // Sometimes array
  return NextResponse.json({ users }); // Sometimes object
}
```

```typescript
// GOOD: Complete error handling
export async function GET() {
  try {
    const session = await requireAuth();
    const users = await db.user.findMany();
    return NextResponse.json({ data: users });
  } catch (error) {
    return handleError(error);
  }
}

// GOOD: Validated input
const schema = z.object({ email: z.string().email() });
const data = schema.parse(await request.json());

// GOOD: Authorization checks
if (session.user.role !== 'admin') {
  throw new ForbiddenError();
}

// GOOD: Consistent response format
return NextResponse.json({ data: users }); // Always { data: T }
```

## Related Patterns

- Error Handling Pattern - For API error responses
- Validation Pattern - For request validation
- Authentication Pattern - For auth in routes
