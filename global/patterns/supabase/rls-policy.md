---
name: Supabase RLS Policy
category: framework
language: sql
framework: supabase
keywords: [supabase, rls, row-level-security, postgres, authorization, policy]
confidence: 0.9
---

# Supabase RLS Policy Pattern

## Problem

Without row-level security:
- API endpoints must manually check permissions
- Easy to forget authorization checks
- Data leaks from missing checks
- Complex authorization logic scattered across codebase

## Solution

Use PostgreSQL Row Level Security (RLS) to enforce authorization at the database level. Every query automatically filtered by user permissions.

## Implementation

### Basic Setup

```sql
-- Enable RLS on table
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

-- Force RLS for table owner too (important for service role)
ALTER TABLE public.posts FORCE ROW LEVEL SECURITY;

-- Basic policy structure
CREATE POLICY "policy_name" ON public.posts
  FOR [ALL | SELECT | INSERT | UPDATE | DELETE]
  TO [authenticated | anon | public]
  USING (/* read condition */)
  WITH CHECK (/* write condition */);
```

### User-Owned Resources

```sql
-- Users can only access their own data
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE,
  bio TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Users can read any profile
CREATE POLICY "profiles_select" ON public.profiles
  FOR SELECT
  TO authenticated
  USING (true);

-- Users can only update their own profile
CREATE POLICY "profiles_update" ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Users can only delete their own profile
CREATE POLICY "profiles_delete" ON public.profiles
  FOR DELETE
  TO authenticated
  USING (auth.uid() = id);

-- New users can create their profile (id must match their auth id)
CREATE POLICY "profiles_insert" ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);
```

### Organization/Team-Based Access

```sql
-- Organizations table
CREATE TABLE public.organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Organization members (junction table)
CREATE TABLE public.organization_members (
  organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'member')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (organization_id, user_id)
);

-- Projects belong to organizations
CREATE TABLE public.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

-- Helper function to check organization membership
CREATE OR REPLACE FUNCTION public.is_org_member(org_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE organization_id = org_id
    AND user_id = auth.uid()
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Helper function to check org admin/owner
CREATE OR REPLACE FUNCTION public.is_org_admin(org_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE organization_id = org_id
    AND user_id = auth.uid()
    AND role IN ('owner', 'admin')
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Organization policies
CREATE POLICY "orgs_select" ON public.organizations
  FOR SELECT TO authenticated
  USING (public.is_org_member(id));

CREATE POLICY "orgs_update" ON public.organizations
  FOR UPDATE TO authenticated
  USING (public.is_org_admin(id))
  WITH CHECK (public.is_org_admin(id));

-- Organization members policies
CREATE POLICY "members_select" ON public.organization_members
  FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

CREATE POLICY "members_insert" ON public.organization_members
  FOR INSERT TO authenticated
  WITH CHECK (public.is_org_admin(organization_id));

CREATE POLICY "members_delete" ON public.organization_members
  FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));

-- Project policies
CREATE POLICY "projects_select" ON public.projects
  FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

CREATE POLICY "projects_insert" ON public.projects
  FOR INSERT TO authenticated
  WITH CHECK (public.is_org_member(organization_id));

CREATE POLICY "projects_update" ON public.projects
  FOR UPDATE TO authenticated
  USING (public.is_org_member(organization_id));

CREATE POLICY "projects_delete" ON public.projects
  FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));
```

### Public and Private Content

```sql
CREATE TABLE public.posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  content TEXT,
  is_published BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

-- Anyone can read published posts
CREATE POLICY "posts_select_published" ON public.posts
  FOR SELECT
  TO anon, authenticated
  USING (is_published = true);

-- Authors can read their own unpublished posts
CREATE POLICY "posts_select_own_drafts" ON public.posts
  FOR SELECT
  TO authenticated
  USING (auth.uid() = author_id AND is_published = false);

-- Authors can insert their own posts
CREATE POLICY "posts_insert" ON public.posts
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = author_id);

-- Authors can update their own posts
CREATE POLICY "posts_update" ON public.posts
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = author_id)
  WITH CHECK (auth.uid() = author_id);

-- Authors can delete their own posts
CREATE POLICY "posts_delete" ON public.posts
  FOR DELETE
  TO authenticated
  USING (auth.uid() = author_id);
```

### Role-Based Access

```sql
-- Custom claims in JWT for roles
-- Set via Supabase Auth hooks or admin API

CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS TEXT AS $$
  SELECT COALESCE(
    (auth.jwt() -> 'app_metadata' ->> 'role'),
    'user'
  );
$$ LANGUAGE sql STABLE;

-- Admin-only table
CREATE TABLE public.admin_settings (
  key TEXT PRIMARY KEY,
  value JSONB,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.admin_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_settings_all" ON public.admin_settings
  FOR ALL
  TO authenticated
  USING (public.get_user_role() = 'admin')
  WITH CHECK (public.get_user_role() = 'admin');
```

### Soft Delete Pattern

```sql
CREATE TABLE public.documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

-- Only show non-deleted documents
CREATE POLICY "documents_select" ON public.documents
  FOR SELECT TO authenticated
  USING (owner_id = auth.uid() AND deleted_at IS NULL);

-- Allow soft delete (update deleted_at)
CREATE POLICY "documents_soft_delete" ON public.documents
  FOR UPDATE TO authenticated
  USING (owner_id = auth.uid() AND deleted_at IS NULL)
  WITH CHECK (owner_id = auth.uid());
```

### Testing RLS Policies

```typescript
// lib/test-utils.ts
import { createClient } from '@supabase/supabase-js';

// Test as a specific user
export async function testAsUser(userId: string) {
  // Use service role to impersonate
  const supabase = createClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_KEY!,
    {
      global: {
        headers: {
          // Impersonate user for RLS
          Authorization: `Bearer ${await createUserJwt(userId)}`,
        },
      },
    },
  );

  // Test that user can read their own posts
  const { data, error } = await supabase
    .from('posts')
    .select('*')
    .eq('author_id', userId);

  expect(error).toBeNull();
  expect(data?.length).toBeGreaterThan(0);

  // Test that user cannot read others' drafts
  const { data: otherDrafts } = await supabase
    .from('posts')
    .select('*')
    .eq('is_published', false)
    .neq('author_id', userId);

  expect(otherDrafts?.length).toBe(0);
}
```

## When to Use

- All tables with user data
- Multi-tenant applications
- Content with mixed public/private access
- Any authorization requirement

## Anti-patterns

```sql
-- BAD: No RLS enabled
CREATE TABLE secrets (data TEXT);
-- Anyone with anon key can read everything!

-- BAD: Overly permissive policy
CREATE POLICY "allow_all" ON posts
  FOR ALL USING (true); -- Everyone can do everything!

-- BAD: Using user input in policy without validation
CREATE POLICY "by_role" ON posts
  FOR SELECT USING (
    current_setting('app.user_role') = 'admin'
    -- Setting could be manipulated!
  );

-- BAD: Complex policies without indexes
CREATE POLICY "complex" ON posts
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM team_members tm
      JOIN teams t ON t.id = tm.team_id
      WHERE tm.user_id = auth.uid()
      -- Missing indexes = slow queries
    )
  );
```

```sql
-- GOOD: Always enable RLS
ALTER TABLE secrets ENABLE ROW LEVEL SECURITY;

-- GOOD: Specific, minimal policies
CREATE POLICY "select_own" ON posts
  FOR SELECT USING (author_id = auth.uid());

-- GOOD: Use auth.uid() and auth.jwt() for secure user info
CREATE POLICY "by_role" ON posts
  FOR SELECT USING (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  );

-- GOOD: Create indexes for policy conditions
CREATE INDEX idx_team_members_user ON team_members(user_id);
CREATE INDEX idx_posts_org ON posts(organization_id);
```

## Related Patterns

- Authentication Pattern - For user authentication
- API Route Pattern - For additional server-side checks
- Error Handling Pattern - For RLS error handling
