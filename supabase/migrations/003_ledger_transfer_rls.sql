-- ============================================================
-- NUSARTA — Ledger correctness, atomic transfers, RLS ownership
--
-- 1. `accounts.opening_balance` + a balance derived from the ledger.
--    Account balances now always equal opening_balance plus the sum of
--    income/expense rows on the account plus/ minus transfer legs.
-- 2. Internal transfers are created atomically through a single RPC
--    (`create_internal_transfer`) instead of two loose inserts.
-- 3. RLS policies verify the owning user for every referenced
--    account / category (prevents cross-user row linking).
-- 4. Unique (user_id, name) on categories so the seed stays idempotent.
-- ============================================================

-- ------------------------------------------------------------
-- 1. OPENING BALANCE + DERIVED BALANCE
-- ------------------------------------------------------------

alter table public.accounts
  add column if not exists opening_balance numeric(14,2) not null default 0;

-- Backfill: existing accounts keep their current balance as the baseline.
update public.accounts
   set opening_balance = balance
 where opening_balance = 0 and balance <> 0;

-- Recompute a single account's balance from its full ledger.
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
   where a.id = p_account_id;
end $$;

-- Keep balances in sync whenever a transaction changes.
create or replace function public.balance_after_transactions()
returns trigger language plpgsql security invoker as $$
declare
  v_old uuid;
  v_new uuid;
begin
  if tg_op <> 'INSERT' then
    v_old := old.account_id;
    perform public.recompute_account_balance(v_old);
  end if;
  if tg_op <> 'DELETE' then
    v_new := new.account_id;
    if v_new is distinct from v_old then
      perform public.recompute_account_balance(v_new);
    end if;
  end if;
  return coalesce(new, old);
end $$;

drop trigger if exists balance_after_transactions on public.transactions;
create trigger balance_after_transactions
  after insert or update or delete on public.transactions
  for each row execute function public.balance_after_transactions();

-- Keep balances in sync whenever a transfer leg changes.
create or replace function public.balance_after_transfers()
returns trigger language plpgsql security invoker as $$
declare
  v_ids uuid[];
  v_id  uuid;
begin
  v_ids := array[]::uuid[];
  if tg_op in ('UPDATE', 'DELETE') then
    v_ids := v_ids || old.from_account_id || old.to_account_id;
  end if;
  if tg_op in ('INSERT', 'UPDATE') then
    v_ids := v_ids || new.from_account_id || new.to_account_id;
  end if;
  foreach v_id in array v_ids loop
    perform public.recompute_account_balance(v_id);
  end loop;
  return coalesce(new, old);
end $$;

drop trigger if exists balance_after_transfers on public.transaction_transfers;
create trigger balance_after_transfers
  after insert or update or delete on public.transaction_transfers
  for each row execute function public.balance_after_transfers();

-- ------------------------------------------------------------
-- 2. ATOMIC INTERNAL TRANSFER
-- ------------------------------------------------------------

-- Single, atomic operation: one transfer transaction row plus its
-- transaction_transfers link. Both insert or neither. The caller must own
-- both accounts. Returns the created transaction id.
create or replace function public.create_internal_transfer(
  from_account_id uuid,
  to_account_id uuid,
  amount numeric,
  note text default null
)
returns uuid language plpgsql security invoker as $$
declare
  v_txn uuid;
begin
  if amount is null or amount <= 0 then
    raise exception 'Amount must be positive' using errcode = 'NUSA01';
  end if;
  if from_account_id is null or to_account_id is null then
    raise exception 'Both accounts are required' using errcode = 'NUSA02';
  end if;
  if from_account_id = to_account_id then
    raise exception 'Accounts must differ' using errcode = 'NUSA03';
  end if;

  perform 1 from public.accounts a
    where a.id = from_account_id and a.user_id = auth.uid();
  if not found then
    raise exception 'Sender account not found' using errcode = 'NUSA04';
  end if;
  perform 1 from public.accounts a
    where a.id = to_account_id and a.user_id = auth.uid();
  if not found then
    raise exception 'Receiver account not found' using errcode = 'NUSA05';
  end if;

  insert into public.transactions
    (user_id, account_id, kind, source, amount, note)
  values (auth.uid(), from_account_id, 'transfer', 'manual', amount, note)
  returning id into v_txn;

  insert into public.transaction_transfers
    (transaction_id, from_account_id, to_account_id, amount)
  values (v_txn, from_account_id, to_account_id, amount);

  return v_txn;
end $$;

grant execute on function public.create_internal_transfer(uuid, uuid, numeric, text)
  to authenticated;

-- ------------------------------------------------------------
-- 3. RLS: verify ownership of every referenced row
-- ------------------------------------------------------------

drop policy if exists "transactions_all_own" on public.transactions;
create policy "transactions_all_own" on public.transactions
  for all
  using (
    auth.uid() = user_id
    and exists (select 1 from public.accounts a
                 where a.id = account_id and a.user_id = auth.uid())
    and (category_id is null or exists (select 1 from public.categories c
         where c.id = category_id and c.user_id = auth.uid()))
  )
  with check (
    auth.uid() = user_id
    and exists (select 1 from public.accounts a
                 where a.id = account_id and a.user_id = auth.uid())
    and (category_id is null or exists (select 1 from public.categories c
         where c.id = category_id and c.user_id = auth.uid()))
  );

drop policy if exists "transaction_transfers_all_own" on public.transaction_transfers;
create policy "transaction_transfers_all_own" on public.transaction_transfers
  for all
  using (
       exists (select 1 from public.transactions t
                where t.id = transaction_id and t.user_id = auth.uid())
   and exists (select 1 from public.accounts a
                where a.id = from_account_id and a.user_id = auth.uid())
   and exists (select 1 from public.accounts a
                where a.id = to_account_id and a.user_id = auth.uid())
  )
  with check (
       exists (select 1 from public.transactions t
                where t.id = transaction_id and t.user_id = auth.uid())
   and exists (select 1 from public.accounts a
                where a.id = from_account_id and a.user_id = auth.uid())
   and exists (select 1 from public.accounts a
                where a.id = to_account_id and a.user_id = auth.uid())
  );

-- ------------------------------------------------------------
-- 4. CATEGORY UNIQUENESS (seed idempotency)
-- ------------------------------------------------------------

create unique index if not exists categories_user_name_idx
  on public.categories (user_id, name);