---
name: Pagination
category: feature
language: typescript
framework: nextjs
keywords: [pagination, infinite-scroll, cursor, offset, list, data-fetching]
confidence: 0.85
---

# Pagination Pattern

## Problem

Loading all data at once causes:
- Slow page loads
- High memory usage
- Poor user experience
- Server strain with large datasets

## Solution

Implement pagination with cursor-based or offset-based approaches, with both traditional pagination UI and infinite scroll options.

## Implementation

### Offset-Based Pagination (Server Component)

```typescript
// app/users/page.tsx
import { db } from '@/lib/db';
import { UserList } from '@/components/user-list';
import { Pagination } from '@/components/pagination';

interface PageProps {
  searchParams: Promise<{ page?: string; limit?: string }>;
}

export default async function UsersPage({ searchParams }: PageProps) {
  const params = await searchParams;
  const page = Math.max(1, parseInt(params.page ?? '1'));
  const limit = Math.min(100, parseInt(params.limit ?? '20'));
  const skip = (page - 1) * limit;

  const [users, total] = await Promise.all([
    db.user.findMany({
      skip,
      take: limit,
      orderBy: { createdAt: 'desc' },
    }),
    db.user.count(),
  ]);

  const totalPages = Math.ceil(total / limit);

  return (
    <div>
      <UserList users={users} />
      <Pagination
        currentPage={page}
        totalPages={totalPages}
        baseUrl="/users"
      />
    </div>
  );
}
```

### Pagination Component

```typescript
// components/pagination.tsx
import Link from 'next/link';
import { cn } from '@/lib/utils';
import { ChevronLeft, ChevronRight } from 'lucide-react';

interface PaginationProps {
  currentPage: number;
  totalPages: number;
  baseUrl: string;
}

export function Pagination({
  currentPage,
  totalPages,
  baseUrl,
}: PaginationProps) {
  const pages = generatePageNumbers(currentPage, totalPages);

  return (
    <nav className="flex items-center justify-center gap-1" aria-label="Pagination">
      <Link
        href={currentPage > 1 ? `${baseUrl}?page=${currentPage - 1}` : '#'}
        className={cn(
          'p-2 rounded-md',
          currentPage <= 1
            ? 'text-gray-300 cursor-not-allowed'
            : 'hover:bg-gray-100',
        )}
        aria-disabled={currentPage <= 1}
      >
        <ChevronLeft className="h-5 w-5" />
        <span className="sr-only">Previous</span>
      </Link>

      {pages.map((page, index) => (
        page === '...' ? (
          <span key={`ellipsis-${index}`} className="px-3 py-2">
            ...
          </span>
        ) : (
          <Link
            key={page}
            href={`${baseUrl}?page=${page}`}
            className={cn(
              'px-3 py-2 rounded-md text-sm font-medium',
              page === currentPage
                ? 'bg-blue-600 text-white'
                : 'hover:bg-gray-100',
            )}
            aria-current={page === currentPage ? 'page' : undefined}
          >
            {page}
          </Link>
        )
      ))}

      <Link
        href={currentPage < totalPages ? `${baseUrl}?page=${currentPage + 1}` : '#'}
        className={cn(
          'p-2 rounded-md',
          currentPage >= totalPages
            ? 'text-gray-300 cursor-not-allowed'
            : 'hover:bg-gray-100',
        )}
        aria-disabled={currentPage >= totalPages}
      >
        <ChevronRight className="h-5 w-5" />
        <span className="sr-only">Next</span>
      </Link>
    </nav>
  );
}

function generatePageNumbers(current: number, total: number): (number | '...')[] {
  if (total <= 7) {
    return Array.from({ length: total }, (_, i) => i + 1);
  }

  if (current <= 3) {
    return [1, 2, 3, 4, '...', total];
  }

  if (current >= total - 2) {
    return [1, '...', total - 3, total - 2, total - 1, total];
  }

  return [1, '...', current - 1, current, current + 1, '...', total];
}
```

### Cursor-Based Pagination (API)

```typescript
// app/api/posts/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { db } from '@/lib/db';

const querySchema = z.object({
  cursor: z.string().optional(),
  limit: z.coerce.number().min(1).max(100).default(20),
});

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const { cursor, limit } = querySchema.parse(
    Object.fromEntries(searchParams),
  );

  const posts = await db.post.findMany({
    take: limit + 1, // Fetch one extra to check if there's more
    ...(cursor && {
      cursor: { id: cursor },
      skip: 1, // Skip the cursor item
    }),
    orderBy: { createdAt: 'desc' },
    include: {
      author: {
        select: { name: true, avatar: true },
      },
    },
  });

  // Check if there's a next page
  const hasMore = posts.length > limit;
  const items = hasMore ? posts.slice(0, -1) : posts;
  const nextCursor = hasMore ? items[items.length - 1].id : null;

  return NextResponse.json({
    data: items,
    pagination: {
      nextCursor,
      hasMore,
    },
  });
}
```

### Infinite Scroll Component

```typescript
// components/infinite-posts.tsx
'use client';

import { useInfiniteQuery } from '@tanstack/react-query';
import { useInView } from 'react-intersection-observer';
import { useEffect } from 'react';
import { PostCard } from './post-card';
import { Skeleton } from './ui/skeleton';

interface Post {
  id: string;
  title: string;
  content: string;
  author: { name: string; avatar: string };
}

interface PostsResponse {
  data: Post[];
  pagination: {
    nextCursor: string | null;
    hasMore: boolean;
  };
}

async function fetchPosts(cursor?: string): Promise<PostsResponse> {
  const params = new URLSearchParams();
  if (cursor) params.set('cursor', cursor);

  const response = await fetch(`/api/posts?${params}`);
  if (!response.ok) throw new Error('Failed to fetch posts');
  return response.json();
}

export function InfinitePosts() {
  const { ref, inView } = useInView();

  const {
    data,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    isLoading,
    isError,
    error,
  } = useInfiniteQuery({
    queryKey: ['posts'],
    queryFn: ({ pageParam }) => fetchPosts(pageParam),
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (lastPage) =>
      lastPage.pagination.hasMore ? lastPage.pagination.nextCursor : undefined,
  });

  // Auto-fetch when scrolling near bottom
  useEffect(() => {
    if (inView && hasNextPage && !isFetchingNextPage) {
      fetchNextPage();
    }
  }, [inView, hasNextPage, isFetchingNextPage, fetchNextPage]);

  if (isLoading) {
    return (
      <div className="space-y-4">
        {Array.from({ length: 5 }).map((_, i) => (
          <Skeleton key={i} className="h-32 w-full" />
        ))}
      </div>
    );
  }

  if (isError) {
    return (
      <div className="text-red-500">
        Error: {error.message}
      </div>
    );
  }

  const allPosts = data?.pages.flatMap((page) => page.data) ?? [];

  return (
    <div className="space-y-4">
      {allPosts.map((post) => (
        <PostCard key={post.id} post={post} />
      ))}

      {/* Sentinel for infinite scroll */}
      <div ref={ref} className="h-10">
        {isFetchingNextPage && (
          <div className="flex justify-center">
            <Spinner />
          </div>
        )}
      </div>

      {!hasNextPage && allPosts.length > 0 && (
        <p className="text-center text-muted-foreground">
          No more posts to load
        </p>
      )}
    </div>
  );
}
```

### Load More Button Pattern

```typescript
// components/load-more-posts.tsx
'use client';

import { useState } from 'react';
import { Button } from './ui/button';
import { PostCard } from './post-card';

interface Post {
  id: string;
  title: string;
}

interface LoadMorePostsProps {
  initialPosts: Post[];
  initialCursor: string | null;
}

export function LoadMorePosts({
  initialPosts,
  initialCursor,
}: LoadMorePostsProps) {
  const [posts, setPosts] = useState(initialPosts);
  const [cursor, setCursor] = useState(initialCursor);
  const [isLoading, setIsLoading] = useState(false);

  const loadMore = async () => {
    if (!cursor) return;

    setIsLoading(true);
    try {
      const response = await fetch(`/api/posts?cursor=${cursor}`);
      const data = await response.json();

      setPosts((prev) => [...prev, ...data.data]);
      setCursor(data.pagination.nextCursor);
    } catch (error) {
      console.error('Failed to load more posts:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-4">
      {posts.map((post) => (
        <PostCard key={post.id} post={post} />
      ))}

      {cursor && (
        <div className="flex justify-center">
          <Button onClick={loadMore} disabled={isLoading}>
            {isLoading ? 'Loading...' : 'Load More'}
          </Button>
        </div>
      )}
    </div>
  );
}
```

### Server-Side with URL State

```typescript
// app/products/page.tsx
import { db } from '@/lib/db';
import { ProductGrid } from '@/components/product-grid';
import { Pagination } from '@/components/pagination';
import { SortSelect } from '@/components/sort-select';

interface SearchParams {
  page?: string;
  sort?: string;
  category?: string;
}

export default async function ProductsPage({
  searchParams,
}: {
  searchParams: Promise<SearchParams>;
}) {
  const params = await searchParams;
  const page = parseInt(params.page ?? '1');
  const sort = params.sort ?? 'newest';
  const category = params.category;
  const limit = 24;

  const orderBy = {
    newest: { createdAt: 'desc' },
    oldest: { createdAt: 'asc' },
    'price-low': { price: 'asc' },
    'price-high': { price: 'desc' },
  }[sort] as Record<string, 'asc' | 'desc'>;

  const where = category ? { category } : {};

  const [products, total] = await Promise.all([
    db.product.findMany({
      where,
      orderBy,
      skip: (page - 1) * limit,
      take: limit,
    }),
    db.product.count({ where }),
  ]);

  const totalPages = Math.ceil(total / limit);

  // Build base URL with current filters
  const baseUrl = `/products?${new URLSearchParams({
    ...(sort !== 'newest' && { sort }),
    ...(category && { category }),
  })}`;

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <p>{total} products</p>
        <SortSelect currentSort={sort} />
      </div>

      <ProductGrid products={products} />

      <Pagination
        currentPage={page}
        totalPages={totalPages}
        baseUrl={baseUrl}
      />
    </div>
  );
}
```

## When to Use

- Lists with more than ~50 items
- Data that changes frequently
- Limited bandwidth/mobile
- Any scrollable content list

## Anti-patterns

```typescript
// BAD: Loading all data then slicing
const allUsers = await db.user.findMany();
const pageUsers = allUsers.slice(skip, skip + limit); // All loaded!

// BAD: No total count
return { data: users }; // User doesn't know total pages

// BAD: Offset pagination for real-time data
// Page 2 might skip or repeat items if data changes

// BAD: No loading states
{posts.map(post => <Post key={post.id} />)} // Blank during load

// BAD: Unkeyed pagination
{page === 1 && <Page1 />}
{page === 2 && <Page2 />} // Component state persists incorrectly
```

```typescript
// GOOD: Database-level pagination
const users = await db.user.findMany({
  skip: (page - 1) * limit,
  take: limit,
});

// GOOD: Include pagination metadata
return {
  data: users,
  pagination: { page, totalPages, total },
};

// GOOD: Cursor pagination for real-time data
const posts = await db.post.findMany({
  cursor: { id: cursor },
  take: limit + 1,
});

// GOOD: Loading and empty states
if (isLoading) return <Skeleton />;
if (posts.length === 0) return <Empty />;

// GOOD: Key by page for proper remounting
<UserList key={`page-${page}`} users={users} />
```

## Related Patterns

- API Route Pattern - For paginated API endpoints
- Infinite Scroll Pattern - Alternative to traditional pagination
- Search Pattern - Often combined with pagination
