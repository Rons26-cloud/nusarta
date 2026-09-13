-- ============================================================
-- NUSARTA — Profile avatar storage (V1.6)
--
-- Adds the avatar file path column to `profiles` and a dedicated
-- `avatars` storage bucket.
--
-- Security model (see docs/database.md):
--   * Bucket is PUBLIC for reads only. Avatar images are non-sensitive
--     (finance data stays behind the table-level RLS policies from 002).
--   * Writes are STRICT: every insert/update/delete is confined to the
--     caller's own folder `<uid>/`, so a user can only manage their own
--     avatar file. Enforcement uses the documented folder-based pattern
--     `(storage.foldername(name))[1] = (select auth.uid()::text)` —
--     NOT the `owner` column — so the constraint holds regardless of how
--     `owner_id` is populated on upload.
--   * File size (5 MB) and MIME types (jpeg/png/webp) are enforced at
--     the bucket level in addition to client-side validation.
--
-- Migration is idempotent: column/object during buckets upsert with
-- ON CONFLICT, policies are dropped/recreated, grants are revoke+grant.
-- ============================================================

-- ------------------------------------------------------------
-- 1. PROFILES: avatar path column
-- ------------------------------------------------------------

alter table public.profiles
  add column if not exists avatar_path text;

-- ------------------------------------------------------------
-- 2. AVATARS BUCKET (public read, strict owned writes)
-- ------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 5242880,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- ------------------------------------------------------------
-- 3. STORAGE OBJECT POLICIES — caller-owned folder only
-- ------------------------------------------------------------

drop policy if exists "avatars_insert_own" on storage.objects;
create policy "avatars_insert_own" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );

drop policy if exists "avatars_select_own" on storage.objects;
create policy "avatars_select_own" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );

drop policy if exists "avatars_update_own" on storage.objects;
create policy "avatars_update_own" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );

drop policy if exists "avatars_delete_own" on storage.objects;
create policy "avatars_delete_own" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );

-- ------------------------------------------------------------
-- 4. GRANTS (raw storage access stays server-only; API paths gated
--    by the policies above)
-- ------------------------------------------------------------

revoke all on storage.objects from authenticated;
grant insert, select, update, delete on storage.objects to authenticated;
revoke all on storage.buckets from authenticated;
grant select on storage.buckets to authenticated;