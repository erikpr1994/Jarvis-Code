---
name: Configuration
category: core
language: typescript
framework: none
keywords: [config, environment, env, settings, secrets, configuration]
confidence: 0.85
---

# Configuration Pattern

## Problem

Without proper configuration management:
- Secrets leak into code or version control
- Environment-specific settings are hardcoded
- Configuration errors crash applications at runtime
- No validation of required settings

## Solution

Centralize configuration with environment variables, validate at startup, and provide type-safe access throughout the application.

## Implementation

### Environment Variable Schema

```typescript
// lib/config.ts
import { z } from 'zod';

// Define schema for all environment variables
const envSchema = z.object({
  // App
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().default(3000),

  // Database
  DATABASE_URL: z.string().url(),
  DATABASE_POOL_SIZE: z.coerce.number().min(1).max(100).default(10),

  // Authentication
  JWT_SECRET: z.string().min(32),
  JWT_EXPIRES_IN: z.string().default('7d'),

  // External Services
  STRIPE_SECRET_KEY: z.string().startsWith('sk_'),
  STRIPE_WEBHOOK_SECRET: z.string().startsWith('whsec_'),

  // Optional services
  REDIS_URL: z.string().url().optional(),
  SENTRY_DSN: z.string().url().optional(),

  // Feature flags
  ENABLE_ANALYTICS: z.coerce.boolean().default(false),
  ENABLE_NEW_CHECKOUT: z.coerce.boolean().default(false),
});

// Parse and validate at module load
function loadConfig() {
  const result = envSchema.safeParse(process.env);

  if (!result.success) {
    console.error('Invalid environment variables:');
    console.error(result.error.format());
    throw new Error('Configuration validation failed');
  }

  return result.data;
}

// Export typed config object
export const config = loadConfig();

// Export type for use elsewhere
export type Config = z.infer<typeof envSchema>;
```

### Environment-Specific Configuration

```typescript
// lib/config.ts (extended)

interface AppConfig {
  isProduction: boolean;
  isDevelopment: boolean;
  isTest: boolean;

  api: {
    baseUrl: string;
    timeout: number;
    retries: number;
  };

  database: {
    url: string;
    poolSize: number;
    logging: boolean;
  };

  cache: {
    enabled: boolean;
    ttl: number;
  };

  features: {
    analytics: boolean;
    newCheckout: boolean;
  };
}

function buildConfig(env: z.infer<typeof envSchema>): AppConfig {
  const isProduction = env.NODE_ENV === 'production';
  const isDevelopment = env.NODE_ENV === 'development';
  const isTest = env.NODE_ENV === 'test';

  return {
    isProduction,
    isDevelopment,
    isTest,

    api: {
      baseUrl: isProduction
        ? 'https://api.production.com'
        : 'http://localhost:3000',
      timeout: isProduction ? 30000 : 60000,
      retries: isProduction ? 3 : 0,
    },

    database: {
      url: env.DATABASE_URL,
      poolSize: env.DATABASE_POOL_SIZE,
      logging: isDevelopment,
    },

    cache: {
      enabled: !!env.REDIS_URL,
      ttl: isProduction ? 3600 : 60,
    },

    features: {
      analytics: env.ENABLE_ANALYTICS,
      newCheckout: env.ENABLE_NEW_CHECKOUT,
    },
  };
}

export const appConfig = buildConfig(loadConfig());
```

### Server-Only Configuration

```typescript
// lib/config.server.ts
import 'server-only'; // Next.js - prevents client bundle inclusion

import { z } from 'zod';

const serverEnvSchema = z.object({
  // Secrets that should NEVER reach the client
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  STRIPE_SECRET_KEY: z.string(),
  API_KEYS: z.string().transform((s) => s.split(',')),
});

export const serverConfig = serverEnvSchema.parse(process.env);
```

### Client-Safe Configuration

```typescript
// lib/config.client.ts
import { z } from 'zod';

// Only NEXT_PUBLIC_ prefixed variables
const clientEnvSchema = z.object({
  NEXT_PUBLIC_API_URL: z.string().url(),
  NEXT_PUBLIC_STRIPE_PUBLIC_KEY: z.string().startsWith('pk_'),
  NEXT_PUBLIC_ANALYTICS_ID: z.string().optional(),
});

export const clientConfig = clientEnvSchema.parse({
  NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
  NEXT_PUBLIC_STRIPE_PUBLIC_KEY: process.env.NEXT_PUBLIC_STRIPE_PUBLIC_KEY,
  NEXT_PUBLIC_ANALYTICS_ID: process.env.NEXT_PUBLIC_ANALYTICS_ID,
});
```

### Feature Flags

```typescript
// lib/features.ts
import { config } from './config';

export const features = {
  analytics: config.ENABLE_ANALYTICS,
  newCheckout: config.ENABLE_NEW_CHECKOUT,

  // Complex feature flags with conditions
  betaFeatures: config.NODE_ENV === 'development' ||
                process.env.ENABLE_BETA === 'true',
} as const;

// Type-safe feature check
export function isFeatureEnabled(feature: keyof typeof features): boolean {
  return features[feature];
}

// Usage
if (isFeatureEnabled('newCheckout')) {
  // New checkout flow
}
```

### Environment Files

```bash
# .env.example (commit this)
NODE_ENV=development
PORT=3000

DATABASE_URL=postgresql://user:pass@localhost:5432/mydb
DATABASE_POOL_SIZE=10

JWT_SECRET=your-secret-key-at-least-32-characters-long
JWT_EXPIRES_IN=7d

STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# Optional
REDIS_URL=
SENTRY_DSN=

# Feature flags
ENABLE_ANALYTICS=false
ENABLE_NEW_CHECKOUT=false
```

```bash
# .env.local (do NOT commit)
DATABASE_URL=postgresql://user:realpass@localhost:5432/mydb
JWT_SECRET=real-secret-key-do-not-commit-this-to-git
STRIPE_SECRET_KEY=sk_test_real_key
```

```gitignore
# .gitignore
.env
.env.local
.env.*.local
```

## When to Use

- All environment-specific settings
- API keys and secrets
- Feature flags
- External service URLs
- Database connection strings
- Any value that changes between environments

## Anti-patterns

```typescript
// BAD: Hardcoded secrets
const apiKey = 'sk_live_abc123'; // In code!

// BAD: Accessing process.env directly throughout codebase
const dbUrl = process.env.DATABASE_URL; // Unvalidated, untyped

// BAD: No validation
const port = parseInt(process.env.PORT); // Could be NaN

// BAD: Secrets in client code
export const config = {
  stripeSecretKey: process.env.STRIPE_SECRET_KEY, // Exposes to client!
};

// BAD: Committing .env files
// git add .env # NEVER DO THIS
```

```typescript
// GOOD: Centralized, validated config
import { config } from '@/lib/config';
const port = config.PORT; // Typed as number, validated

// GOOD: Server-only for secrets
import { serverConfig } from '@/lib/config.server';
// This import fails if used in client code

// GOOD: Public config for client
import { clientConfig } from '@/lib/config.client';
// Only NEXT_PUBLIC_ prefixed variables

// GOOD: Fail fast on missing config
function loadConfig() {
  const result = schema.safeParse(process.env);
  if (!result.success) {
    throw new Error('Missing configuration'); // App won't start
  }
}
```

## Related Patterns

- Validation Pattern - For validating configuration
- Error Handling Pattern - For configuration errors
- Logging Pattern - For logging configuration at startup
