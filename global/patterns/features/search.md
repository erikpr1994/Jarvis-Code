---
name: Search
category: feature
language: typescript
framework: nextjs
keywords: [search, filter, query, debounce, full-text, instant-search]
confidence: 0.85
---

# Search Pattern

## Problem

Implementing search has many challenges:
- Too many requests from typing
- Poor search relevance
- Slow search performance
- No search state persistence

## Solution

Implement debounced search with URL state, optimistic UI updates, and appropriate backend search strategies.

## Implementation

### Search with URL State (Server Component)

```typescript
// app/search/page.tsx
import { db } from '@/lib/db';
import { SearchInput } from '@/components/search-input';
import { SearchResults } from '@/components/search-results';
import { Suspense } from 'react';

interface SearchPageProps {
  searchParams: Promise<{ q?: string; category?: string }>;
}

export default async function SearchPage({ searchParams }: SearchPageProps) {
  const params = await searchParams;
  const query = params.q ?? '';
  const category = params.category;

  return (
    <div className="container py-8">
      <SearchInput defaultValue={query} />

      <Suspense
        key={query + category}
        fallback={<SearchResultsSkeleton />}
      >
        <SearchResultsAsync query={query} category={category} />
      </Suspense>
    </div>
  );
}

async function SearchResultsAsync({
  query,
  category,
}: {
  query: string;
  category?: string;
}) {
  if (!query) {
    return <EmptySearch />;
  }

  const results = await db.product.findMany({
    where: {
      AND: [
        {
          OR: [
            { name: { contains: query, mode: 'insensitive' } },
            { description: { contains: query, mode: 'insensitive' } },
          ],
        },
        category ? { category } : {},
      ],
    },
    take: 20,
    orderBy: { _relevance: { fields: ['name'], search: query, sort: 'desc' } },
  });

  if (results.length === 0) {
    return <NoResults query={query} />;
  }

  return <SearchResults results={results} />;
}
```

### Debounced Search Input

```typescript
// components/search-input.tsx
'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useState, useTransition, useCallback, useEffect } from 'react';
import { useDebounce } from '@/hooks/use-debounce';
import { SearchIcon, XIcon, Loader2 } from 'lucide-react';
import { Input } from '@/components/ui/input';

interface SearchInputProps {
  defaultValue?: string;
  placeholder?: string;
}

export function SearchInput({
  defaultValue = '',
  placeholder = 'Search...',
}: SearchInputProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [isPending, startTransition] = useTransition();

  const [value, setValue] = useState(defaultValue);
  const debouncedValue = useDebounce(value, 300);

  // Update URL when debounced value changes
  useEffect(() => {
    const params = new URLSearchParams(searchParams);

    if (debouncedValue) {
      params.set('q', debouncedValue);
    } else {
      params.delete('q');
    }

    startTransition(() => {
      router.push(`/search?${params.toString()}`);
    });
  }, [debouncedValue, router, searchParams]);

  const clearSearch = useCallback(() => {
    setValue('');
  }, []);

  return (
    <div className="relative w-full max-w-xl">
      <SearchIcon className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />

      <Input
        type="search"
        value={value}
        onChange={(e) => setValue(e.target.value)}
        placeholder={placeholder}
        className="pl-10 pr-10"
      />

      {isPending ? (
        <Loader2 className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 animate-spin" />
      ) : value ? (
        <button
          onClick={clearSearch}
          className="absolute right-3 top-1/2 -translate-y-1/2 p-1 hover:bg-gray-100 rounded"
        >
          <XIcon className="h-4 w-4" />
        </button>
      ) : null}
    </div>
  );
}
```

### Search with Filters

```typescript
// components/search-filters.tsx
'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useCallback, useTransition } from 'react';
import { Select } from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';

const categories = ['Electronics', 'Clothing', 'Books', 'Home'];
const sortOptions = [
  { value: 'relevance', label: 'Most Relevant' },
  { value: 'newest', label: 'Newest First' },
  { value: 'price-low', label: 'Price: Low to High' },
  { value: 'price-high', label: 'Price: High to Low' },
];

export function SearchFilters() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [isPending, startTransition] = useTransition();

  const updateFilter = useCallback(
    (key: string, value: string | null) => {
      const params = new URLSearchParams(searchParams);

      if (value) {
        params.set(key, value);
      } else {
        params.delete(key);
      }

      // Reset to page 1 when filters change
      params.delete('page');

      startTransition(() => {
        router.push(`/search?${params.toString()}`);
      });
    },
    [router, searchParams],
  );

  const currentCategory = searchParams.get('category');
  const currentSort = searchParams.get('sort') ?? 'relevance';
  const inStock = searchParams.get('inStock') === 'true';

  return (
    <div className="space-y-4">
      <div>
        <label className="text-sm font-medium">Category</label>
        <Select
          value={currentCategory ?? ''}
          onValueChange={(v) => updateFilter('category', v || null)}
        >
          <option value="">All Categories</option>
          {categories.map((cat) => (
            <option key={cat} value={cat}>
              {cat}
            </option>
          ))}
        </Select>
      </div>

      <div>
        <label className="text-sm font-medium">Sort By</label>
        <Select
          value={currentSort}
          onValueChange={(v) => updateFilter('sort', v)}
        >
          {sortOptions.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </Select>
      </div>

      <div className="flex items-center gap-2">
        <Checkbox
          checked={inStock}
          onCheckedChange={(checked) =>
            updateFilter('inStock', checked ? 'true' : null)
          }
        />
        <label className="text-sm">In Stock Only</label>
      </div>
    </div>
  );
}
```

### Instant Search with Results Dropdown

```typescript
// components/instant-search.tsx
'use client';

import { useState, useRef, useEffect } from 'react';
import { useDebounce } from '@/hooks/use-debounce';
import { useQuery } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { SearchIcon, Loader2 } from 'lucide-react';

interface SearchResult {
  id: string;
  title: string;
  type: 'product' | 'article' | 'user';
  url: string;
}

async function searchAll(query: string): Promise<SearchResult[]> {
  if (!query) return [];
  const res = await fetch(`/api/search?q=${encodeURIComponent(query)}`);
  if (!res.ok) throw new Error('Search failed');
  return res.json();
}

export function InstantSearch() {
  const router = useRouter();
  const [isOpen, setIsOpen] = useState(false);
  const [query, setQuery] = useState('');
  const debouncedQuery = useDebounce(query, 200);
  const inputRef = useRef<HTMLInputElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  const { data: results, isLoading } = useQuery({
    queryKey: ['search', debouncedQuery],
    queryFn: () => searchAll(debouncedQuery),
    enabled: debouncedQuery.length >= 2,
  });

  // Close on click outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (
        containerRef.current &&
        !containerRef.current.contains(event.target as Node)
      ) {
        setIsOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Keyboard navigation
  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Escape') {
      setIsOpen(false);
      inputRef.current?.blur();
    }
    if (e.key === 'Enter' && query) {
      router.push(`/search?q=${encodeURIComponent(query)}`);
      setIsOpen(false);
    }
  };

  const handleResultClick = (result: SearchResult) => {
    router.push(result.url);
    setIsOpen(false);
    setQuery('');
  };

  return (
    <div ref={containerRef} className="relative w-full max-w-md">
      <div className="relative">
        <SearchIcon className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <input
          ref={inputRef}
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onFocus={() => setIsOpen(true)}
          onKeyDown={handleKeyDown}
          placeholder="Search..."
          className="w-full pl-10 pr-4 py-2 border rounded-lg"
        />
        {isLoading && (
          <Loader2 className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 animate-spin" />
        )}
      </div>

      {isOpen && debouncedQuery.length >= 2 && (
        <div className="absolute top-full mt-1 w-full bg-white border rounded-lg shadow-lg z-50">
          {results && results.length > 0 ? (
            <ul className="py-2">
              {results.map((result) => (
                <li key={result.id}>
                  <button
                    onClick={() => handleResultClick(result)}
                    className="w-full px-4 py-2 text-left hover:bg-gray-100 flex items-center gap-2"
                  >
                    <span className="text-xs text-muted-foreground capitalize">
                      {result.type}
                    </span>
                    <span>{result.title}</span>
                  </button>
                </li>
              ))}
            </ul>
          ) : !isLoading ? (
            <div className="px-4 py-3 text-muted-foreground">
              No results found
            </div>
          ) : null}

          <div className="border-t px-4 py-2">
            <button
              onClick={() => {
                router.push(`/search?q=${encodeURIComponent(query)}`);
                setIsOpen(false);
              }}
              className="text-sm text-blue-600 hover:underline"
            >
              See all results for "{query}"
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
```

### Search API with Full-Text Search

```typescript
// app/api/search/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { db } from '@/lib/db';

const searchSchema = z.object({
  q: z.string().min(1).max(100),
  type: z.enum(['all', 'products', 'articles', 'users']).default('all'),
  limit: z.coerce.number().min(1).max(50).default(10),
});

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const { q, type, limit } = searchSchema.parse(
      Object.fromEntries(searchParams),
    );

    // Clean and prepare search query
    const searchQuery = q.trim().toLowerCase();

    const results = await Promise.all([
      // Products search
      (type === 'all' || type === 'products') &&
        db.$queryRaw`
          SELECT id, name as title, 'product' as type, '/products/' || slug as url
          FROM products
          WHERE to_tsvector('english', name || ' ' || description) @@ plainto_tsquery('english', ${searchQuery})
          ORDER BY ts_rank(to_tsvector('english', name || ' ' || description), plainto_tsquery('english', ${searchQuery})) DESC
          LIMIT ${limit}
        `,

      // Articles search
      (type === 'all' || type === 'articles') &&
        db.$queryRaw`
          SELECT id, title, 'article' as type, '/blog/' || slug as url
          FROM articles
          WHERE to_tsvector('english', title || ' ' || content) @@ plainto_tsquery('english', ${searchQuery})
          ORDER BY ts_rank(to_tsvector('english', title || ' ' || content), plainto_tsquery('english', ${searchQuery})) DESC
          LIMIT ${limit}
        `,
    ]);

    const flatResults = results.filter(Boolean).flat();

    return NextResponse.json(flatResults);
  } catch (error) {
    console.error('Search error:', error);
    return NextResponse.json(
      { error: 'Search failed' },
      { status: 500 },
    );
  }
}
```

## When to Use

- Product catalogs
- Documentation sites
- User directories
- Any content-heavy application

## Anti-patterns

```typescript
// BAD: Search on every keystroke
onChange={(e) => {
  const results = await search(e.target.value); // Request per character!
}}

// BAD: Client-side filtering of all data
const results = allItems.filter(item =>
  item.name.includes(query) // Loaded all items first
);

// BAD: No loading state
{results.map(r => <Result key={r.id} />)} // Blank during search

// BAD: Search state lost on navigation
// Using local state instead of URL params
```

```typescript
// GOOD: Debounced search
const debouncedQuery = useDebounce(query, 300);
useEffect(() => {
  search(debouncedQuery);
}, [debouncedQuery]);

// GOOD: Server-side search with indexes
WHERE to_tsvector('english', name) @@ plainto_tsquery('english', $1)

// GOOD: Loading and empty states
if (isLoading) return <Skeleton />;
if (results.length === 0) return <NoResults />;

// GOOD: URL-based search state
router.push(`/search?q=${query}`);
```

## Related Patterns

- Pagination Pattern - Often combined with search
- Debounce Hook Pattern - For search input
- API Route Pattern - For search endpoints
