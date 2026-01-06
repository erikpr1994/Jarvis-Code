---
name: Third-Party API Integration
category: integration
language: typescript
framework: none
keywords: [api, integration, fetch, http, client, external-service]
confidence: 0.85
---

# Third-Party API Integration Pattern

## Problem

Integrating with external APIs introduces:
- Network failures and timeouts
- Rate limiting
- Inconsistent response formats
- Authentication complexity
- Testing difficulties

## Solution

Create typed API clients with proper error handling, retries, rate limiting, and circuit breakers.

## Implementation

### Typed API Client

```typescript
// lib/api-client.ts

interface ApiClientConfig {
  baseUrl: string;
  apiKey?: string;
  timeout?: number;
  retries?: number;
}

interface RequestOptions extends RequestInit {
  params?: Record<string, string | number | boolean>;
  timeout?: number;
}

export class ApiClient {
  private baseUrl: string;
  private apiKey?: string;
  private timeout: number;
  private retries: number;

  constructor(config: ApiClientConfig) {
    this.baseUrl = config.baseUrl;
    this.apiKey = config.apiKey;
    this.timeout = config.timeout ?? 30000;
    this.retries = config.retries ?? 3;
  }

  private async request<T>(
    path: string,
    options: RequestOptions = {},
  ): Promise<T> {
    const url = new URL(path, this.baseUrl);

    // Add query parameters
    if (options.params) {
      Object.entries(options.params).forEach(([key, value]) => {
        url.searchParams.set(key, String(value));
      });
    }

    const headers = new Headers(options.headers);
    headers.set('Content-Type', 'application/json');

    if (this.apiKey) {
      headers.set('Authorization', `Bearer ${this.apiKey}`);
    }

    const controller = new AbortController();
    const timeout = setTimeout(
      () => controller.abort(),
      options.timeout ?? this.timeout,
    );

    let lastError: Error | null = null;

    for (let attempt = 0; attempt < this.retries; attempt++) {
      try {
        const response = await fetch(url.toString(), {
          ...options,
          headers,
          signal: controller.signal,
        });

        clearTimeout(timeout);

        if (!response.ok) {
          const error = await this.parseError(response);
          throw error;
        }

        return (await response.json()) as T;
      } catch (error) {
        lastError = error as Error;

        // Don't retry on client errors (4xx)
        if (
          error instanceof ApiError &&
          error.status >= 400 &&
          error.status < 500
        ) {
          throw error;
        }

        // Wait before retry with exponential backoff
        if (attempt < this.retries - 1) {
          await this.delay(Math.pow(2, attempt) * 1000);
        }
      }
    }

    throw lastError;
  }

  private async parseError(response: Response): Promise<ApiError> {
    try {
      const body = await response.json();
      return new ApiError(
        response.status,
        body.message || body.error || 'Request failed',
        body.code,
      );
    } catch {
      return new ApiError(response.status, response.statusText);
    }
  }

  private delay(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  async get<T>(path: string, options?: RequestOptions): Promise<T> {
    return this.request<T>(path, { ...options, method: 'GET' });
  }

  async post<T>(path: string, data?: unknown, options?: RequestOptions): Promise<T> {
    return this.request<T>(path, {
      ...options,
      method: 'POST',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  async put<T>(path: string, data?: unknown, options?: RequestOptions): Promise<T> {
    return this.request<T>(path, {
      ...options,
      method: 'PUT',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  async delete<T>(path: string, options?: RequestOptions): Promise<T> {
    return this.request<T>(path, { ...options, method: 'DELETE' });
  }
}

export class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
    public code?: string,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}
```

### Service-Specific Client

```typescript
// lib/stripe-client.ts
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2023-10-16',
  typescript: true,
});

export const stripeClient = {
  async createCustomer(email: string, name?: string) {
    return stripe.customers.create({ email, name });
  },

  async createCheckoutSession(params: {
    customerId: string;
    priceId: string;
    successUrl: string;
    cancelUrl: string;
  }) {
    return stripe.checkout.sessions.create({
      customer: params.customerId,
      line_items: [{ price: params.priceId, quantity: 1 }],
      mode: 'subscription',
      success_url: params.successUrl,
      cancel_url: params.cancelUrl,
    });
  },

  async getSubscription(subscriptionId: string) {
    return stripe.subscriptions.retrieve(subscriptionId);
  },

  async cancelSubscription(subscriptionId: string) {
    return stripe.subscriptions.cancel(subscriptionId);
  },
};
```

### Rate-Limited Client

```typescript
// lib/rate-limited-client.ts

interface RateLimitConfig {
  maxRequests: number;
  windowMs: number;
}

class RateLimiter {
  private requests: number[] = [];
  private maxRequests: number;
  private windowMs: number;

  constructor(config: RateLimitConfig) {
    this.maxRequests = config.maxRequests;
    this.windowMs = config.windowMs;
  }

  async acquire(): Promise<void> {
    const now = Date.now();

    // Remove old requests outside the window
    this.requests = this.requests.filter(
      (time) => now - time < this.windowMs,
    );

    if (this.requests.length >= this.maxRequests) {
      // Wait until oldest request expires
      const oldestRequest = this.requests[0];
      const waitTime = this.windowMs - (now - oldestRequest);
      await new Promise((resolve) => setTimeout(resolve, waitTime));
      return this.acquire(); // Retry
    }

    this.requests.push(now);
  }
}

export class RateLimitedApiClient extends ApiClient {
  private rateLimiter: RateLimiter;

  constructor(config: ApiClientConfig & { rateLimit: RateLimitConfig }) {
    super(config);
    this.rateLimiter = new RateLimiter(config.rateLimit);
  }

  protected async request<T>(
    path: string,
    options: RequestOptions = {},
  ): Promise<T> {
    await this.rateLimiter.acquire();
    return super.request<T>(path, options);
  }
}

// Usage
const githubClient = new RateLimitedApiClient({
  baseUrl: 'https://api.github.com',
  apiKey: process.env.GITHUB_TOKEN,
  rateLimit: {
    maxRequests: 5000, // GitHub rate limit
    windowMs: 60 * 60 * 1000, // per hour
  },
});
```

### Circuit Breaker Pattern

```typescript
// lib/circuit-breaker.ts

type CircuitState = 'closed' | 'open' | 'half-open';

interface CircuitBreakerConfig {
  failureThreshold: number;
  successThreshold: number;
  timeout: number;
}

class CircuitBreaker {
  private state: CircuitState = 'closed';
  private failures = 0;
  private successes = 0;
  private lastFailure: number | null = null;
  private config: CircuitBreakerConfig;

  constructor(config: CircuitBreakerConfig) {
    this.config = config;
  }

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === 'open') {
      // Check if timeout has passed
      if (
        this.lastFailure &&
        Date.now() - this.lastFailure > this.config.timeout
      ) {
        this.state = 'half-open';
      } else {
        throw new Error('Circuit breaker is open');
      }
    }

    try {
      const result = await fn();

      if (this.state === 'half-open') {
        this.successes++;
        if (this.successes >= this.config.successThreshold) {
          this.reset();
        }
      }

      return result;
    } catch (error) {
      this.handleFailure();
      throw error;
    }
  }

  private handleFailure(): void {
    this.failures++;
    this.lastFailure = Date.now();

    if (this.state === 'half-open') {
      this.state = 'open';
    } else if (this.failures >= this.config.failureThreshold) {
      this.state = 'open';
    }
  }

  private reset(): void {
    this.state = 'closed';
    this.failures = 0;
    this.successes = 0;
    this.lastFailure = null;
  }

  getState(): CircuitState {
    return this.state;
  }
}

// Usage with API client
const circuitBreaker = new CircuitBreaker({
  failureThreshold: 5,
  successThreshold: 2,
  timeout: 30000,
});

async function fetchExternalData(): Promise<Data> {
  return circuitBreaker.execute(async () => {
    return apiClient.get<Data>('/data');
  });
}
```

### Caching API Responses

```typescript
// lib/cached-client.ts
import { unstable_cache } from 'next/cache';

// Next.js built-in caching
export const getCachedUser = unstable_cache(
  async (userId: string) => {
    return externalApi.get<User>(`/users/${userId}`);
  },
  ['external-user'],
  {
    revalidate: 60, // Cache for 60 seconds
    tags: ['users'],
  },
);

// Manual caching with Redis
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL);

async function cachedFetch<T>(
  key: string,
  fetcher: () => Promise<T>,
  ttlSeconds: number = 300,
): Promise<T> {
  // Try cache first
  const cached = await redis.get(key);
  if (cached) {
    return JSON.parse(cached) as T;
  }

  // Fetch and cache
  const data = await fetcher();
  await redis.setex(key, ttlSeconds, JSON.stringify(data));

  return data;
}

// Usage
const user = await cachedFetch(
  `user:${userId}`,
  () => externalApi.get<User>(`/users/${userId}`),
  300, // 5 minutes
);
```

## When to Use

- Payment providers (Stripe, PayPal)
- Email services (SendGrid, Resend)
- Cloud storage (S3, Cloudinary)
- Social APIs (Twitter, GitHub)
- Any external HTTP API

## Anti-patterns

```typescript
// BAD: No error handling
const data = await fetch(url).then(r => r.json());

// BAD: Hardcoded credentials
const client = new ApiClient('https://api.example.com', 'sk_live_xxx');

// BAD: No timeout
await fetch(url); // May hang forever

// BAD: No retries
const data = await apiClient.get('/data');
// Network blip = failure

// BAD: Unbounded requests
await Promise.all(items.map(item => api.fetch(item)));
// Hits rate limits immediately
```

```typescript
// GOOD: Proper error handling
try {
  const data = await apiClient.get('/data');
} catch (error) {
  if (error instanceof ApiError && error.status === 404) {
    return null;
  }
  throw error;
}

// GOOD: Environment config
const client = new ApiClient({
  baseUrl: process.env.API_URL!,
  apiKey: process.env.API_KEY!,
});

// GOOD: Timeout and retries
const client = new ApiClient({
  timeout: 10000,
  retries: 3,
});

// GOOD: Rate limiting
const client = new RateLimitedApiClient({
  rateLimit: { maxRequests: 100, windowMs: 60000 },
});
```

## Related Patterns

- Error Handling Pattern - For API error handling
- Caching Strategy Pattern - For response caching
- Circuit Breaker Pattern - For failure protection
