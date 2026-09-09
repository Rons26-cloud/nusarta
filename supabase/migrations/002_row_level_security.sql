-- ============================================================
-- NUSARTA — Row Level Security
-- Every table is user-scoped. A user only ever reads/writes their
-- own rows. Must verify with two accounts (see docs/RLS_TESTING.md).
-- ============================================================

alter table public.profiles enable row level security;
alter table public.accounts enable row level security;
alter table public.categories enable row level security;
alter table public.transactions enable row level security;
alter table public.transaction_transfers enable row level security;
alter table public.budgets enable row level security;
alter table public.financial_goals enable row level security;
alter table public.app_settings enable row level security;
alter table public.audit_events enable row level security;

-- ============================================================
-- HANDLER: profile auto-creation
-- ============================================================
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  insert into public.app_settings (user_id)
  values (new.id)
  on conflict (user_id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
-- PROFILES — each user manages their own row only
-- ============================================================
create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);
create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- ============================================================
-- ACCOUNTS
-- ============================================================
create policy "accounts_all_own" on public.accounts
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- CATEGORIES
-- ============================================================
create policy "categories_all_own" on public.categories
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- TRANSACTIONS
-- ============================================================
create policy "transactions_all_own" on public.transactions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- TRANSACTION TRANSFERS — via the owner's transactions
-- ============================================================
create policy "transaction_transfers_all_own" on public.transaction_transfers
  for all using (
    exists (
      select 1 from public.transactions t
      where t.id = transaction_id and t.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.transactions t
      where t.id = transaction_id and t.user_id = auth.uid()
    )
  );

-- ============================================================
-- BUDGETS
-- ============================================================
create policy "budgets_all_own" on public.budgets
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- FINANCIAL GOALS
-- ============================================================
create policy "financial_goals_all_own" on public.financial_goals
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- APP SETTINGS
-- ============================================================
create policy "app_settings_all_own" on public.app_settings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- AUDIT EVENTS — user can read own only
-- ============================================================
create policy "audit_events_select_own" on public.audit_events
  for select using (auth.uid() = user_id);

-- ============================================================
-- GRANTS (defaults via Supabase roles)
-- ============================================================
grant all on public.profiles to authenticated;
grant all on public.accounts to authenticated;
grant all on public.categories to authenticated;
grant all on public.transactions to authenticated;
grant all on public.transaction_transfers to authenticated;
grant all on public.budgets to authenticated;
grant all on public.financial_goals to authenticated;
grant all on public.app_settings to authenticated;
grant select on public.audit_events to authenticated;