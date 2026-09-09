-- ============================================================
-- NUSARTA — Initial schema
-- Future-ready: accounts, categories, transactions (multi-source),
-- transfers, budgets, goals, app settings, audit events.
-- ============================================================

-- Extensions (idempotent)
create extension if not exists "pgcrypto";
create extension if not exists "citext";

-- ============================================================
-- ENUMS
-- ============================================================

-- Transaction source models the future integration pipeline.
-- V1 only uses 'manual'; future values are reserved.
do $$ begin
  create type transaction_source as enum ('manual', 'imported', 'bank_api', 'wallet_api');
exception
  when duplicate_object then null;
end $$;

-- Manual account types.
do $$ begin
  create type account_type as enum ('cash', 'bank', 'ewallet', 'custom');
exception
  when duplicate_object then null;
end $$;

-- Transaction direction.
do $$ begin
  create type transaction_kind as enum ('income', 'expense', 'transfer');
exception
  when duplicate_object then null;
end $$;

-- Budget period.
do $$ begin
  create type budget_period as enum ('weekly', 'monthly', 'yearly');
exception
  when duplicate_object then null;
end $$;

-- Goal period.
do $$ begin
  create type goal_period as enum ('weekly', 'monthly', 'yearly');
exception
  when duplicate_object then null;
end $$;

-- ============================================================
-- TABLES
-- ============================================================

-- Profiles (mirrors auth.users)
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  email         text,
  display_name  text,
  currency_code text not null default 'IDR',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- Accounts (manual). Bank provider/identifier reserved for the future
-- integration layer — deliberately nullable so existing/local rows stay valid.
create table if not exists public.accounts (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles(id) on delete cascade,
  name          text not null,
  type          account_type not null default 'cash',
  balance       numeric(14,2) not null default 0,
  currency_code text not null default 'IDR',
  is_archived   boolean not null default false,
  -- future connected-finance fields
  provider      text,
  external_id   text,
  is_linked     boolean not null default false,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- Categories
create table if not exists public.categories (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  name       text not null,
  kind       transaction_kind not null default 'expense',
  icon       text,
  color      text,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

-- Transactions. `source` enables the multi-source future.
create table if not exists public.transactions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  account_id  uuid not null references public.accounts(id) on delete cascade,
  category_id uuid references public.categories(id) on delete set null,
  kind        transaction_kind not null default 'expense',
  source      transaction_source not null default 'manual',
  amount      numeric(14,2) not null check (amount > 0),
  note        text,
  occurred_at timestamptz not null default now(),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists transactions_user_occurred_idx
  on public.transactions (user_id, occurred_at desc);

-- Internal transfers link a sender and receiver account.
create table if not exists public.transaction_transfers (
  id              uuid primary key default gen_random_uuid(),
  transaction_id  uuid not null unique references public.transactions(id) on delete cascade,
  from_account_id uuid not null references public.accounts(id) on delete restrict,
  to_account_id   uuid not null references public.accounts(id) on delete restrict,
  amount          numeric(14,2) not null check (amount > 0),
  created_at      timestamptz not null default now(),
  check (from_account_id <> to_account_id)
);

-- Budgets
create table if not exists public.budgets (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  category_id uuid not null references public.categories(id) on delete cascade,
  amount      numeric(14,2) not null check (amount >= 0),
  period      budget_period not null default 'monthly',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Financial goals
create table if not exists public.financial_goals (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  name       text not null,
  target     numeric(14,2) not null check (target > 0),
  current    numeric(14,2) not null default 0,
  deadline   date,
  period     goal_period,
  is_archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- App settings
create table if not exists public.app_settings (
  user_id         uuid primary key references public.profiles(id) on delete cascade,
  theme           text not null default 'system',
  currency_code   text not null default 'IDR',
  auto_lock_minutes integer not null default 5,
  show_onboarding boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- Audit events (least privilege: as-needed usage in the future)
create table if not exists public.audit_events (
  id           bigint generated always as identity primary key,
  user_id      uuid references public.profiles(id) on delete cascade,
  event_type   text not null,
  metadata     jsonb not null default '{}'::jsonb,
  created_at   timestamptz not null default now()
);

-- ============================================================
-- UPDATED_AT TRIGGERS
-- ============================================================
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists set_updated_at_profiles on public.profiles;
create trigger set_updated_at_profiles before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_accounts on public.accounts;
create trigger set_updated_at_accounts before update on public.accounts
  for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_transactions on public.transactions;
create trigger set_updated_at_transactions before update on public.transactions
  for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_budgets on public.budgets;
create trigger set_updated_at_budgets before update on public.budgets
  for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_goals on public.financial_goals;
create trigger set_updated_at_goals before update on public.financial_goals
  for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_settings on public.app_settings;
create trigger set_updated_at_settings before update on public.app_settings
  for each row execute function public.set_updated_at();