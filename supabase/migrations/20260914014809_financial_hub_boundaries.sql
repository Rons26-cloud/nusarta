-- Extend existing domain. No live provider capabilities are enabled.
alter table public.accounts
  add column if not exists balance_source text not null default 'unavailable'
    check (balance_source in ('live','sandbox','simulated','unavailable')),
  add column if not exists account_holder_name text;
alter table public.future_transfers
  add column if not exists execution_mode text not null default 'UNVERIFIED'
    check (execution_mode in ('UNVERIFIED','SANDBOX_SIMULATED_SOURCE','BRANKAS_PLATFORM_PAYOUT','LIVE_CONNECTED_ACCOUNT')),
  add column if not exists destination_account_id uuid references public.accounts(id),
  add column if not exists request_fingerprint text,
  add column if not exists note text;

-- Only backend may attest connections, balances, or provider outcomes.
drop policy if exists account_connections_all_own on public.account_connections;
create policy account_connections_select_own on public.account_connections
  for select to authenticated using ((select auth.uid()) = user_id);
revoke all on public.account_connections from anon, authenticated;
grant select on public.account_connections to authenticated;
drop policy if exists future_transfers_all_own on public.future_transfers;
create policy future_transfers_select_own on public.future_transfers
  for select to authenticated using ((select auth.uid()) = user_id);
revoke all on public.future_transfers from anon, authenticated;
grant select on public.future_transfers to authenticated;

create or replace function public.guard_connected_account() returns trigger
language plpgsql set search_path = public as $$
begin
  if current_user in ('anon','authenticated') then
    if tg_op = 'INSERT' then
      if new.is_linked or new.connection_status <> 'manual' or new.balance_source <> 'unavailable' then
        raise exception 'connection_server_only' using errcode = '42501';
      end if;
    elsif row(new.is_linked,new.connection_status,new.connection_type,new.provider,new.external_id,new.last_synced_at,new.balance_source,new.account_holder_name)
        is distinct from row(old.is_linked,old.connection_status,old.connection_type,old.provider,old.external_id,old.last_synced_at,old.balance_source,old.account_holder_name)
        or (old.is_linked and row(new.balance,new.institution_id,new.currency_code,new.type,new.masked_account_number,new.last_four)
          is distinct from row(old.balance,old.institution_id,old.currency_code,old.type,old.masked_account_number,old.last_four)) then
      raise exception 'connection_server_only' using errcode = '42501';
    end if;
  end if;
  return new;
end $$;
create trigger guard_connected_account before insert or update on public.accounts
for each row execute function public.guard_connected_account();

create index if not exists hub_source_pending_idx on public.future_transfers
(source_financial_account_id, status);
insert into public.feature_flags(id,enabled,description) values
('financial_hub_sandbox', false, 'Explicit simulation only; never bank balance or debit') on conflict do nothing;

-- This API is callable only by the Edge Function service role, after JWT validation.
create or replace function public.hub_create_transfer(
 p_user uuid, p_source uuid, p_destination uuid, p_identifier text,
 p_amount numeric, p_key text, p_own_destination uuid default null, p_note text default null
) returns public.future_transfers language plpgsql security definer set search_path = public as $$
declare s public.accounts; d public.institutions; t public.future_transfers;
 fingerprint text; reserved numeric; target_account public.accounts;
begin
 if not exists(select 1 from public.feature_flags where id='financial_hub_sandbox' and enabled) then
   raise exception 'sandbox_disabled'; end if;
 if p_amount is null or p_amount::text in ('NaN','Infinity','-Infinity') or p_amount <= 0 or p_amount > 100000000
   or trunc(p_amount) <> p_amount or p_key is null or length(p_key) not between 16 and 128
   or p_identifier is null or p_identifier !~ '^[0-9]{6,20}$' or length(coalesce(p_note,'')) > 80 then
   raise exception 'invalid_transfer'; end if;
 perform pg_advisory_xact_lock(hashtextextended(p_user::text, 0));
 fingerprint := md5(jsonb_build_array(p_source,p_destination,p_identifier,p_amount,p_own_destination,p_note)::text);
 select * into t from public.future_transfers where user_id=p_user and idempotency_key=p_key;
 if found then
   if t.request_fingerprint is distinct from fingerprint then raise exception 'idempotency_conflict'; end if;
   return t;
 end if;
 if (select count(*) from public.future_transfers where user_id=p_user and created_at > now()-interval '1 minute') >= 5 then
   raise exception 'rate_limited'; end if;
 select * into s from public.accounts where id=p_source and user_id=p_user for update;
 if not found or s.is_archived or not s.is_linked or s.connection_status <> 'active'
    or s.provider is distinct from 'nusarta_simulator' or s.balance_source <> 'simulated' or s.currency_code <> 'IDR'
    or s.type not in ('bank','ewallet') or s.last_synced_at is null then raise exception 'source_not_eligible'; end if;
 if not exists(select 1 from public.account_connections where financial_account_id=s.id and user_id=p_user
   and institution_id=s.institution_id and status='active' and provider='nusarta_simulator' and provider_connection_id is not null
   and (consent_expires_at is null or consent_expires_at > now())) then raise exception 'connection_not_active'; end if;
 if not exists(select 1 from public.institutions where id=s.institution_id and is_active and provider_support->>'simulation_supported'='true') then raise exception 'source_not_eligible'; end if;
 select * into d from public.institutions where id=p_destination and is_active;
 if not found or d.institution_type not in ('bank','ewallet') or d.provider_support->>'simulation_supported' is distinct from 'true'
    then raise exception 'destination_not_supported'; end if;
 if d.institution_type='ewallet' and p_identifier !~ '^08[0-9]{8,13}$' then raise exception 'invalid_wallet_identifier'; end if;
 if p_own_destination is not null then
   select * into target_account from public.accounts where id=p_own_destination and user_id=p_user and id<>p_source;
   if not found or target_account.is_archived or not target_account.is_linked or target_account.connection_status<>'active'
      or target_account.provider is distinct from 'nusarta_simulator' or target_account.balance_source<>'simulated' or target_account.institution_id<>p_destination
      or target_account.external_id is distinct from p_identifier then raise exception 'destination_not_owned'; end if;
 end if;
 select coalesce(sum(total_amount),0) into reserved from public.future_transfers
 where source_financial_account_id=p_source and status in ('draft','awaiting_authorization','pending','processing');
 if s.balance-reserved < p_amount then raise exception 'insufficient_balance'; end if;
 insert into public.future_transfers(user_id,source_financial_account_id,destination_type,destination_institution_id,
 destination_account_reference,destination_account_id,amount,fee_amount,total_amount,currency,provider,status,
 idempotency_key,request_fingerprint,execution_mode,authorized_at,note)
 values(p_user,p_source,d.institution_type::text::destination_type,d.id,'•••• '||right(p_identifier,4),p_own_destination,
 p_amount,0,p_amount,'IDR','nusarta_simulator','pending',p_key,fingerprint,'SANDBOX_SIMULATED_SOURCE',now(),p_note) returning * into t;
 insert into public.security_events(user_id,event_category,event_type,metadata)
 values(p_user,'transfer','sandbox_transfer_created',jsonb_build_object('transfer_id',t.id,'execution_mode',t.execution_mode));
 return t;
end $$;
revoke all on function public.hub_create_transfer(uuid,uuid,uuid,text,numeric,text,uuid,text) from public, anon, authenticated;
grant execute on function public.hub_create_transfer(uuid,uuid,uuid,text,numeric,text,uuid,text) to service_role;

-- Authenticated simulator events only. Provider callbacks must NOT use this API.
create or replace function public.hub_apply_simulation_event(p_transfer uuid,p_status text)
returns public.future_transfers language plpgsql security definer set search_path = public as $$
declare t public.future_transfers;
begin
 if p_status not in ('processing','success','failed','reversed') then raise exception 'invalid_status'; end if;
 select * into t from public.future_transfers where id=p_transfer for update;
 if not found or t.execution_mode <> 'SANDBOX_SIMULATED_SOURCE' or t.provider <> 'nusarta_simulator' then raise exception 'unsupported_transfer'; end if;
 if t.status::text=p_status or t.status in ('failed','reversed','cancelled')
    or (t.status='success' and p_status<>'reversed') or (p_status='reversed' and t.status<>'success') then return t; end if;
 if p_status in ('success','reversed') then
   -- Consistent account lock order also covers simultaneous opposite transfers.
   perform id from public.accounts where id in (t.source_financial_account_id,t.destination_account_id) order by id for update;
   update public.accounts set balance=balance + case when p_status='success' then -t.total_amount else t.total_amount end,
      last_synced_at=now() where id=t.source_financial_account_id and user_id=t.user_id and balance_source='simulated';
   if t.destination_account_id is not null then
     update public.accounts set balance=balance + case when p_status='success' then t.amount else -t.amount end,
       last_synced_at=now() where id=t.destination_account_id and user_id=t.user_id and balance_source='simulated';
   end if;
 end if;
 update public.future_transfers set status=p_status::transfer_status,
   provider_reference='sim-'||id::text,processed_at=now(),
   completed_at=case when p_status in ('success','failed','reversed') then now() else completed_at end
   where id=t.id returning * into t;
 insert into public.security_events(user_id,event_category,event_type,metadata)
 values(t.user_id,'transfer','sandbox_transfer_'||p_status,jsonb_build_object('transfer_id',t.id));
 return t;
end $$;
revoke all on function public.hub_apply_simulation_event(uuid,text) from public, anon, authenticated;
grant execute on function public.hub_apply_simulation_event(uuid,text) to service_role;

-- Sandbox linking creates synthetic identifiers, never asks for bank credentials.
create or replace function public.hub_connect_simulated(p_user uuid,p_institution uuid)
returns public.accounts language plpgsql security definer set search_path=public as $$
declare i public.institutions; a public.accounts; ident text;
begin
 if not exists(select 1 from public.feature_flags where id='financial_hub_sandbox' and enabled) then raise exception 'sandbox_disabled'; end if;
 perform pg_advisory_xact_lock(hashtextextended(p_user::text,0));
 if (select count(*) from public.accounts where user_id=p_user and provider='nusarta_simulator') >= 20 then raise exception 'account_limit'; end if;
 select * into i from public.institutions where id=p_institution and is_active and institution_type in ('bank','ewallet');
 if not found or i.provider_support->>'simulation_supported' is distinct from 'true' then raise exception 'destination_not_supported'; end if;
 ident := case when i.institution_type='ewallet' then '080000' else '990000' end || lpad(floor(random()*1000000)::text,6,'0');
 insert into public.accounts(user_id,name,type,balance,opening_balance,currency_code,provider,external_id,is_linked,
 institution_id,masked_account_number,last_four,display_name,is_primary,connection_type,connection_status,last_synced_at,balance_source,account_holder_name)
 values(p_user,i.name,i.institution_type::text::account_type,1000000,0,'IDR','nusarta_simulator',ident,true,
 i.id,'•••• '||right(ident,4),right(ident,4),i.name,false,'payment_provider','active',now(),'simulated','Pengguna Sandbox') returning * into a;
 insert into public.account_connections(user_id,institution_id,financial_account_id,provider,provider_connection_id,status,scopes,last_synced_at)
 values(p_user,i.id,a.id,'nusarta_simulator','sim-'||a.id::text,'active',array['simulation'],now());
 return a;
end $$;
revoke all on function public.hub_connect_simulated(uuid,uuid) from public,anon,authenticated;
grant execute on function public.hub_connect_simulated(uuid,uuid) to service_role;

-- Serialize choosing the default; never clear another user's accounts.
create or replace function public.hub_set_primary(p_account uuid) returns void
language plpgsql security invoker set search_path=public as $$
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,0));
 if not exists(select 1 from public.accounts where id=p_account and user_id=auth.uid() and not is_archived) then raise exception 'account_not_owned'; end if;
 update public.accounts set is_primary=(id=p_account) where user_id=auth.uid() and (is_primary or id=p_account);
end $$;
revoke all on function public.hub_set_primary(uuid) from public,anon;
grant execute on function public.hub_set_primary(uuid) to authenticated;
revoke truncate,references,trigger on public.accounts from anon,authenticated;

-- Provider balances never come from the manual ledger.
create or replace function public.recompute_account_balance(p_account_id uuid)
returns void language plpgsql security invoker as $$
begin
  update public.accounts a
     set balance =
         (select coalesce(a.opening_balance, 0)
                 + coalesce((
                       select sum(case when t.kind = 'income' then t.amount
                                       when t.kind = 'expense' then -t.amount
                                       else 0 end)
                         from public.transactions t
                        where t.account_id = a.id), 0)
                 + coalesce((
                       select sum(tt.amount) from public.transaction_transfers tt
                        where tt.to_account_id = a.id), 0)
                 - coalesce((
                       select sum(tt.amount) from public.transaction_transfers tt
                        where tt.from_account_id = a.id), 0))
   where a.id = p_account_id and not a.is_linked;
end $$;


create or replace function public.guard_connected_ledger() returns trigger
language plpgsql set search_path=public as $$
declare before_row jsonb; after_row jsonb;
begin
 if current_user in ('anon','authenticated') then
   before_row := case when tg_op<>'INSERT' then to_jsonb(old) else '{}'::jsonb end;
   after_row := case when tg_op<>'DELETE' then to_jsonb(new) else '{}'::jsonb end;
   if exists(select 1 from public.accounts where is_linked and id in (
     (before_row->>'account_id')::uuid,(before_row->>'from_account_id')::uuid,(before_row->>'to_account_id')::uuid,
     (after_row->>'account_id')::uuid,(after_row->>'from_account_id')::uuid,(after_row->>'to_account_id')::uuid)) then
     raise exception 'connected_ledger_server_only' using errcode='42501'; end if;
 end if;
 return case when tg_op='DELETE' then old else new end;
end $$;
create trigger guard_connected_ledger before insert or update or delete on public.transactions
for each row execute function public.guard_connected_ledger();
create trigger guard_connected_transfer_ledger before insert or update or delete on public.transaction_transfers
for each row execute function public.guard_connected_ledger();
