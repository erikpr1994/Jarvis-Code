# Supabase Migrations

> Inherits from: project root CLAUDE.md > supabase/CLAUDE.md
> Level: L2 (supabase/migrations/)
> Token budget: ~400 tokens

## Purpose

SQL migration files that define and evolve the database schema. Migrations are applied sequentially and tracked by Supabase.

## Naming Convention

```
YYYYMMDDHHMMSS_descriptive_name.sql

Examples:
20240115143000_create_users_table.sql
20240116090000_add_avatar_to_profiles.sql
20240117120000_create_posts_with_rls.sql
20240118150000_add_indexes_to_posts.sql
```

**Rules:**
- Timestamp format: `YYYYMMDDHHMMSS` (14 digits)
- Use lowercase with underscores
- Be descriptive: action_target (create_users, add_column_to_table)
- Never modify existing migration files

## Migration Structure

```sql
-- Migration: Create profiles table
-- Description: User profiles linked to auth.users

-- Up migration
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique not null,
  display_name text,
  avatar_url text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

-- Enable RLS (always for user data)
alter table public.profiles enable row level security;

-- RLS Policies
create policy "profiles_select_all"
  on public.profiles for select
  using (true);

create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id);

-- Indexes
create index if not exists profiles_username_idx on public.profiles (username);

-- Triggers
create trigger on_profiles_updated
  before update on public.profiles
  for each row execute function public.handle_updated_at();
```

## Common Patterns

### Create Table with RLS

```sql
create table public.{{table_name}} (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null,
  -- columns
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

alter table public.{{table_name}} enable row level security;

create policy "{{table_name}}_select_own"
  on public.{{table_name}} for select
  using (auth.uid() = user_id);

create policy "{{table_name}}_insert_own"
  on public.{{table_name}} for insert
  with check (auth.uid() = user_id);
```

### Add Column

```sql
alter table public.profiles
  add column bio text,
  add column website text;
```

### Create Index

```sql
create index concurrently if not exists posts_user_id_idx
  on public.posts (user_id);

create index concurrently if not exists posts_created_at_idx
  on public.posts (created_at desc);
```

### Create Function

```sql
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql security definer;
```

## Commands

```bash
# Create new migration
supabase migration new {{migration_name}}

# Apply migrations locally
supabase db reset

# Push to remote
supabase db push

# View migration status
supabase migration list

# Generate types after migration
supabase gen types typescript --local > src/types/database.types.ts
```

## DO NOT

- Modify existing migrations (create new ones instead)
- Skip RLS on tables with user data
- Use `drop table` without `if exists`
- Create migrations manually (use `supabase migration new`)
- Forget indexes on frequently queried columns
- Use reserved SQL keywords as column names
- Skip foreign key constraints
- Create circular foreign key dependencies

## Checklist for New Migrations

- [ ] Table has RLS enabled
- [ ] RLS policies cover all operations (select, insert, update, delete)
- [ ] Foreign keys have appropriate `on delete` behavior
- [ ] Timestamps use `timestamptz` not `timestamp`
- [ ] Indexes added for query patterns
- [ ] Types regenerated after applying migration
