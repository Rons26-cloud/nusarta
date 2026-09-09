-- ============================================================
-- NUSARTA — Account deletion (server-authoritative)
--
-- Play Store "Account deletion" requirement.
--
-- Design principles:
--  1. The client NEVER holds a privileged credential. The Flutter app
--     only calls `public.delete_my_account(p_confirm)` with its own
--     authenticated session (ANON/PGRST JWT).
--  2. The privileged delete runs as the function DEFINER (database owner,
--     server-side only). In command 004 SQLSTATE codes below are 5 chars.
--  3. The target is ALWAYS auth.uid() — arbitrary user_id is never
--     accepted, so cross-user deletion is impossible by construction.
--  4. Re-authentication freshness: the caller must have a recent access
--     token (issued within the last 5 minutes). The client reauthenticates
--     with the password right before invoking this function.
--  5. Explicit destructive confirmation: the caller must pass p_confirm = 'HAPUS'.
--  6. Rows are deleted in explicit order so transaction_transfers
--     (which RESTRICT account deletes) never orphan or dead-lock.
--
-- Alternative supported by Supabase: an authenticated Edge Function using
-- the SERVICE_ROLE secret server-side (admin.auth.admin.deleteUser + table
-- cleanup). The RPC below achieves the same isolation without adding an
-- Edge runtime; both approaches never expose secrets to the client.
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
  --    call must have been issued within the last 5 minutes. The client
  --    reauthenticates (signInWithPassword) immediately before deleting.
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
  delete from public.audit_events where user_id = v_uid;

  -- Transfer legs may reference the caller's accounts from BOTH sides,
  -- and account deletion is RESTRICTed by transaction_transfers, so the
  -- legs are removed first.
  delete from public.transaction_transfers tt
    using public.accounts a
   where (tt.from_account_id = a.id or tt.to_account_id = a.id)
     and a.user_id = v_uid;

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