# Next.js Project Additions

> Inherits from: global-claude.md + CLAUDE.md.template + typescript.md
> Override: {{OVERRIDE_PARENT}} (set to true for complete override, false for merge)
> Token budget: ~800 tokens

This template extends the base CLAUDE.md with Next.js-specific patterns.

## Tech Stack Additions

```yaml
framework:
  - Next.js {{NEXTJS_VERSION}}
  - React {{REACT_VERSION}}

routing:
  type: {{ROUTER_TYPE}}  # app | pages

rendering:
  default: {{DEFAULT_RENDERING}}  # SSR | SSG | ISR | CSR

styling:
  - {{STYLING_SOLUTION}}  # tailwind | css-modules | styled-components
```

## Project Structure

### App Router (if applicable)

```
app/
├── layout.tsx           # Root layout (required)
├── page.tsx             # Home page
├── loading.tsx          # Loading UI
├── error.tsx            # Error UI
├── not-found.tsx        # 404 page
├── globals.css          # Global styles
├── (auth)/              # Route group (no URL segment)
│   ├── login/page.tsx
│   └── signup/page.tsx
├── api/                 # API routes
│   └── [route]/route.ts
└── [dynamic]/           # Dynamic segments
    └── page.tsx
```

### Pages Router (if applicable)

```
pages/
├── _app.tsx             # App wrapper
├── _document.tsx        # Document customization
├── index.tsx            # Home page
├── api/                 # API routes
│   └── [route].ts
└── [dynamic]/           # Dynamic routes
    └── index.tsx
```

## Key Patterns

### Server Components (App Router)

- Default to Server Components (no 'use client')
- Add 'use client' only when needed:
  - useState, useEffect, event handlers
  - Browser-only APIs
  - Third-party client libraries

```typescript
// Server Component (default)
async function ServerPage() {
  const data = await fetchData(); // Direct async/await
  return <div>{data.title}</div>;
}

// Client Component (when needed)
'use client';
import { useState } from 'react';

function ClientCounter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}
```

### Server Actions

```typescript
// In Server Component or separate file
'use server';

export async function createItem(formData: FormData) {
  const title = formData.get('title');

  // Validate
  if (!title || typeof title !== 'string') {
    return { error: 'Title required' };
  }

  // Perform action
  await db.items.create({ data: { title } });

  // Revalidate cache
  revalidatePath('/items');

  return { success: true };
}
```

### Data Fetching

```typescript
// Server Component - direct fetch
async function DataPage() {
  // With caching options
  const data = await fetch('https://api.example.com/data', {
    next: { revalidate: 3600 }, // ISR: revalidate every hour
  });

  return <DataDisplay data={await data.json()} />;
}

// With unstable_cache for database queries
import { unstable_cache } from 'next/cache';

const getCachedUser = unstable_cache(
  async (userId: string) => db.user.findUnique({ where: { id: userId } }),
  ['user-data'],
  { revalidate: 3600, tags: ['user'] }
);
```

### Metadata

```typescript
// Static metadata
export const metadata: Metadata = {
  title: 'Page Title',
  description: 'Page description',
};

// Dynamic metadata
export async function generateMetadata({ params }): Promise<Metadata> {
  const item = await getItem(params.id);
  return {
    title: item.title,
    description: item.description,
    openGraph: { images: [item.image] },
  };
}
```

### Route Handlers (API Routes)

```typescript
// app/api/items/route.ts
import { NextResponse } from 'next/server';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const id = searchParams.get('id');

  try {
    const data = await fetchData(id);
    return NextResponse.json(data);
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to fetch' },
      { status: 500 }
    );
  }
}

export async function POST(request: Request) {
  const body = await request.json();
  // Validate and process
  return NextResponse.json({ success: true }, { status: 201 });
}
```

## Testing

### Component Testing

```typescript
import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import Page from './page';

// Mock server actions
vi.mock('./actions', () => ({
  getData: vi.fn().mockResolvedValue({ items: [] }),
}));

describe('Page', () => {
  it('renders correctly', async () => {
    const result = await Page();
    render(result);
    expect(screen.getByRole('heading')).toBeInTheDocument();
  });
});
```

### E2E Testing

```typescript
// e2e/navigation.spec.ts
import { test, expect } from '@playwright/test';

test('navigates to about page', async ({ page }) => {
  await page.goto('/');
  await page.click('text=About');
  await expect(page).toHaveURL('/about');
  await expect(page.locator('h1')).toContainText('About');
});
```

## Common Commands

```bash
# Development
{{DEV_CMD}}

# Build
{{BUILD_CMD}}

# Start production
{{START_CMD}}

# Type check
{{TYPECHECK_CMD}}

# Lint
{{LINT_CMD}}
```

## DO NOT

- Use 'use client' without necessity (breaks Server Component benefits)
- Fetch data in Client Components when Server Components suffice
- Use getServerSideProps/getStaticProps in App Router (use async components)
- Mix Server Actions with API routes for same functionality
- Forget to handle loading and error states
- Skip metadata for SEO-important pages
- Use cookies() or headers() in cached functions without proper handling

## File Conventions

| Pattern | Purpose |
|---------|---------|
| `page.tsx` | Route UI |
| `layout.tsx` | Shared layout |
| `loading.tsx` | Loading UI |
| `error.tsx` | Error boundary |
| `not-found.tsx` | 404 page |
| `route.ts` | API endpoint |
| `template.tsx` | Re-mounting layout |
| `default.tsx` | Parallel route fallback |
