---
name: add-migration
description: Create a database migration with proper naming and structure
disable-model-invocation: false
---

# /add-migration - Add Database Migration

Create a new database migration file with proper naming conventions and structure.

## What It Does

1. **Detects ORM/database** - Identifies Prisma, Drizzle, Supabase, Knex, etc.
2. **Creates migration file** - Generates timestamped migration
3. **Provides template** - Includes up/down or appropriate structure
4. **Updates schema** - For schema-first ORMs

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | Migration name describing the change | "add_users_table", "add_email_to_profiles" |

## Process

### Phase 1: Detection

1. **Identify database tool**
   - Check for `prisma/` directory
   - Check for `drizzle/` or `drizzle.config.ts`
   - Check for `supabase/migrations/`
   - Check for `knexfile.js`
   - Check for `sequelize` in package.json

2. **Get current state**
   - Latest migration timestamp
   - Current schema version
   - Pending migrations

### Phase 2: Generation

3. **Generate migration file**

For Supabase:
```sql
-- supabase/migrations/[timestamp]_[name].sql

-- Migration: add_users_table
-- Created at: 2026-01-06 12:00:00

-- Up Migration
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own profile"
  ON public.users
  FOR SELECT
  USING (auth.uid() = id);

-- Add trigger for updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

For Prisma:
```
npx prisma migrate dev --name [name]
```

For Drizzle:
```typescript
// drizzle/migrations/[timestamp]_[name].ts
import { sql } from 'drizzle-orm'
import { pgTable, uuid, text, timestamp } from 'drizzle-orm/pg-core'

export async function up(db) {
  await db.execute(sql`
    CREATE TABLE users (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      email TEXT UNIQUE NOT NULL,
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  `)
}

export async function down(db) {
  await db.execute(sql`DROP TABLE IF EXISTS users`)
}
```

For Knex:
```javascript
// migrations/[timestamp]_[name].js
exports.up = function(knex) {
  return knex.schema.createTable('users', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'))
    table.string('email').unique().notNullable()
    table.timestamps(true, true)
  })
}

exports.down = function(knex) {
  return knex.schema.dropTable('users')
}
```

### Phase 3: Validation

4. **Validate migration**
   - Check SQL syntax (for raw SQL)
   - Verify foreign key references
   - Check for breaking changes

5. **Output instructions**
   - How to run the migration
   - How to rollback if needed
   - Related schema updates

## Examples

**Add new table:**
```
/add-migration create_posts_table
```

**Add column:**
```
/add-migration add_avatar_to_users
```

**Add index:**
```
/add-migration add_email_index_to_users
```

**Add foreign key:**
```
/add-migration add_user_id_to_posts
```

## Migration Types

### Structural Changes
- Create table
- Drop table
- Add column
- Drop column
- Rename column
- Change column type

### Constraints
- Add primary key
- Add foreign key
- Add unique constraint
- Add check constraint

### Performance
- Create index
- Drop index
- Add partial index

### Data
- Seed data
- Data migration
- Backfill values

## Output

After completion:
```
Created migration: add_users_table

File created:
  - supabase/migrations/20260106120000_add_users_table.sql

To apply:
  supabase db push      # Local development
  supabase db migrate   # Production

To rollback:
  Manual rollback required - see migration comments
```

## Best Practices

1. **Naming conventions**
   - Use snake_case
   - Be descriptive: `add_email_to_users` not `update_users`
   - Include table name when relevant

2. **Safety**
   - Always include rollback/down migration
   - Use `IF EXISTS` / `IF NOT EXISTS`
   - Test migrations on copy of production data

3. **Performance**
   - Add indexes for foreign keys
   - Consider partial indexes for large tables
   - Use concurrent index creation for large tables
