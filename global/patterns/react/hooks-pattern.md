---
name: React Hooks Pattern
category: framework
language: typescript
framework: react
keywords: [react, hooks, custom-hooks, state, useEffect, useState]
confidence: 0.9
---

# React Hooks Pattern

## Problem

Component logic becomes repetitive and hard to share:
- Same data fetching logic duplicated
- Complex state management in components
- Event listeners scattered throughout
- Business logic mixed with UI

## Solution

Extract reusable logic into custom hooks that encapsulate state, effects, and behavior. Keep hooks focused and composable.

## Implementation

### Basic Custom Hook

```typescript
// hooks/use-local-storage.ts
import { useState, useEffect, useCallback } from 'react';

export function useLocalStorage<T>(
  key: string,
  initialValue: T,
): [T, (value: T | ((prev: T) => T)) => void, () => void] {
  // Initialize from localStorage or default
  const [storedValue, setStoredValue] = useState<T>(() => {
    if (typeof window === 'undefined') {
      return initialValue;
    }
    try {
      const item = window.localStorage.getItem(key);
      return item ? (JSON.parse(item) as T) : initialValue;
    } catch (error) {
      console.error(`Error reading localStorage key "${key}":`, error);
      return initialValue;
    }
  });

  // Update localStorage when state changes
  useEffect(() => {
    try {
      window.localStorage.setItem(key, JSON.stringify(storedValue));
    } catch (error) {
      console.error(`Error setting localStorage key "${key}":`, error);
    }
  }, [key, storedValue]);

  // Clear storage
  const clear = useCallback(() => {
    setStoredValue(initialValue);
    window.localStorage.removeItem(key);
  }, [key, initialValue]);

  return [storedValue, setStoredValue, clear];
}

// Usage
function Settings() {
  const [theme, setTheme] = useLocalStorage('theme', 'light');
  return (
    <select value={theme} onChange={(e) => setTheme(e.target.value)}>
      <option value="light">Light</option>
      <option value="dark">Dark</option>
    </select>
  );
}
```

### Data Fetching Hook

```typescript
// hooks/use-async.ts
import { useState, useCallback, useEffect } from 'react';

interface AsyncState<T> {
  data: T | null;
  error: Error | null;
  isLoading: boolean;
  isError: boolean;
  isSuccess: boolean;
}

export function useAsync<T>(
  asyncFn: () => Promise<T>,
  deps: React.DependencyList = [],
): AsyncState<T> & { execute: () => Promise<void>; reset: () => void } {
  const [state, setState] = useState<AsyncState<T>>({
    data: null,
    error: null,
    isLoading: false,
    isError: false,
    isSuccess: false,
  });

  const execute = useCallback(async () => {
    setState((prev) => ({
      ...prev,
      isLoading: true,
      error: null,
    }));

    try {
      const data = await asyncFn();
      setState({
        data,
        error: null,
        isLoading: false,
        isError: false,
        isSuccess: true,
      });
    } catch (error) {
      setState({
        data: null,
        error: error instanceof Error ? error : new Error(String(error)),
        isLoading: false,
        isError: true,
        isSuccess: false,
      });
    }
  }, deps);

  const reset = useCallback(() => {
    setState({
      data: null,
      error: null,
      isLoading: false,
      isError: false,
      isSuccess: false,
    });
  }, []);

  return { ...state, execute, reset };
}

// Usage
function UserList() {
  const { data: users, isLoading, error, execute } = useAsync(
    () => fetch('/api/users').then((r) => r.json()),
    [],
  );

  useEffect(() => {
    execute();
  }, [execute]);

  if (isLoading) return <Spinner />;
  if (error) return <Error message={error.message} onRetry={execute} />;
  return <UserTable users={users} />;
}
```

### Debounced Value Hook

```typescript
// hooks/use-debounce.ts
import { useState, useEffect } from 'react';

export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => {
      clearTimeout(timer);
    };
  }, [value, delay]);

  return debouncedValue;
}

// Usage
function Search() {
  const [query, setQuery] = useState('');
  const debouncedQuery = useDebounce(query, 300);

  useEffect(() => {
    if (debouncedQuery) {
      searchApi(debouncedQuery);
    }
  }, [debouncedQuery]);

  return (
    <input
      value={query}
      onChange={(e) => setQuery(e.target.value)}
      placeholder="Search..."
    />
  );
}
```

### Event Listener Hook

```typescript
// hooks/use-event-listener.ts
import { useEffect, useRef } from 'react';

export function useEventListener<K extends keyof WindowEventMap>(
  eventName: K,
  handler: (event: WindowEventMap[K]) => void,
  element: HTMLElement | Window = window,
): void {
  // Store handler in ref to avoid effect re-runs
  const savedHandler = useRef(handler);

  useEffect(() => {
    savedHandler.current = handler;
  }, [handler]);

  useEffect(() => {
    const eventListener = (event: WindowEventMap[K]) => {
      savedHandler.current(event);
    };

    element.addEventListener(eventName, eventListener as EventListener);

    return () => {
      element.removeEventListener(eventName, eventListener as EventListener);
    };
  }, [eventName, element]);
}

// Usage
function ClickCounter() {
  const [count, setCount] = useState(0);

  useEventListener('click', () => {
    setCount((c) => c + 1);
  });

  return <p>Document clicks: {count}</p>;
}
```

### Media Query Hook

```typescript
// hooks/use-media-query.ts
import { useState, useEffect } from 'react';

export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(false);

  useEffect(() => {
    const mediaQuery = window.matchMedia(query);
    setMatches(mediaQuery.matches);

    const handler = (event: MediaQueryListEvent) => {
      setMatches(event.matches);
    };

    mediaQuery.addEventListener('change', handler);
    return () => mediaQuery.removeEventListener('change', handler);
  }, [query]);

  return matches;
}

// Convenience hooks
export function useIsMobile(): boolean {
  return useMediaQuery('(max-width: 768px)');
}

export function usePrefersDarkMode(): boolean {
  return useMediaQuery('(prefers-color-scheme: dark)');
}

// Usage
function ResponsiveNav() {
  const isMobile = useIsMobile();
  return isMobile ? <MobileNav /> : <DesktopNav />;
}
```

### Form Hook

```typescript
// hooks/use-form.ts
import { useState, useCallback, ChangeEvent, FormEvent } from 'react';

interface UseFormOptions<T> {
  initialValues: T;
  onSubmit: (values: T) => Promise<void> | void;
  validate?: (values: T) => Partial<Record<keyof T, string>>;
}

export function useForm<T extends Record<string, any>>({
  initialValues,
  onSubmit,
  validate,
}: UseFormOptions<T>) {
  const [values, setValues] = useState<T>(initialValues);
  const [errors, setErrors] = useState<Partial<Record<keyof T, string>>>({});
  const [touched, setTouched] = useState<Partial<Record<keyof T, boolean>>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleChange = useCallback(
    (e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
      const { name, value, type } = e.target;
      const newValue = type === 'checkbox'
        ? (e.target as HTMLInputElement).checked
        : value;

      setValues((prev) => ({ ...prev, [name]: newValue }));

      // Clear error on change
      if (errors[name as keyof T]) {
        setErrors((prev) => ({ ...prev, [name]: undefined }));
      }
    },
    [errors],
  );

  const handleBlur = useCallback(
    (e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
      const { name } = e.target;
      setTouched((prev) => ({ ...prev, [name]: true }));

      // Validate on blur
      if (validate) {
        const fieldErrors = validate(values);
        if (fieldErrors[name as keyof T]) {
          setErrors((prev) => ({
            ...prev,
            [name]: fieldErrors[name as keyof T],
          }));
        }
      }
    },
    [values, validate],
  );

  const handleSubmit = useCallback(
    async (e: FormEvent) => {
      e.preventDefault();

      // Validate all fields
      if (validate) {
        const validationErrors = validate(values);
        setErrors(validationErrors);

        if (Object.keys(validationErrors).length > 0) {
          return;
        }
      }

      setIsSubmitting(true);
      try {
        await onSubmit(values);
      } finally {
        setIsSubmitting(false);
      }
    },
    [values, validate, onSubmit],
  );

  const reset = useCallback(() => {
    setValues(initialValues);
    setErrors({});
    setTouched({});
  }, [initialValues]);

  const setFieldValue = useCallback((name: keyof T, value: T[keyof T]) => {
    setValues((prev) => ({ ...prev, [name]: value }));
  }, []);

  return {
    values,
    errors,
    touched,
    isSubmitting,
    handleChange,
    handleBlur,
    handleSubmit,
    reset,
    setFieldValue,
    setValues,
    setErrors,
  };
}

// Usage
function LoginForm() {
  const form = useForm({
    initialValues: { email: '', password: '' },
    onSubmit: async (values) => {
      await login(values.email, values.password);
    },
    validate: (values) => {
      const errors: Record<string, string> = {};
      if (!values.email) errors.email = 'Email is required';
      if (!values.password) errors.password = 'Password is required';
      return errors;
    },
  });

  return (
    <form onSubmit={form.handleSubmit}>
      <input
        name="email"
        value={form.values.email}
        onChange={form.handleChange}
        onBlur={form.handleBlur}
      />
      {form.touched.email && form.errors.email && (
        <span className="error">{form.errors.email}</span>
      )}
      {/* ... */}
    </form>
  );
}
```

### Intersection Observer Hook

```typescript
// hooks/use-intersection-observer.ts
import { useState, useEffect, useRef, RefObject } from 'react';

interface UseIntersectionObserverOptions {
  threshold?: number | number[];
  root?: Element | null;
  rootMargin?: string;
  freezeOnceVisible?: boolean;
}

export function useIntersectionObserver(
  options: UseIntersectionObserverOptions = {},
): [RefObject<HTMLDivElement>, boolean] {
  const {
    threshold = 0,
    root = null,
    rootMargin = '0px',
    freezeOnceVisible = false,
  } = options;

  const ref = useRef<HTMLDivElement>(null);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    // Don't observe if frozen and already visible
    if (freezeOnceVisible && isVisible) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        setIsVisible(entry.isIntersecting);
      },
      { threshold, root, rootMargin },
    );

    observer.observe(element);

    return () => {
      observer.disconnect();
    };
  }, [threshold, root, rootMargin, freezeOnceVisible, isVisible]);

  return [ref, isVisible];
}

// Usage
function LazyImage({ src, alt }: { src: string; alt: string }) {
  const [ref, isVisible] = useIntersectionObserver({
    threshold: 0.1,
    freezeOnceVisible: true,
  });

  return (
    <div ref={ref}>
      {isVisible ? (
        <img src={src} alt={alt} />
      ) : (
        <div className="placeholder" />
      )}
    </div>
  );
}
```

## When to Use

- Reusable stateful logic
- Event handling abstraction
- Side effect encapsulation
- Browser API wrappers
- Form state management
- Animation logic

## Anti-patterns

```typescript
// BAD: Hook does too many things
function useEverything() {
  const [user, setUser] = useState();
  const [posts, setPosts] = useState();
  const [comments, setComments] = useState();
  // 200 lines of mixed concerns
}

// BAD: Unnecessary hook
function useConstant() {
  return 42; // Just use a constant
}

// BAD: Hook that could be a function
function useFormat(date: Date) {
  return date.toLocaleDateString(); // No state, no effects
}

// BAD: Missing dependencies
useEffect(() => {
  fetchUser(userId);
}, []); // userId missing from deps!

// BAD: Conditional hooks
if (condition) {
  const [state, setState] = useState(); // Violates rules of hooks
}
```

```typescript
// GOOD: Single responsibility
function useUser(id: string) { /* user fetching only */ }
function usePosts(userId: string) { /* posts fetching only */ }

// GOOD: Hooks have state/effects
function useDebounce(value: string, delay: number) {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => { /* ... */ }, [value, delay]);
  return debounced;
}

// GOOD: Correct dependencies
useEffect(() => {
  fetchUser(userId);
}, [userId]); // All deps listed

// GOOD: Unconditional hook calls
const user = useUser(condition ? userId : undefined);
```

## Related Patterns

- React Component Pattern - Where hooks are used
- Context Provider Pattern - For global state
- Error Handling Pattern - For error states in hooks
