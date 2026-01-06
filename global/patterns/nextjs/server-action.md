---
name: Next.js Server Action
category: framework
language: typescript
framework: nextjs
keywords: [nextjs, server-action, form, mutation, use-server, app-router]
confidence: 0.9
---

# Next.js Server Action Pattern

## Problem

Traditional form handling requires:
- Separate API routes
- Manual fetch calls
- Complex state management
- Loading/error state handling

## Solution

Use Server Actions for form submissions and mutations with built-in progressive enhancement, type safety, and simplified state management.

## Implementation

### Basic Server Action

```typescript
// actions/user-actions.ts
'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { requireAuth } from '@/lib/auth';
import { db } from '@/lib/db';

const createUserSchema = z.object({
  name: z.string().min(1, 'Name is required').max(100),
  email: z.string().email('Invalid email'),
  role: z.enum(['user', 'admin']).default('user'),
});

export async function createUser(formData: FormData) {
  // Authentication
  const session = await requireAuth();

  // Validation
  const rawData = {
    name: formData.get('name'),
    email: formData.get('email'),
    role: formData.get('role') || 'user',
  };

  const validatedData = createUserSchema.parse(rawData);

  // Create user
  const user = await db.user.create({
    data: validatedData,
  });

  // Revalidate cache
  revalidatePath('/users');

  // Redirect or return
  redirect(`/users/${user.id}`);
}
```

### Action with Return Value

```typescript
// actions/user-actions.ts
'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';

// Define result type
type ActionResult<T> =
  | { success: true; data: T }
  | { success: false; error: string; fieldErrors?: Record<string, string[]> };

const updateUserSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  email: z.string().email().optional(),
  bio: z.string().max(500).optional(),
});

export async function updateUser(
  userId: string,
  formData: FormData,
): Promise<ActionResult<{ id: string; name: string }>> {
  try {
    const session = await requireAuth();

    // Authorization
    if (session.user.id !== userId && session.user.role !== 'admin') {
      return { success: false, error: 'Not authorized to update this user' };
    }

    // Parse form data
    const rawData = Object.fromEntries(formData.entries());
    const result = updateUserSchema.safeParse(rawData);

    if (!result.success) {
      return {
        success: false,
        error: 'Validation failed',
        fieldErrors: result.error.flatten().fieldErrors,
      };
    }

    // Update user
    const user = await db.user.update({
      where: { id: userId },
      data: result.data,
      select: { id: true, name: true },
    });

    revalidatePath(`/users/${userId}`);

    return { success: true, data: user };
  } catch (error) {
    console.error('Failed to update user:', error);
    return { success: false, error: 'Failed to update user' };
  }
}
```

### Using with useActionState (React 19)

```typescript
// components/user-form.tsx
'use client';

import { useActionState } from 'react';
import { updateUser } from '@/actions/user-actions';

interface FormState {
  success: boolean;
  error?: string;
  fieldErrors?: Record<string, string[]>;
}

const initialState: FormState = { success: false };

export function UserForm({ userId }: { userId: string }) {
  const updateUserWithId = updateUser.bind(null, userId);
  const [state, formAction, pending] = useActionState(
    updateUserWithId,
    initialState,
  );

  return (
    <form action={formAction}>
      {state.error && (
        <div className="text-red-500 mb-4">{state.error}</div>
      )}

      <div className="space-y-4">
        <div>
          <label htmlFor="name" className="block text-sm font-medium">
            Name
          </label>
          <input
            id="name"
            name="name"
            type="text"
            className="mt-1 block w-full rounded border px-3 py-2"
          />
          {state.fieldErrors?.name && (
            <p className="text-red-500 text-sm">{state.fieldErrors.name[0]}</p>
          )}
        </div>

        <div>
          <label htmlFor="email" className="block text-sm font-medium">
            Email
          </label>
          <input
            id="email"
            name="email"
            type="email"
            className="mt-1 block w-full rounded border px-3 py-2"
          />
          {state.fieldErrors?.email && (
            <p className="text-red-500 text-sm">{state.fieldErrors.email[0]}</p>
          )}
        </div>

        <button
          type="submit"
          disabled={pending}
          className="w-full rounded bg-blue-600 px-4 py-2 text-white disabled:opacity-50"
        >
          {pending ? 'Saving...' : 'Save Changes'}
        </button>
      </div>
    </form>
  );
}
```

### Optimistic Updates

```typescript
// components/like-button.tsx
'use client';

import { useOptimistic, useTransition } from 'react';
import { toggleLike } from '@/actions/post-actions';

export function LikeButton({
  postId,
  initialLiked,
  initialCount,
}: {
  postId: string;
  initialLiked: boolean;
  initialCount: number;
}) {
  const [isPending, startTransition] = useTransition();

  const [optimisticState, addOptimistic] = useOptimistic(
    { liked: initialLiked, count: initialCount },
    (state, newLiked: boolean) => ({
      liked: newLiked,
      count: newLiked ? state.count + 1 : state.count - 1,
    }),
  );

  async function handleClick() {
    startTransition(async () => {
      addOptimistic(!optimisticState.liked);
      await toggleLike(postId);
    });
  }

  return (
    <button
      onClick={handleClick}
      disabled={isPending}
      className={`flex items-center gap-2 ${
        optimisticState.liked ? 'text-red-500' : 'text-gray-500'
      }`}
    >
      <HeartIcon filled={optimisticState.liked} />
      <span>{optimisticState.count}</span>
    </button>
  );
}

// actions/post-actions.ts
'use server';

import { revalidatePath } from 'next/cache';

export async function toggleLike(postId: string) {
  const session = await requireAuth();

  const existing = await db.like.findUnique({
    where: {
      userId_postId: { userId: session.user.id, postId },
    },
  });

  if (existing) {
    await db.like.delete({ where: { id: existing.id } });
  } else {
    await db.like.create({
      data: { userId: session.user.id, postId },
    });
  }

  revalidatePath(`/posts/${postId}`);
}
```

### Action with File Upload

```typescript
// actions/upload-actions.ts
'use server';

import { z } from 'zod';
import { put } from '@vercel/blob';

const uploadSchema = z.object({
  file: z.instanceof(File).refine(
    (file) => file.size <= 5 * 1024 * 1024,
    'File must be less than 5MB'
  ),
});

export async function uploadAvatar(formData: FormData) {
  const session = await requireAuth();

  const file = formData.get('file') as File;
  const result = uploadSchema.safeParse({ file });

  if (!result.success) {
    return { success: false, error: result.error.errors[0].message };
  }

  // Upload to blob storage
  const blob = await put(`avatars/${session.user.id}`, file, {
    access: 'public',
    contentType: file.type,
  });

  // Update user with new avatar URL
  await db.user.update({
    where: { id: session.user.id },
    data: { avatarUrl: blob.url },
  });

  revalidatePath('/profile');

  return { success: true, url: blob.url };
}
```

### Server Action Composition

```typescript
// lib/action-utils.ts
import { requireAuth, type Session } from './auth';

type ActionFn<TInput, TOutput> = (
  input: TInput,
  session: Session,
) => Promise<TOutput>;

// Wrap action with auth and error handling
export function createAction<TInput, TOutput>(
  fn: ActionFn<TInput, TOutput>,
) {
  return async (input: TInput) => {
    try {
      const session = await requireAuth();
      return await fn(input, session);
    } catch (error) {
      console.error('Action error:', error);
      throw error;
    }
  };
}

// Usage
// actions/user-actions.ts
export const deleteUser = createAction(async (userId: string, session) => {
  if (session.user.role !== 'admin') {
    throw new Error('Unauthorized');
  }

  await db.user.delete({ where: { id: userId } });
  revalidatePath('/users');
});
```

## When to Use

- Form submissions
- Data mutations (create, update, delete)
- Actions that need server-side execution
- When you need progressive enhancement
- Simple mutations without complex state

## Anti-patterns

```typescript
// BAD: No validation
export async function createUser(formData: FormData) {
  const name = formData.get('name') as string; // No validation!
  await db.user.create({ data: { name } });
}

// BAD: No error handling
export async function deleteUser(id: string) {
  await db.user.delete({ where: { id } }); // Might throw!
}

// BAD: No authentication
export async function updateProfile(formData: FormData) {
  // Anyone can call this!
  await db.user.update({ ... });
}

// BAD: Using for data fetching
export async function getUsers() { // Should be a regular function
  return db.user.findMany();
}

// BAD: Sensitive data in error messages
catch (error) {
  return { error: error.message }; // May leak DB details
}
```

```typescript
// GOOD: Validated input
const result = schema.safeParse(Object.fromEntries(formData));
if (!result.success) {
  return { success: false, fieldErrors: result.error.flatten().fieldErrors };
}

// GOOD: Proper error handling
try {
  await db.user.delete({ where: { id } });
} catch (error) {
  console.error('Delete failed:', error);
  return { success: false, error: 'Failed to delete user' };
}

// GOOD: Authentication check
const session = await requireAuth();
if (session.user.id !== userId) {
  return { success: false, error: 'Not authorized' };
}

// GOOD: Generic error messages
return { success: false, error: 'An unexpected error occurred' };
```

## Related Patterns

- Validation Pattern - For form data validation
- Error Handling Pattern - For action error handling
- React Component Pattern - For form components
