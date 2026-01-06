---
name: Logging
category: core
language: any
framework: none
keywords: [logging, debug, trace, monitoring, observability, structured-logging]
confidence: 0.85
---

# Logging Pattern

## Problem

Without consistent logging:
- Debugging production issues becomes guesswork
- No visibility into system behavior
- Security incidents go undetected
- Performance problems are hard to diagnose

## Solution

Implement structured logging with consistent levels, context propagation, and machine-readable format for easy querying and alerting.

## Implementation

### Logger Setup

```typescript
// lib/logger.ts

type LogLevel = 'debug' | 'info' | 'warn' | 'error';

interface LogContext {
  requestId?: string;
  userId?: string;
  traceId?: string;
  [key: string]: unknown;
}

interface LogEntry {
  timestamp: string;
  level: LogLevel;
  message: string;
  context?: LogContext;
  error?: {
    name: string;
    message: string;
    stack?: string;
  };
}

class Logger {
  private context: LogContext = {};

  constructor(private defaultContext: LogContext = {}) {
    this.context = defaultContext;
  }

  child(context: LogContext): Logger {
    return new Logger({ ...this.context, ...context });
  }

  private log(level: LogLevel, message: string, context?: LogContext): void {
    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level,
      message,
      context: { ...this.context, ...context },
    };

    // In production, send to logging service
    // In development, format for readability
    if (process.env.NODE_ENV === 'production') {
      console.log(JSON.stringify(entry));
    } else {
      console[level](`[${entry.level.toUpperCase()}] ${message}`, entry.context);
    }
  }

  debug(message: string, context?: LogContext): void {
    if (process.env.LOG_LEVEL === 'debug') {
      this.log('debug', message, context);
    }
  }

  info(message: string, context?: LogContext): void {
    this.log('info', message, context);
  }

  warn(message: string, context?: LogContext): void {
    this.log('warn', message, context);
  }

  error(message: string, error?: unknown, context?: LogContext): void {
    const errorDetails = error instanceof Error
      ? { name: error.name, message: error.message, stack: error.stack }
      : { message: String(error) };

    this.log('error', message, {
      ...context,
      error: errorDetails,
    });
  }
}

export const logger = new Logger();
```

### Request Context Logging

```typescript
// middleware.ts or lib/request-context.ts
import { AsyncLocalStorage } from 'async_hooks';
import { nanoid } from 'nanoid';

interface RequestContext {
  requestId: string;
  userId?: string;
  traceId?: string;
  startTime: number;
}

export const requestContext = new AsyncLocalStorage<RequestContext>();

export function withRequestContext<T>(
  fn: () => T | Promise<T>,
  context?: Partial<RequestContext>,
): T | Promise<T> {
  return requestContext.run(
    {
      requestId: nanoid(),
      startTime: Date.now(),
      ...context,
    },
    fn,
  );
}

// Get context-aware logger
export function getLogger() {
  const ctx = requestContext.getStore();
  return logger.child({
    requestId: ctx?.requestId,
    userId: ctx?.userId,
    traceId: ctx?.traceId,
  });
}
```

### Usage in API Routes

```typescript
// app/api/users/route.ts
import { getLogger, withRequestContext } from '@/lib/request-context';

export async function POST(request: Request) {
  return withRequestContext(async () => {
    const log = getLogger();

    log.info('Creating user');

    try {
      const body = await request.json();
      log.debug('Request body received', { email: body.email });

      const user = await createUser(body);
      log.info('User created', { userId: user.id });

      return Response.json({ data: user });
    } catch (error) {
      log.error('Failed to create user', error);
      throw error;
    }
  });
}
```

### Logging Best Practices by Level

```typescript
// DEBUG - Detailed information for diagnosing issues
log.debug('Cache lookup', { key, hit: !!value });
log.debug('Database query', { sql, params, duration: '23ms' });

// INFO - Notable events that should be recorded
log.info('User logged in', { userId, method: 'password' });
log.info('Order completed', { orderId, total, items: 3 });
log.info('Email sent', { to: 'user@example.com', template: 'welcome' });

// WARN - Potentially harmful situations
log.warn('Rate limit approaching', { userId, requests: 95, limit: 100 });
log.warn('Deprecated API endpoint called', { endpoint, replacement });
log.warn('Slow query detected', { query, duration: '5200ms' });

// ERROR - Errors that need attention
log.error('Payment processing failed', error, { orderId, amount });
log.error('External API unavailable', error, { service: 'stripe', retries: 3 });
log.error('Database connection lost', error);
```

## When to Use

- Application startup/shutdown
- Request/response lifecycle
- Business events (user actions, transactions)
- Error conditions
- Performance metrics
- Security events (auth attempts, permission changes)

## Anti-patterns

```typescript
// BAD: Logging sensitive data
log.info('User login', { email, password }); // Never log passwords!

// BAD: Unstructured logging
console.log('Error: ' + error.message); // Not machine-parseable

// BAD: Logging without context
log.error('Failed'); // What failed? Where?

// BAD: Excessive logging in loops
for (const item of items) {
  log.debug('Processing item', { item }); // May generate millions of logs
}

// BAD: Using wrong log levels
log.error('User not found'); // Not an error, use info or debug
log.info('Database connection failed'); // This IS an error
```

```typescript
// GOOD: Sanitize sensitive data
log.info('User login', { email, passwordProvided: !!password });

// GOOD: Structured with context
log.error('Payment failed', error, {
  orderId,
  amount,
  provider: 'stripe',
  requestId,
});

// GOOD: Batch logging for loops
log.info('Processing batch', { count: items.length });
const results = await processAll(items);
log.info('Batch complete', {
  success: results.filter(r => r.ok).length,
  failed: results.filter(r => !r.ok).length,
});

// GOOD: Appropriate levels
log.info('User not found', { userId });
log.error('Database connection failed', error);
```

## Related Patterns

- Error Handling Pattern - For what to log when errors occur
- Configuration Pattern - For log level configuration
- Webhook Handler Pattern - For logging external events
