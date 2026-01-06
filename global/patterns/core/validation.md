---
name: Validation
category: core
language: typescript
framework: none
keywords: [validation, zod, schema, input, sanitization, type-safety]
confidence: 0.9
---

# Validation Pattern

## Problem

Without proper validation:
- Invalid data corrupts the database
- Security vulnerabilities (injection, XSS)
- Runtime errors from unexpected data shapes
- Poor user experience with unclear error messages

## Solution

Use schema-based validation at system boundaries with Zod for TypeScript projects. Validate early, fail fast, and provide clear error messages.

## Implementation

### Basic Schema Definition

```typescript
// schemas/user.ts
import { z } from 'zod';

// Define reusable field schemas
const emailSchema = z.string()
  .email('Invalid email format')
  .toLowerCase()
  .trim();

const passwordSchema = z.string()
  .min(8, 'Password must be at least 8 characters')
  .max(100, 'Password must be less than 100 characters')
  .regex(/[A-Z]/, 'Password must contain an uppercase letter')
  .regex(/[a-z]/, 'Password must contain a lowercase letter')
  .regex(/[0-9]/, 'Password must contain a number');

const nameSchema = z.string()
  .min(1, 'Name is required')
  .max(100, 'Name must be less than 100 characters')
  .trim();

// Compose into object schemas
export const createUserSchema = z.object({
  email: emailSchema,
  password: passwordSchema,
  name: nameSchema,
  role: z.enum(['user', 'admin']).default('user'),
  metadata: z.record(z.unknown()).optional(),
});

export const updateUserSchema = z.object({
  email: emailSchema.optional(),
  name: nameSchema.optional(),
  avatar: z.string().url('Invalid avatar URL').optional(),
}).refine(
  (data) => Object.keys(data).length > 0,
  { message: 'At least one field must be provided' }
);

// Infer types from schemas
export type CreateUserInput = z.infer<typeof createUserSchema>;
export type UpdateUserInput = z.infer<typeof updateUserSchema>;
```

### Complex Validation

```typescript
// schemas/order.ts
import { z } from 'zod';

const orderItemSchema = z.object({
  productId: z.string().uuid(),
  quantity: z.number().int().positive().max(100),
  price: z.number().positive(),
});

export const createOrderSchema = z.object({
  items: z.array(orderItemSchema)
    .min(1, 'Order must have at least one item')
    .max(50, 'Order cannot have more than 50 items'),

  shippingAddress: z.object({
    street: z.string().min(1),
    city: z.string().min(1),
    state: z.string().length(2),
    zipCode: z.string().regex(/^\d{5}(-\d{4})?$/),
    country: z.string().length(2),
  }),

  paymentMethod: z.discriminatedUnion('type', [
    z.object({
      type: z.literal('card'),
      cardToken: z.string(),
    }),
    z.object({
      type: z.literal('bank'),
      accountNumber: z.string(),
      routingNumber: z.string(),
    }),
  ]),

  couponCode: z.string()
    .regex(/^[A-Z0-9]{6,10}$/)
    .optional(),

}).refine(
  (data) => {
    const total = data.items.reduce(
      (sum, item) => sum + item.price * item.quantity,
      0
    );
    return total >= 10; // Minimum order amount
  },
  { message: 'Order total must be at least $10' }
);
```

### API Route Validation

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { createUserSchema } from '@/schemas/user';

export async function POST(request: NextRequest) {
  try {
    // Parse request body
    const body = await request.json();

    // Validate with schema
    const validatedData = createUserSchema.parse(body);

    // validatedData is now typed and validated
    const user = await createUser(validatedData);

    return NextResponse.json({ data: user }, { status: 201 });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        {
          error: {
            message: 'Validation failed',
            code: 'VALIDATION_ERROR',
            details: error.errors.map((e) => ({
              field: e.path.join('.'),
              message: e.message,
            })),
          },
        },
        { status: 422 }
      );
    }
    throw error;
  }
}
```

### Query Parameter Validation

```typescript
// app/api/users/route.ts
const querySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  sort: z.enum(['name', 'createdAt', 'email']).default('createdAt'),
  order: z.enum(['asc', 'desc']).default('desc'),
  search: z.string().max(100).optional(),
  role: z.enum(['user', 'admin']).optional(),
});

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);

  // Convert searchParams to object
  const params = Object.fromEntries(searchParams.entries());

  // Validate and parse
  const query = querySchema.parse(params);

  // query is now typed with defaults applied
  const users = await getUsers({
    skip: (query.page - 1) * query.limit,
    take: query.limit,
    orderBy: { [query.sort]: query.order },
    where: {
      ...(query.search && {
        OR: [
          { name: { contains: query.search } },
          { email: { contains: query.search } },
        ],
      }),
      ...(query.role && { role: query.role }),
    },
  });

  return NextResponse.json({ data: users });
}
```

### Form Validation with React Hook Form

```typescript
// components/user-form.tsx
'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { createUserSchema, type CreateUserInput } from '@/schemas/user';

export function UserForm({ onSubmit }: { onSubmit: (data: CreateUserInput) => void }) {
  const form = useForm<CreateUserInput>({
    resolver: zodResolver(createUserSchema),
    defaultValues: {
      email: '',
      name: '',
      password: '',
      role: 'user',
    },
  });

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      <input {...form.register('email')} />
      {form.formState.errors.email && (
        <span className="text-red-500">
          {form.formState.errors.email.message}
        </span>
      )}
      {/* More fields... */}
    </form>
  );
}
```

### Validation Utility Functions

```typescript
// lib/validation.ts
import { z } from 'zod';

// Safe parse with Result type
export function validate<T>(
  schema: z.ZodSchema<T>,
  data: unknown,
): { success: true; data: T } | { success: false; errors: z.ZodError } {
  const result = schema.safeParse(data);
  if (result.success) {
    return { success: true, data: result.data };
  }
  return { success: false, errors: result.error };
}

// Format Zod errors for API responses
export function formatZodErrors(error: z.ZodError) {
  return error.errors.map((e) => ({
    field: e.path.join('.'),
    message: e.message,
    code: e.code,
  }));
}

// Validate or throw
export function validateOrThrow<T>(schema: z.ZodSchema<T>, data: unknown): T {
  return schema.parse(data);
}
```

## When to Use

- All API request bodies
- Query parameters
- URL path parameters
- Form submissions
- Configuration files
- External API responses
- Database results (when uncertain)

## Anti-patterns

```typescript
// BAD: Manual validation
function validateEmail(email: string): boolean {
  return email.includes('@'); // Incomplete, error-prone
}

// BAD: Validation after use
const user = await db.user.create({ data: req.body }); // Already saved!
validateUser(user); // Too late

// BAD: Trusting client-side validation only
// Server must always validate, client validation is UX only

// BAD: Not handling validation errors
const data = schema.parse(body); // Throws, but not caught

// BAD: Validating in multiple places inconsistently
// Route validates one way, service validates differently
```

```typescript
// GOOD: Schema-based validation
const emailSchema = z.string().email();

// GOOD: Validate at system boundary, before any processing
const validatedData = schema.parse(body);
const user = await createUser(validatedData);

// GOOD: Validate on both client and server
// Client: for UX
// Server: for security

// GOOD: Proper error handling
const result = schema.safeParse(body);
if (!result.success) {
  return errorResponse(result.error);
}

// GOOD: Single source of truth for validation
// Export schemas, import everywhere they're needed
```

## Related Patterns

- Error Handling Pattern - For handling validation errors
- API Error Handling Pattern - For returning validation errors
- React Component Pattern - For form validation
