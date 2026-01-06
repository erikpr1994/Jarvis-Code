---
name: add-page
description: Scaffold a new page/route with proper structure and components
disable-model-invocation: false
---

# /add-page - Add a New Page

Scaffold a new page or route with appropriate structure based on the framework.

## What It Does

1. **Detects framework** - Identifies Next.js, React Router, Vue Router, etc.
2. **Creates page file** - Generates page component with proper boilerplate
3. **Sets up routing** - Configures route if needed
4. **Adds metadata** - Includes SEO, title, description where applicable

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | Page name and optional path | "dashboard", "settings/profile" |

## Process

### Phase 1: Detection

1. **Identify framework**
   - Check for `app/` directory (Next.js App Router)
   - Check for `pages/` directory (Next.js Pages Router)
   - Check for `src/routes/` (SvelteKit, SolidStart)
   - Check for `router` configuration (React Router, Vue Router)

2. **Determine page type**
   - Static page (no dynamic segments)
   - Dynamic page (with [params])
   - Catch-all route ([...slug])

### Phase 2: Scaffolding

3. **Create page file**

For Next.js App Router:
```typescript
// app/[path]/page.tsx
import { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Page Title',
  description: 'Page description',
}

export default function PageName() {
  return (
    <main>
      <h1>Page Title</h1>
    </main>
  )
}
```

For Next.js Pages Router:
```typescript
// pages/[path].tsx
import Head from 'next/head'

export default function PageName() {
  return (
    <>
      <Head>
        <title>Page Title</title>
        <meta name="description" content="Page description" />
      </Head>
      <main>
        <h1>Page Title</h1>
      </main>
    </>
  )
}
```

4. **Create supporting files** (if applicable)
   - `loading.tsx` - Loading state
   - `error.tsx` - Error boundary
   - `layout.tsx` - Page-specific layout

### Phase 3: Integration

5. **Update navigation** (if applicable)
   - Add to nav menu config
   - Update sitemap
   - Add breadcrumb entry

## Examples

**Add simple page:**
```
/add-page about
```
Creates `app/about/page.tsx` or `pages/about.tsx`

**Add nested page:**
```
/add-page settings/profile
```
Creates `app/settings/profile/page.tsx`

**Add dynamic page:**
```
/add-page blog/[slug]
```
Creates `app/blog/[slug]/page.tsx` with params handling

**Add catch-all:**
```
/add-page docs/[...slug]
```
Creates catch-all route for documentation

## Framework Templates

### Next.js App Router
- `page.tsx` - Main page component
- `layout.tsx` - Optional layout
- `loading.tsx` - Loading UI
- `error.tsx` - Error handling

### SvelteKit
- `+page.svelte` - Page component
- `+page.ts` - Load function
- `+layout.svelte` - Layout

### React Router
- Page component
- Route registration in router config

## Output

After completion:
```
Created page: /settings/profile

Files created:
  - app/settings/profile/page.tsx
  - app/settings/profile/loading.tsx

Next steps:
  - Add content to the page
  - Update navigation if needed
  - Add tests for the page
```
