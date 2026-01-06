# Supabase Project Additions

> Inherits from: global-claude.md + CLAUDE.md.template
> Override: {{OVERRIDE_PARENT}} (set to true for complete override, false for merge)
> Token budget: ~900 tokens

This template extends the base CLAUDE.md with Supabase-specific patterns.

## Tech Stack Additions

```yaml
database:
  - Supabase {{SUPABASE_VERSION}}
  - PostgreSQL 15

features:
  - Authentication
  - Row Level Security (RLS)
  - Realtime subscriptions
  - Edge Functions
  - Storage
```

## Project Structure

```
supabase/
├── config.toml              # Supabase configuration
├── migrations/              # Database migrations
│   ├── 20240101000000_initial.sql
│   └── 20240102000000_add_profiles.sql
├── functions/               # Edge Functions
│   └── my-function/
│       └── index.ts
├── seed.sql                 # Seed data
└── tests/                   # Database tests
    └── database.test.sql
```

## Key Patterns

### Database Schema

```sql
-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Create tables with proper types
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique not null,
  display_name text,
  avatar_url text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

-- Enable RLS
alter table public.profiles enable row level security;

-- RLS Policies
create policy "Public profiles are viewable by everyone"
  on public.profiles for select
  using (true);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Users can insert their own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Trigger for updated_at
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger on_profile_updated
  before update on public.profiles
  for each row execute function public.handle_updated_at();
```

### Migration Naming Convention

```
YYYYMMDDHHMMSS_descriptive_name.sql

Examples:
20240115143000_create_profiles_table.sql
20240116090000_add_avatar_to_profiles.sql
20240117120000_create_posts_table.sql
```

### Client Setup (TypeScript)

```typescript
import { createClient } from '@supabase/supabase-js';
import type { Database } from './types/database.types';

// Browser client
export const supabase = createClient<Database>(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

// Server client (for Server Components/Actions)
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function createServerSupabase() {
  const cookieStore = await cookies();

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => {
            cookieStore.set(name, value, options);
          });
        },
      },
    }
  );
}
```

### Database Queries

```typescript
// Select with type safety
const { data: profiles, error } = await supabase
  .from('profiles')
  .select('id, username, display_name, avatar_url')
  .eq('username', username)
  .single();

// Insert
const { data, error } = await supabase
  .from('posts')
  .insert({
    title: 'New Post',
    content: 'Content here',
    user_id: userId,
  })
  .select()
  .single();

// Update
const { error } = await supabase
  .from('profiles')
  .update({ display_name: newName })
  .eq('id', userId);

// Delete
const { error } = await supabase
  .from('posts')
  .delete()
  .eq('id', postId);

// Complex query with joins
const { data: postsWithAuthor } = await supabase
  .from('posts')
  .select(`
    id,
    title,
    content,
    created_at,
    author:profiles!user_id (
      username,
      display_name,
      avatar_url
    )
  `)
  .order('created_at', { ascending: false })
  .limit(10);
```

### Authentication

```typescript
// Sign up
const { data, error } = await supabase.auth.signUp({
  email,
  password,
  options: {
    emailRedirectTo: `${window.location.origin}/auth/callback`,
    data: { username }, // Metadata
  },
});

// Sign in
const { data, error } = await supabase.auth.signInWithPassword({
  email,
  password,
});

// OAuth
const { data, error } = await supabase.auth.signInWithOAuth({
  provider: 'google',
  options: {
    redirectTo: `${window.location.origin}/auth/callback`,
  },
});

// Get session
const { data: { session } } = await supabase.auth.getSession();

// Auth state listener
supabase.auth.onAuthStateChange((event, session) => {
  if (event === 'SIGNED_IN') {
    // Handle sign in
  } else if (event === 'SIGNED_OUT') {
    // Handle sign out
  }
});
```

### Realtime Subscriptions

```typescript
// Subscribe to table changes
const channel = supabase
  .channel('posts-changes')
  .on(
    'postgres_changes',
    {
      event: '*', // INSERT | UPDATE | DELETE
      schema: 'public',
      table: 'posts',
      filter: `user_id=eq.${userId}`,
    },
    (payload) => {
      console.log('Change:', payload);
    }
  )
  .subscribe();

// Cleanup
channel.unsubscribe();
```

### Edge Functions

```typescript
// supabase/functions/my-function/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  try {
    // Get auth token from request
    const authHeader = req.headers.get('Authorization')!;

    // Create Supabase client with user context
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    );

    // Get authenticated user
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response('Unauthorized', { status: 401 });
    }

    // Your logic here
    const body = await req.json();

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
```

### Type Generation

```bash
# Generate types from database schema
supabase gen types typescript --project-id {{PROJECT_ID}} > src/types/database.types.ts

# Or from local database
supabase gen types typescript --local > src/types/database.types.ts
```

## Common Commands

```bash
# Start local Supabase
supabase start

# Stop local Supabase
supabase stop

# Database status
supabase status

# Create migration
supabase migration new {{MIGRATION_NAME}}

# Apply migrations locally
supabase db reset

# Push migrations to remote
supabase db push

# Generate types
supabase gen types typescript --local > src/types/database.types.ts

# Deploy Edge Functions
supabase functions deploy my-function

# View function logs
supabase functions logs my-function
```

## DO NOT

- Store sensitive data without RLS policies
- Use service_role key in client-side code
- Skip RLS on tables with user data
- Forget to handle auth session expiry
- Create migrations manually without using `supabase migration new`
- Use `*` in select without considering performance
- Skip error handling on database operations
- Forget to unsubscribe from realtime channels

## RLS Policy Patterns

| Pattern | Use Case |
|---------|----------|
| `auth.uid() = user_id` | User owns the row |
| `auth.uid() in (select user_id from members where ...)` | Team membership |
| `true` (for SELECT) | Public read access |
| `exists(select 1 from ... where ...)` | Related row exists |
| `auth.jwt() ->> 'role' = 'admin'` | Role-based access |
