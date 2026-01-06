# API Directory

> Inherits from: parent CLAUDE.md
> Level: L3 (typically app/api, src/api, or api/)
> Token budget: ~500 tokens

## Purpose

API routes and server-side endpoints for {{APP_NAME}}.

## Organization

```
api/
├── auth/                # Authentication endpoints
│   ├── login/route.ts
│   ├── logout/route.ts
│   └── callback/route.ts
├── users/               # User management
│   ├── route.ts         # GET/POST /api/users
│   └── [id]/
│       └── route.ts     # GET/PUT/DELETE /api/users/:id
├── webhooks/            # External webhooks
│   └── stripe/route.ts
└── internal/            # Internal-only endpoints
    └── health/route.ts
```

## Route Handler Pattern

### Basic Structure

```typescript
import { NextResponse } from 'next/server';
import { z } from 'zod';

// Request validation schema
const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
});

// GET handler
export async function GET(request: Request) {
  try {
    // 1. Auth check
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // 2. Parse query params
    const { searchParams } = new URL(request.url);
    const limit = parseInt(searchParams.get('limit') || '10');

    // 3. Execute
    const data = await fetchData({ limit });

    // 4. Return response
    return NextResponse.json(data);
  } catch (error) {
    console.error('GET /api/endpoint error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

// POST handler
export async function POST(request: Request) {
  try {
    // 1. Auth check
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // 2. Parse and validate body
    const body = await request.json();
    const validationResult = createUserSchema.safeParse(body);

    if (!validationResult.success) {
      return NextResponse.json(
        { error: 'Validation failed', details: validationResult.error.flatten() },
        { status: 400 }
      );
    }

    // 3. Execute
    const result = await createUser(validationResult.data);

    // 4. Return response
    return NextResponse.json(result, { status: 201 });
  } catch (error) {
    console.error('POST /api/endpoint error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
```

### Dynamic Routes

```typescript
// app/api/users/[id]/route.ts
export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  const { id } = params;

  const user = await getUser(id);
  if (!user) {
    return NextResponse.json(
      { error: 'User not found' },
      { status: 404 }
    );
  }

  return NextResponse.json(user);
}
```

## Key Patterns

### Authentication

```typescript
// Middleware or helper for auth
import { createServerSupabase } from '@/lib/supabase/server';

async function getCurrentUser() {
  const supabase = await createServerSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  return user;
}

// Use in handlers
export async function GET() {
  const user = await getCurrentUser();
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  // ...
}
```

### Error Handling

```typescript
// Consistent error response format
interface ApiError {
  error: string;
  code?: string;
  details?: unknown;
}

// Error helper
function apiError(message: string, status: number, details?: unknown): NextResponse<ApiError> {
  return NextResponse.json(
    { error: message, details },
    { status }
  );
}
```

### Webhook Verification

```typescript
// app/api/webhooks/stripe/route.ts
import Stripe from 'stripe';

export async function POST(request: Request) {
  const body = await request.text();
  const signature = request.headers.get('stripe-signature')!;

  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch (err) {
    return NextResponse.json(
      { error: 'Webhook signature verification failed' },
      { status: 400 }
    );
  }

  // Handle event
  switch (event.type) {
    case 'payment_intent.succeeded':
      // Handle payment success
      break;
  }

  return NextResponse.json({ received: true });
}
```

## Response Codes

| Code | Meaning | When to Use |
|------|---------|-------------|
| 200 | OK | Successful GET, PUT |
| 201 | Created | Successful POST that creates |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Validation failed |
| 401 | Unauthorized | Not authenticated |
| 403 | Forbidden | Authenticated but not authorized |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Duplicate or state conflict |
| 500 | Internal Error | Unexpected server error |

## Testing

```typescript
import { describe, it, expect, vi } from 'vitest';
import { GET, POST } from './route';

describe('GET /api/users', () => {
  it('returns users for authenticated request', async () => {
    vi.mocked(getCurrentUser).mockResolvedValue({ id: '1' });

    const request = new Request('http://localhost/api/users');
    const response = await GET(request);

    expect(response.status).toBe(200);
    const data = await response.json();
    expect(Array.isArray(data)).toBe(true);
  });

  it('returns 401 for unauthenticated request', async () => {
    vi.mocked(getCurrentUser).mockResolvedValue(null);

    const request = new Request('http://localhost/api/users');
    const response = await GET(request);

    expect(response.status).toBe(401);
  });
});
```

## DO NOT

- Skip input validation
- Return raw error messages to clients in production
- Forget authentication checks on protected routes
- Use GET for mutations (use POST/PUT/DELETE)
- Store sensitive data in query params (use body or headers)
- Skip rate limiting for public endpoints
- Forget CORS headers when needed
- Log sensitive user data
