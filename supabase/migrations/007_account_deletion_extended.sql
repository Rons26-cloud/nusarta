-- ============================================================
-- NUSARTA — Extend account deletion for future-foundation tables
--
-- Migration 004 (delete_my_account) predates migrations 005/006 which add
-- new user-owned tables. This migration re-creates the function to also
-- clean up rows from the new tables (devices, account_connections,
-- future_transfers, transfer_recipients, notifications, security_events)
-- before the profile row is removed.
--
-- It is backward-compatible: the function signature and behavior for the
-- existing tables is unchanged; only the cleanup list is extended.
-- ============================================================

create or replace function public.delete_my_account(p_confirm text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_iat bigint;
begin
  -- 1. Authenticated caller only.
  if v_uid is null then
    raise exception 'Unauthenticated' using errcode = 'NUSA1';
  end if;

  -- 2. Re-authentication freshness: the access token that authorised this
  --    call must have been issued within the last 5 minutes.
  v_iat := (auth.jwt() ->> 'iat')::bigint;
  if v_iat is null or (extract(epoch from now()) - v_iat) > 300 then
    raise exception 'Re-authentication required' using errcode = 'NUSA2';
  end if;

  -- 3. Explicit destructive confirmation phrase.
  if coalesce(upper(p_confirm), '') <> 'HAPUS' then
    raise exception 'Confirmation required' using errcode = 'NUSA3';
  end if;

  -- 4. Server-authoritative, ordered deletion. Only the authenticated
  --    caller's records are touched (v_uid := auth.uid()).

  delete from public.security_events where user_id = v_uid;
  delete from public.audit_events where user_id = v_uid;
  delete from public.notifications where user_id = v_uid;
  delete from public.devices where user_id = v_uid;

  -- Account connections / recipients may reference accounts, drop them first.
  delete from public.account_connections where user_id = v_uid;
  delete from public.future_transfers where user_id = v_uid;
  delete from public.transfer_recipients where user_id = v_uid;

  -- Transfer legs may reference the caller's accounts from BOTH sides,
  -- and account deletion is RESTRICTed by transaction_transfers, so the
  -- legs are removed first.
  delete from public.transaction_transfers tt
    using public.accounts a
   where (tt.from_account_id = a.id or tt.to_account_id = a.id)
     and a.user_id = v_uid;

  -- Disconnect accounts from institution catalog before deletion.
  update public.accounts set institution_id = null where user_id = v_uid;

  delete from public.transactions where user_id = v_uid;
  delete from public.budgets where user_id = v_uid;
  delete from public.financial_goals where user_id = v_uid;
  delete from public.categories where user_id = v_uid;
  delete from public.accounts where user_id = v_uid;
  delete from public.app_settings where user_id = v_uid;
  delete from public.profiles where id = v_uid;

  -- Finally remove the authentication identity (sessions and refresh
  -- tokens are cascaded by the auth schema).
  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.delete_my_account(text) from public;
grant execute on function public.delete_my_account(text) to authenticated;
