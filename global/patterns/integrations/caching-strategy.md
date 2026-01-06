---
name: Caching Strategy
category: integration
language: typescript
framework: nextjs
keywords: [cache, redis, performance, invalidation, ttl, revalidation]
confidence: 0.85
---

# Caching Strategy Pattern

## Problem

Without caching:
- Every request hits the database
- External API calls are repeated
- Page loads are slow
- Costs increase with usage

## Solution

Implement multi-layer caching with proper invalidation strategies for different types of data.

## Implementation

### Next.js Built-in Caching

```typescript
// lib/data.ts
import { unstable_cache } from 'next/cache';
import { db } from './db';

// Cache database queries
export const getUser = unstable_cache(
  async (userId: string) => {
    return db.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        avatar: true,
      },
    });
  },
  ['user'],
  {
    revalidate: 60, // Revalidate every 60 seconds
    tags: ['users'],
  },
);

// Cache with dynamic tags
export const getPostsByUser = unstable_cache(
  async (userId: string) => {
    return db.post.findMany({
      where: { authorId: userId },
      orderBy: { createdAt: 'desc' },
      take: 10,
    });
  },
  ['posts-by-user'],
  {
    revalidate: 300,
    tags: ['posts', `user-posts-${userId}`],
  },
);

// Invalidation
import { revalidateTag, revalidatePath } from 'next/cache';

export async function createPost(data: CreatePostInput) {
  const post = await db.post.create({ data });

  // Invalidate relevant caches
  revalidateTag('posts');
  revalidateTag(`user-posts-${data.authorId}`);
  revalidatePath('/posts');

  return post;
}
```

### Request Memoization

```typescript
// lib/data.ts
import { cache } from 'react';
import { db } from './db';

// Deduplicate requests within a single render
export const getCurrentUser = cache(async () => {
  const session = await getSession();
  if (!session) return null;

  return db.user.findUnique({
    where: { id: session.user.id },
  });
});

// Usage - only one DB query even if called multiple times
async function Header() {
  const user = await getCurrentUser();
  // ...
}

async function Sidebar() {
  const user = await getCurrentUser(); // Same request, memoized
  // ...
}
```

### Redis Caching Layer

```typescript
// lib/cache.ts
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL!);

interface CacheOptions {
  ttl?: number; // Time to live in seconds
  tags?: string[];
}

export async function cacheGet<T>(key: string): Promise<T | null> {
  const data = await redis.get(key);
  return data ? JSON.parse(data) : null;
}

export async function cacheSet<T>(
  key: string,
  value: T,
  options: CacheOptions = {},
): Promise<void> {
  const { ttl = 3600, tags = [] } = options;

  await redis.setex(key, ttl, JSON.stringify(value));

  // Track tags for invalidation
  if (tags.length > 0) {
    await Promise.all(
      tags.map((tag) => redis.sadd(`tag:${tag}`, key)),
    );
  }
}

export async function cacheDelete(key: string): Promise<void> {
  await redis.del(key);
}

export async function cacheInvalidateTag(tag: string): Promise<void> {
  const keys = await redis.smembers(`tag:${tag}`);
  if (keys.length > 0) {
    await redis.del(...keys);
    await redis.del(`tag:${tag}`);
  }
}

// High-level cache wrapper
export async function cached<T>(
  key: string,
  fetcher: () => Promise<T>,
  options: CacheOptions = {},
): Promise<T> {
  // Try cache first
  const cached = await cacheGet<T>(key);
  if (cached !== null) {
    return cached;
  }

  // Fetch and cache
  const data = await fetcher();
  await cacheSet(key, data, options);

  return data;
}

// Usage
const user = await cached(
  `user:${userId}`,
  () => db.user.findUnique({ where: { id: userId } }),
  { ttl: 300, tags: ['users', `user:${userId}`] },
);
```

### API Response Caching

```typescript
// app/api/products/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { cached } from '@/lib/cache';
import { db } from '@/lib/db';

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const category = searchParams.get('category');
  const page = parseInt(searchParams.get('page') ?? '1');

  // Build cache key from request params
  const cacheKey = `products:${category || 'all'}:page:${page}`;

  const data = await cached(
    cacheKey,
    async () => {
      const [products, total] = await Promise.all([
        db.product.findMany({
          where: category ? { category } : undefined,
          skip: (page - 1) * 20,
          take: 20,
        }),
        db.product.count({
          where: category ? { category } : undefined,
        }),
      ]);

      return { products, total, page };
    },
    {
      ttl: 60,
      tags: ['products', category ? `category:${category}` : 'all-products'],
    },
  );

  return NextResponse.json(data, {
    headers: {
      'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=300',
    },
  });
}
```

### Stale-While-Revalidate Pattern

```typescript
// lib/swr-cache.ts
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL!);

interface SWROptions {
  staleTime: number; // Max age for fresh data
  maxAge: number; // Max age before eviction
}

interface CachedData<T> {
  data: T;
  timestamp: number;
}

export async function swrCached<T>(
  key: string,
  fetcher: () => Promise<T>,
  options: SWROptions,
): Promise<T> {
  const cached = await redis.get(key);
  const now = Date.now();

  if (cached) {
    const { data, timestamp } = JSON.parse(cached) as CachedData<T>;
    const age = now - timestamp;

    // Fresh - return immediately
    if (age < options.staleTime * 1000) {
      return data;
    }

    // Stale but not expired - return and revalidate in background
    if (age < options.maxAge * 1000) {
      // Revalidate in background (don't await)
      revalidate(key, fetcher, options.maxAge).catch(console.error);
      return data;
    }
  }

  // No cache or expired - fetch and cache
  const freshData = await fetcher();
  await cacheData(key, freshData, options.maxAge);

  return freshData;
}

async function revalidate<T>(
  key: string,
  fetcher: () => Promise<T>,
  maxAge: number,
): Promise<void> {
  const lockKey = `lock:${key}`;

  // Prevent multiple simultaneous revalidations
  const acquired = await redis.set(lockKey, '1', 'EX', 10, 'NX');
  if (!acquired) return;

  try {
    const data = await fetcher();
    await cacheData(key, data, maxAge);
  } finally {
    await redis.del(lockKey);
  }
}

async function cacheData<T>(
  key: string,
  data: T,
  maxAge: number,
): Promise<void> {
  const cached: CachedData<T> = {
    data,
    timestamp: Date.now(),
  };

  await redis.setex(key, maxAge, JSON.stringify(cached));
}
```

### Cache Warming

```typescript
// scripts/warm-cache.ts
import { db } from '@/lib/db';
import { cacheSet } from '@/lib/cache';

async function warmCache() {
  console.log('Warming cache...');

  // Warm popular products
  const popularProducts = await db.product.findMany({
    where: { featured: true },
    take: 100,
  });

  await Promise.all(
    popularProducts.map((product) =>
      cacheSet(`product:${product.id}`, product, {
        ttl: 3600,
        tags: ['products'],
      }),
    ),
  );

  // Warm category lists
  const categories = await db.category.findMany();
  await Promise.all(
    categories.map(async (category) => {
      const products = await db.product.findMany({
        where: { categoryId: category.id },
        take: 20,
      });

      await cacheSet(`category:${category.slug}:products`, products, {
        ttl: 3600,
        tags: ['products', `category:${category.slug}`],
      });
    }),
  );

  console.log('Cache warmed successfully');
}

warmCache().catch(console.error);
```

### Cache Invalidation on Mutations

```typescript
// lib/products.ts
import { db } from './db';
import { cacheInvalidateTag, cacheDelete } from './cache';
import { revalidatePath, revalidateTag } from 'next/cache';

export async function updateProduct(
  id: string,
  data: UpdateProductInput,
) {
  const product = await db.product.update({
    where: { id },
    data,
  });

  // Invalidate Redis cache
  await cacheDelete(`product:${id}`);
  await cacheInvalidateTag(`category:${product.categoryId}`);
  await cacheInvalidateTag('products');

  // Invalidate Next.js cache
  revalidateTag('products');
  revalidatePath('/products');
  revalidatePath(`/products/${product.slug}`);

  return product;
}

export async function deleteProduct(id: string) {
  const product = await db.product.delete({ where: { id } });

  // Full invalidation for deletes
  await cacheDelete(`product:${id}`);
  await cacheInvalidateTag('products');

  revalidateTag('products');
  revalidatePath('/products');

  return product;
}
```

## When to Use

- Frequently accessed data
- Expensive computations
- External API responses
- Static content with occasional updates

## Anti-patterns

```typescript
// BAD: Cache everything forever
await redis.set(key, value); // No TTL = stale data forever

// BAD: No invalidation strategy
await createProduct(data); // Cache still has old list

// BAD: Caching user-specific data with shared key
await cache.set('products', userProducts); // Other users see wrong data

// BAD: Cache stampede
if (!cache.get(key)) {
  const data = await expensiveQuery(); // 100 requests all hit DB
  cache.set(key, data);
}
```

```typescript
// GOOD: Always set TTL
await redis.setex(key, 3600, value);

// GOOD: Invalidate on mutations
await createProduct(data);
await cacheInvalidateTag('products');

// GOOD: User-specific cache keys
await cache.set(`user:${userId}:products`, products);

// GOOD: Prevent stampede with locks
const lock = await acquireLock(key);
if (lock) {
  const data = await expensiveQuery();
  await cache.set(key, data);
  await releaseLock(key);
}
```

## Related Patterns

- Third-Party API Pattern - Cache API responses
- Queue Processing Pattern - Async cache warming
- Database Pattern - Reduce database load
