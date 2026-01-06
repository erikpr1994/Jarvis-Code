---
name: Authentication
category: feature
language: typescript
framework: nextjs
keywords: [auth, authentication, login, session, jwt, supabase, next-auth]
confidence: 0.9
---

# Authentication Pattern

## Problem

Authentication implementation is security-critical and complex:
- Session management across requests
- Secure token storage
- Protected routes and API endpoints
- Multiple auth providers
- Security vulnerabilities from improper implementation

## Solution

Use established auth libraries (Supabase Auth, NextAuth.js) with proper session handling, protected routes, and secure patterns.

## Implementation

### Supabase Auth Setup

```typescript
// lib/supabase/server.ts
import { createServerClient, type CookieOptions } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options),
            );
          } catch {
            // Handle read-only cookies in Server Components
          }
        },
      },
    },
  );
}
```

```typescript
// lib/supabase/client.ts
import { createBrowserClient } from '@supabase/ssr';

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
```

### Auth Utilities

```typescript
// lib/auth.ts
import { redirect } from 'next/navigation';
import { createClient } from './supabase/server';

export interface Session {
  user: {
    id: string;
    email: string;
    role: string;
  };
}

// Get current session
export async function getSession(): Promise<Session | null> {
  const supabase = await createClient();
  const { data: { user }, error } = await supabase.auth.getUser();

  if (error || !user) {
    return null;
  }

  return {
    user: {
      id: user.id,
      email: user.email!,
      role: user.app_metadata?.role ?? 'user',
    },
  };
}

// Require authentication - redirect if not logged in
export async function requireAuth(): Promise<Session> {
  const session = await getSession();

  if (!session) {
    redirect('/login');
  }

  return session;
}

// Require specific role
export async function requireRole(role: string): Promise<Session> {
  const session = await requireAuth();

  if (session.user.role !== role) {
    redirect('/unauthorized');
  }

  return session;
}

// For API routes - don't redirect, throw
export async function requireAuthApi(): Promise<Session> {
  const session = await getSession();

  if (!session) {
    throw new UnauthorizedError('Authentication required');
  }

  return session;
}
```

### Protected Routes

```typescript
// app/(protected)/layout.tsx
import { requireAuth } from '@/lib/auth';

export default async function ProtectedLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // This will redirect to /login if not authenticated
  await requireAuth();

  return <>{children}</>;
}
```

```typescript
// app/(protected)/admin/layout.tsx
import { requireRole } from '@/lib/auth';

export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Requires admin role
  await requireRole('admin');

  return <>{children}</>;
}
```

### Auth Middleware

```typescript
// middleware.ts
import { NextResponse, type NextRequest } from 'next/server';
import { createServerClient } from '@supabase/ssr';

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({
    request: {
      headers: request.headers,
    },
  });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) =>
            request.cookies.set(name, value),
          );
          response = NextResponse.next({
            request: {
              headers: request.headers,
            },
          });
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  // Refresh session
  const { data: { user } } = await supabase.auth.getUser();

  // Protected routes check
  if (request.nextUrl.pathname.startsWith('/dashboard')) {
    if (!user) {
      const loginUrl = new URL('/login', request.url);
      loginUrl.searchParams.set('redirect', request.nextUrl.pathname);
      return NextResponse.redirect(loginUrl);
    }
  }

  // Redirect logged-in users away from auth pages
  if (['/login', '/signup'].includes(request.nextUrl.pathname)) {
    if (user) {
      return NextResponse.redirect(new URL('/dashboard', request.url));
    }
  }

  return response;
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|public/).*)',
  ],
};
```

### Login/Logout Actions

```typescript
// actions/auth-actions.ts
'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export async function login(formData: FormData) {
  const supabase = await createClient();

  const email = formData.get('email') as string;
  const password = formData.get('password') as string;

  const { error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });

  if (error) {
    return { error: error.message };
  }

  revalidatePath('/', 'layout');
  redirect('/dashboard');
}

export async function signup(formData: FormData) {
  const supabase = await createClient();

  const email = formData.get('email') as string;
  const password = formData.get('password') as string;
  const name = formData.get('name') as string;

  const { error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: { name },
      emailRedirectTo: `${process.env.NEXT_PUBLIC_APP_URL}/auth/callback`,
    },
  });

  if (error) {
    return { error: error.message };
  }

  return { success: 'Check your email to confirm your account' };
}

export async function logout() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  revalidatePath('/', 'layout');
  redirect('/login');
}

export async function signInWithProvider(provider: 'google' | 'github') {
  const supabase = await createClient();

  const { data, error } = await supabase.auth.signInWithOAuth({
    provider,
    options: {
      redirectTo: `${process.env.NEXT_PUBLIC_APP_URL}/auth/callback`,
    },
  });

  if (error) {
    return { error: error.message };
  }

  if (data.url) {
    redirect(data.url);
  }
}
```

### Auth Callback Handler

```typescript
// app/auth/callback/route.ts
import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function GET(request: Request) {
  const requestUrl = new URL(request.url);
  const code = requestUrl.searchParams.get('code');
  const next = requestUrl.searchParams.get('next') ?? '/dashboard';

  if (code) {
    const supabase = await createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);

    if (!error) {
      return NextResponse.redirect(new URL(next, request.url));
    }
  }

  return NextResponse.redirect(new URL('/login?error=auth_failed', request.url));
}
```

### Login Form Component

```typescript
// components/auth/login-form.tsx
'use client';

import { useActionState } from 'react';
import { login, signInWithProvider } from '@/actions/auth-actions';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';

export function LoginForm() {
  const [state, formAction, pending] = useActionState(login, null);

  return (
    <div className="space-y-4">
      <form action={formAction} className="space-y-4">
        {state?.error && (
          <div className="text-red-500 text-sm">{state.error}</div>
        )}

        <Input
          name="email"
          type="email"
          placeholder="Email"
          required
        />

        <Input
          name="password"
          type="password"
          placeholder="Password"
          required
        />

        <Button type="submit" disabled={pending} className="w-full">
          {pending ? 'Signing in...' : 'Sign In'}
        </Button>
      </form>

      <div className="relative">
        <div className="absolute inset-0 flex items-center">
          <span className="w-full border-t" />
        </div>
        <div className="relative flex justify-center text-xs uppercase">
          <span className="bg-background px-2 text-muted-foreground">
            Or continue with
          </span>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <Button
          variant="outline"
          onClick={() => signInWithProvider('google')}
        >
          Google
        </Button>
        <Button
          variant="outline"
          onClick={() => signInWithProvider('github')}
        >
          GitHub
        </Button>
      </div>
    </div>
  );
}
```

## When to Use

- Any application with user accounts
- Multi-tenant applications
- Role-based access control
- Personalized content/features

## Anti-patterns

```typescript
// BAD: Storing passwords in plain text
await db.user.create({
  data: { password: formData.password }, // Never!
});

// BAD: Checking auth only on client
if (typeof window !== 'undefined' && !localStorage.token) {
  redirect('/login'); // Can be bypassed!
}

// BAD: Trusting client-provided user ID
const userId = request.headers.get('x-user-id'); // Can be spoofed!

// BAD: No CSRF protection
// Using GET for state-changing operations

// BAD: Session token in URL
redirect(`/dashboard?token=${token}`); // Token in logs, history
```

```typescript
// GOOD: Use auth library's password hashing
await supabase.auth.signUp({ email, password });

// GOOD: Server-side auth checks
const session = await getSession(); // Verified on server

// GOOD: Get user ID from verified session
const userId = session.user.id; // From JWT, verified

// GOOD: CSRF protection via cookies + POST
<form action={serverAction} method="POST">

// GOOD: HTTP-only cookies for tokens
// Handled automatically by Supabase SSR
```

## Related Patterns

- Supabase RLS Policy Pattern - For database-level authorization
- API Route Pattern - For protected API routes
- Server Action Pattern - For auth actions
