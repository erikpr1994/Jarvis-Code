---
name: react-component
category: pattern
language: typescript
description: Modern React component patterns with TypeScript, composition, and best practices
keywords: [react, component, typescript, hooks, composition, patterns]
---

# React Component Pattern

## Overview

Modern React component patterns using TypeScript with:
- Strong typing for props and state
- Composition over inheritance
- Server and Client component separation
- Proper error handling and loading states
- Accessibility built-in

## Basic Component Structure

### Functional Component with TypeScript

```typescript
// components/user-card.tsx
import { cn } from '@/lib/utils';

interface UserCardProps {
  user: {
    id: string;
    name: string;
    email: string;
    avatarUrl?: string;
  };
  variant?: 'default' | 'compact' | 'detailed';
  className?: string;
  onSelect?: (userId: string) => void;
}

export function UserCard({
  user,
  variant = 'default',
  className,
  onSelect,
}: UserCardProps) {
  return (
    <div
      className={cn(
        'rounded-lg border p-4 transition-colors',
        variant === 'compact' && 'p-2',
        variant === 'detailed' && 'p-6',
        onSelect && 'cursor-pointer hover:bg-accent',
        className,
      )}
      onClick={() => onSelect?.(user.id)}
      role={onSelect ? 'button' : undefined}
      tabIndex={onSelect ? 0 : undefined}
      onKeyDown={(e) => {
        if (onSelect && (e.key === 'Enter' || e.key === ' ')) {
          e.preventDefault();
          onSelect(user.id);
        }
      }}
    >
      <div className="flex items-center gap-3">
        {user.avatarUrl && (
          <img
            src={user.avatarUrl}
            alt={`${user.name}'s avatar`}
            className="h-10 w-10 rounded-full"
          />
        )}
        <div>
          <p className="font-medium">{user.name}</p>
          {variant !== 'compact' && (
            <p className="text-sm text-muted-foreground">{user.email}</p>
          )}
        </div>
      </div>
    </div>
  );
}
```

## Server Components (Default in Next.js 15)

### Data Fetching Server Component

```typescript
// app/users/page.tsx (Server Component - no 'use client')
import { api } from '@/trpc/server';
import { UserList } from '@/components/user-list';
import { Suspense } from 'react';
import { UserListSkeleton } from '@/components/user-list-skeleton';

export default async function UsersPage() {
  // Direct async data fetching - no useEffect needed
  const users = await api.user.getAll();

  return (
    <div className="container py-8">
      <h1 className="mb-6 text-2xl font-bold">Users</h1>
      <Suspense fallback={<UserListSkeleton />}>
        <UserList users={users} />
      </Suspense>
    </div>
  );
}
```

### Server Component with Parallel Data Fetching

```typescript
// app/dashboard/page.tsx
import { api } from '@/trpc/server';
import { Dashboard } from '@/components/dashboard';

export default async function DashboardPage() {
  // Parallel data fetching for better performance
  const [user, projects, analytics, notifications] = await Promise.all([
    api.auth.getCurrentUser(),
    api.project.getUserProjects(),
    api.analytics.getDashboardStats(),
    api.notification.getUnreadCount(),
  ]);

  return (
    <Dashboard
      user={user}
      projects={projects}
      analytics={analytics}
      notificationCount={notifications.count}
    />
  );
}
```

## Client Components

### Interactive Component with State

```typescript
// components/search-input.tsx
'use client';

import { useState, useTransition, useDeferredValue } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { Input } from '@/components/ui/input';
import { SearchIcon, Loader2 } from 'lucide-react';

interface SearchInputProps {
  placeholder?: string;
  className?: string;
}

export function SearchInput({
  placeholder = 'Search...',
  className,
}: SearchInputProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [isPending, startTransition] = useTransition();

  const [value, setValue] = useState(searchParams.get('q') ?? '');
  const deferredValue = useDeferredValue(value);

  const handleSearch = (newValue: string) => {
    setValue(newValue);

    startTransition(() => {
      const params = new URLSearchParams(searchParams);
      if (newValue) {
        params.set('q', newValue);
      } else {
        params.delete('q');
      }
      router.push(`?${params.toString()}`);
    });
  };

  return (
    <div className="relative">
      <SearchIcon className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
      <Input
        value={value}
        onChange={(e) => handleSearch(e.target.value)}
        placeholder={placeholder}
        className={cn('pl-10', className)}
      />
      {isPending && (
        <Loader2 className="absolute right-3 top-3 h-4 w-4 animate-spin" />
      )}
    </div>
  );
}
```

### Form Component with React Hook Form

```typescript
// components/forms/user-form.tsx
'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import { toast } from 'sonner';

const userFormSchema = z.object({
  name: z.string().min(1, 'Name is required').max(100),
  email: z.string().email('Invalid email address'),
  bio: z.string().max(500).optional(),
});

type UserFormValues = z.infer<typeof userFormSchema>;

interface UserFormProps {
  defaultValues?: Partial<UserFormValues>;
  onSubmit: (data: UserFormValues) => Promise<void>;
  submitLabel?: string;
}

export function UserForm({
  defaultValues,
  onSubmit,
  submitLabel = 'Save',
}: UserFormProps) {
  const form = useForm<UserFormValues>({
    resolver: zodResolver(userFormSchema),
    defaultValues: {
      name: '',
      email: '',
      bio: '',
      ...defaultValues,
    },
  });

  const handleSubmit = async (data: UserFormValues) => {
    try {
      await onSubmit(data);
      toast.success('User saved successfully');
    } catch (error) {
      toast.error('Failed to save user');
    }
  };

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(handleSubmit)} className="space-y-4">
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Name</FormLabel>
              <FormControl>
                <Input placeholder="John Doe" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email</FormLabel>
              <FormControl>
                <Input
                  type="email"
                  placeholder="john@example.com"
                  {...field}
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="bio"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Bio (optional)</FormLabel>
              <FormControl>
                <Input placeholder="Tell us about yourself" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <Button
          type="submit"
          disabled={form.formState.isSubmitting}
        >
          {form.formState.isSubmitting ? 'Saving...' : submitLabel}
        </Button>
      </form>
    </Form>
  );
}
```

## Compound Components

```typescript
// components/tabs/index.tsx
'use client';

import { createContext, useContext, useState } from 'react';
import { cn } from '@/lib/utils';

interface TabsContextValue {
  activeTab: string;
  setActiveTab: (tab: string) => void;
}

const TabsContext = createContext<TabsContextValue | null>(null);

function useTabsContext() {
  const context = useContext(TabsContext);
  if (!context) {
    throw new Error('Tabs components must be used within a Tabs provider');
  }
  return context;
}

interface TabsProps {
  defaultValue: string;
  children: React.ReactNode;
  className?: string;
}

export function Tabs({ defaultValue, children, className }: TabsProps) {
  const [activeTab, setActiveTab] = useState(defaultValue);

  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      <div className={cn('w-full', className)}>{children}</div>
    </TabsContext.Provider>
  );
}

interface TabsListProps {
  children: React.ReactNode;
  className?: string;
}

export function TabsList({ children, className }: TabsListProps) {
  return (
    <div
      className={cn(
        'inline-flex items-center justify-center rounded-lg bg-muted p-1',
        className,
      )}
      role="tablist"
    >
      {children}
    </div>
  );
}

interface TabsTriggerProps {
  value: string;
  children: React.ReactNode;
  className?: string;
}

export function TabsTrigger({ value, children, className }: TabsTriggerProps) {
  const { activeTab, setActiveTab } = useTabsContext();
  const isActive = activeTab === value;

  return (
    <button
      type="button"
      role="tab"
      aria-selected={isActive}
      className={cn(
        'inline-flex items-center justify-center whitespace-nowrap rounded-md px-3 py-1.5 text-sm font-medium ring-offset-background transition-all',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2',
        'disabled:pointer-events-none disabled:opacity-50',
        isActive && 'bg-background shadow-sm',
        className,
      )}
      onClick={() => setActiveTab(value)}
    >
      {children}
    </button>
  );
}

interface TabsContentProps {
  value: string;
  children: React.ReactNode;
  className?: string;
}

export function TabsContent({ value, children, className }: TabsContentProps) {
  const { activeTab } = useTabsContext();

  if (activeTab !== value) {
    return null;
  }

  return (
    <div
      role="tabpanel"
      className={cn('mt-2 ring-offset-background', className)}
    >
      {children}
    </div>
  );
}
```

## Polymorphic Component

```typescript
// components/box.tsx
import { cn } from '@/lib/utils';

type BoxProps<E extends React.ElementType = 'div'> = {
  as?: E;
  children?: React.ReactNode;
  className?: string;
} & Omit<React.ComponentPropsWithoutRef<E>, 'as' | 'className'>;

export function Box<E extends React.ElementType = 'div'>({
  as,
  children,
  className,
  ...props
}: BoxProps<E>) {
  const Component = as || 'div';

  return (
    <Component className={cn(className)} {...props}>
      {children}
    </Component>
  );
}

// Usage
<Box as="section" className="container">Content</Box>
<Box as="button" onClick={handleClick}>Click me</Box>
<Box as="a" href="/about">About</Box>
```

## ForwardRef Component

```typescript
// components/input.tsx
import * as React from 'react';
import { cn } from '@/lib/utils';

export interface InputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, label, error, leftIcon, rightIcon, ...props }, ref) => {
    const id = React.useId();

    return (
      <div className="w-full">
        {label && (
          <label
            htmlFor={id}
            className="mb-1 block text-sm font-medium"
          >
            {label}
          </label>
        )}
        <div className="relative">
          {leftIcon && (
            <div className="absolute left-3 top-1/2 -translate-y-1/2">
              {leftIcon}
            </div>
          )}
          <input
            id={id}
            type={type}
            ref={ref}
            className={cn(
              'flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm',
              'ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium',
              'placeholder:text-muted-foreground',
              'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2',
              'disabled:cursor-not-allowed disabled:opacity-50',
              leftIcon && 'pl-10',
              rightIcon && 'pr-10',
              error && 'border-destructive',
              className,
            )}
            aria-invalid={error ? 'true' : undefined}
            aria-describedby={error ? `${id}-error` : undefined}
            {...props}
          />
          {rightIcon && (
            <div className="absolute right-3 top-1/2 -translate-y-1/2">
              {rightIcon}
            </div>
          )}
        </div>
        {error && (
          <p id={`${id}-error`} className="mt-1 text-sm text-destructive">
            {error}
          </p>
        )}
      </div>
    );
  },
);

Input.displayName = 'Input';

export { Input };
```

## Loading and Error States

```typescript
// components/data-display.tsx
'use client';

import { api } from '@/trpc/react';
import { Skeleton } from '@/components/ui/skeleton';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { RefreshCw, AlertCircle } from 'lucide-react';

interface DataDisplayProps {
  userId: string;
}

export function DataDisplay({ userId }: DataDisplayProps) {
  const {
    data: user,
    isLoading,
    isError,
    error,
    refetch,
  } = api.user.getById.useQuery({ id: userId });

  // Loading state
  if (isLoading) {
    return (
      <div className="space-y-3">
        <Skeleton className="h-4 w-[250px]" />
        <Skeleton className="h-4 w-[200px]" />
        <Skeleton className="h-4 w-[150px]" />
      </div>
    );
  }

  // Error state
  if (isError) {
    return (
      <Alert variant="destructive">
        <AlertCircle className="h-4 w-4" />
        <AlertDescription className="flex items-center justify-between">
          <span>{error.message}</span>
          <Button
            variant="outline"
            size="sm"
            onClick={() => refetch()}
          >
            <RefreshCw className="mr-2 h-4 w-4" />
            Retry
          </Button>
        </AlertDescription>
      </Alert>
    );
  }

  // Empty state
  if (!user) {
    return (
      <div className="text-center py-8 text-muted-foreground">
        User not found
      </div>
    );
  }

  // Success state
  return (
    <div className="space-y-2">
      <h2 className="text-xl font-semibold">{user.name}</h2>
      <p className="text-muted-foreground">{user.email}</p>
    </div>
  );
}
```

## Best Practices

### Do

- Use Server Components by default (no 'use client')
- Add 'use client' only when needed (hooks, event handlers)
- Use TypeScript for all props
- Include proper accessibility attributes
- Handle loading, error, and empty states
- Use composition over complex props
- Extract reusable logic to custom hooks
- Use forwardRef for input components

### Don't

- Add 'use client' unnecessarily
- Use `any` type for props
- Forget error boundaries
- Skip accessibility attributes
- Create deeply nested component trees
- Mix concerns in single components
- Use inline styles (use cn/className)
- Forget loading states for async operations

## Component Checklist

- [ ] TypeScript props interface defined
- [ ] Proper default values for optional props
- [ ] className prop supported for styling flexibility
- [ ] Accessibility attributes (aria-*, role)
- [ ] Keyboard navigation (if interactive)
- [ ] Loading state handled
- [ ] Error state handled
- [ ] Empty state handled
- [ ] forwardRef used (if wrapping native element)
- [ ] displayName set (if using forwardRef)
