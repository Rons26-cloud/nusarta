-- ============================================================
-- NUSARTA — Future Foundation hardening (V1.5)
--
-- Adds safe boundaries and small performance/consistency fixes on top of
-- migrations 005/006/007 WITHOUT rewiring existing tables or enums:
--
--   1. create_user_notification RPC — the ONLY privileged path for the
--      client to write an in-app notification, and it is restricted to the
--      authenticated caller (auth.uid()). The raw INSERT on `notifications`
--      stays server-only (no client INSERT grant in migration 006).
--      Only V1-supported types (transaction, budget, security, system) are
--      accepted; account_connection and transfer are reserved for later.
--
--   2. Targeted indexes for lookups that V1.5 UI performs:
--        - accounts by institution (catalog label joins)
--        - accounts by is_primary (future "primary account" semantics)
--
--   3. Notes (no code change): future_transfers.source_financial_account_id
--      intentionally uses the default NO ACTION (≈ RESTRICT) FK so a manual
--      account deletion is never allowed to silently orphan a transfer row.
--      This is documented in docs/database.md, not relaxed here.
--
-- Migration is idempotent: functions are created-or-replaced, indexes use
-- IF NOT EXISTS, and grants are revoke+grant.
-- ============================================================

-- ------------------------------------------------------------
-- 1. SAFE IN-APP NOTIFICATION BOUNDARY
-- ------------------------------------------------------------

create or replace function public.create_user_notification(
  p_type notification_type,
  p_title text,
  p_body text default null,
  p_data jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_id uuid;
begin
  -- Authenticated caller only.
  if v_uid is null then
    raise exception 'Unauthenticated' using errcode = 'NUSA1';
  end if;

  -- V1 supports transaction/budget/security/system; the rest are reserved
  -- until their respective capabilities land.
  if p_type not in (
      'transaction'::notification_type,
      'budget'::notification_type,
      'security'::notification_type,
      'system'::notification_type) then
    raise exception 'Notification type not available yet' using errcode = 'NUSA4';
  end if;

  insert into public.notifications (user_id, type, title, body, data)
  values (v_uid, p_type, p_title, p_body, coalesce(p_data, '{}'::jsonb))
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.create_user_notification(notification_type, text, text, jsonb) from public;
grant execute on function public.create_user_notification(notification_type, text, text, jsonb) to authenticated;

-- ------------------------------------------------------------
-- 2. TARGETED INDEXES FOR V1.5 LOOKUPS
-- ------------------------------------------------------------

create index if not exists accounts_institution_idx
  on public.accounts (institution_id) where institution_id is not null;

create index if not exists accounts_is_primary_idx
  on public.accounts (is_primary) where is_primary = true;