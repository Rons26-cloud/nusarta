# Supabase Setup

NUSARTA V1 uses Supabase for Auth, PostgreSQL, Storage (as needed) and Row Level Security.

## Local / managed

1. Create a Supabase project (or run `supabase start` locally).
2. Run migrations in order:

   ```bash
   supabase db push              # managed projects
   # or run the SQL files directly in the SQL editor in order:
   supabase/migrations/001_initial_schema.sql
   supabase/migrations/002_row_level_security.sql
   ```

3. (Optional) Configure email confirmation in Supabase Auth settings.

## Environment variables

Copy the files below and fill with your project URL + anon key:

- `apps/mobile/lib/core/config/app_config.example.dart` → `app_config.dart`
- `apps/web/.env.example` → `apps/web/.env.local`

> The **anon key** is safe for use in clients. Never expose the
> `service_role` key, database password, or signing secrets.

## Storage

Not required for V1. Reserved for future use (exported reports, etc.).

## RLS verification

RLS is mandatory. Run the two-account test documented in
[`docs/RLS_TESTING.md`](../docs/RLS_TESTING.md) before any release.