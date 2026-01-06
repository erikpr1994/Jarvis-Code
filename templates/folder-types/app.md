# App Directory

> Inherits from: parent CLAUDE.md
> Level: L2 (apps/*/)
> Token budget: ~500 tokens

## Purpose

Application entry point with routing, layouts, and app-specific configuration.

## Organization

```
app/
├── (auth)/              # Route groups (no URL impact)
│   ├── login/
│   │   └── page.tsx
│   └── layout.tsx
├── (dashboard)/
│   ├── layout.tsx
│   └── [slug]/
│       └── page.tsx
├── api/                 # API routes (if applicable)
│   └── [...route]/
│       └── route.ts
├── layout.tsx           # Root layout
├── page.tsx             # Home page
├── loading.tsx          # Loading UI
├── error.tsx            # Error boundary
├── not-found.tsx        # 404 page
└── globals.css          # Global styles
```

## Routing Patterns

### File Conventions

| File | Purpose |
|------|---------|
| `page.tsx` | Page component (required for route) |
| `layout.tsx` | Shared layout (wraps children) |
| `loading.tsx` | Loading state (Suspense boundary) |
| `error.tsx` | Error boundary |
| `not-found.tsx` | 404 handling |
| `route.ts` | API endpoint |

### Dynamic Routes

```typescript
// [id]/page.tsx - Dynamic segment
export default function Page({ params }: { params: { id: string } }) {
  return <div>ID: {params.id}</div>;
}

// [...slug]/page.tsx - Catch-all
export default function Page({ params }: { params: { slug: string[] } }) {
  return <div>Path: {params.slug.join('/')}</div>;
}
```

### Route Groups

```
(marketing)/           # Groups routes without affecting URL
├── about/page.tsx     # /about
└── contact/page.tsx   # /contact

(dashboard)/
├── layout.tsx         # Dashboard-specific layout
└── settings/page.tsx  # /settings
```

## Data Fetching

### Server Components (default)

```typescript
// Direct async/await in component
async function Page() {
  const data = await fetchData();
  return <div>{data.title}</div>;
}
```

### Server Actions

```typescript
// actions.ts
'use server';

export async function createItem(formData: FormData) {
  const title = formData.get('title');
  // Database operation
  revalidatePath('/items');
}
```

## Metadata

```typescript
// Static metadata
export const metadata: Metadata = {
  title: 'Page Title',
  description: 'Page description',
};

// Dynamic metadata
export async function generateMetadata({ params }): Promise<Metadata> {
  const data = await fetchData(params.id);
  return { title: data.title };
}
```

## Key Patterns

### Layout Composition

```typescript
// layout.tsx - wraps all child routes
export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen">
      <Header />
      <main>{children}</main>
      <Footer />
    </div>
  );
}
```

### Loading States

```typescript
// loading.tsx - automatic Suspense boundary
export default function Loading() {
  return <Skeleton />;
}
```

### Error Handling

```typescript
'use client';

export default function Error({
  error,
  reset,
}: {
  error: Error;
  reset: () => void;
}) {
  return (
    <div>
      <h2>Something went wrong</h2>
      <button onClick={reset}>Try again</button>
    </div>
  );
}
```

## DO NOT

- Put business logic in page components (use services/actions)
- Create deeply nested route structures (max 4 levels)
- Skip loading.tsx for data-fetching pages
- Use client components for static content
- Ignore error boundaries for critical pages
- Duplicate layouts (use route groups)

## Testing

```typescript
// Page tests focus on integration
import { render, screen } from '@testing-library/react';

describe('HomePage', () => {
  it('renders main content', async () => {
    render(await Page());
    expect(screen.getByRole('heading')).toBeInTheDocument();
  });
});
```
