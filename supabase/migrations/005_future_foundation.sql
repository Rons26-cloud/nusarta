-- ============================================================
-- NUSARTA — Future Foundation (V1.5 ready)
--
-- Adds the database foundation for:
--   - Institution catalog (banks, e-wallets, cash)
--   - Device management
--   - Account connection model (future linked bank/e-wallet)
--   - External transfer domain (not internal transfers)
--   - Transfer recipients
--   - In-app notifications
--   - Feature flags
--   - Security events (separate from audit_events)
--
-- All new tables are backward-compatible. Existing V1 data is untouched.
-- New columns on existing tables are nullable or have safe defaults.
-- ============================================================

-- ------------------------------------------------------------
-- 1. NEW ENUMS
-- ------------------------------------------------------------

do $$ begin
  create type institution_type as enum ('bank', 'ewallet', 'cash', 'other');
exception when duplicate_object then null; end $$;

do $$ begin
  create type connection_type as enum ('manual', 'bank_api', 'ewallet_api', 'open_banking', 'payment_provider');
exception when duplicate_object then null; end $$;

do $$ begin
  create type connection_status as enum ('manual', 'disconnected', 'pending', 'active', 'expired', 'error', 'revoked');
exception when duplicate_object then null; end $$;

do $$ begin
  create type balance_source as enum ('calculated', 'manual', 'provider');
exception when duplicate_object then null; end $$;

do $$ begin
  create type transaction_status as enum ('pending', 'completed', 'failed', 'reversed', 'cancelled');
exception when duplicate_object then null; end $$;

do $$ begin
  create type transfer_status as enum ('draft', 'awaiting_authorization', 'pending', 'processing', 'success', 'failed', 'reversed', 'cancelled');
exception when duplicate_object then null; end $$;

do $$ begin
  create type destination_type as enum ('bank', 'ewallet', 'internal_future');
exception when duplicate_object then null; end $$;

do $$ begin
  create type device_platform as enum ('android', 'ios', 'web', 'other');
exception when duplicate_object then null; end $$;

do $$ begin
  create type notification_type as enum ('transaction', 'budget', 'security', 'account_connection', 'transfer', 'system');
exception when duplicate_object then null; end $$;

do $$ begin
  create type event_category as enum ('auth', 'security', 'connection', 'transfer', 'account', 'system');
exception when duplicate_object then null; end $$;

-- ------------------------------------------------------------
-- 2. INSTITUTIONS (catalog of banks, e-wallets, etc.)
-- ------------------------------------------------------------

create table if not exists public.institutions (
  id              uuid primary key default gen_random_uuid(),
  code            text not null unique,
  name            text not null,
  institution_type institution_type not null,
  logo_url        text,
  country         text not null default 'ID',
  is_active       boolean not null default true,
  provider_support jsonb not null default '{}'::jsonb,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists institutions_type_idx on public.institutions (institution_type);
create index if not exists institutions_active_idx on public.institutions (is_active) where is_active = true;

-- ------------------------------------------------------------
-- 3. DEVICES (device management)
-- ------------------------------------------------------------

create table if not exists public.devices (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references public.profiles(id) on delete cascade,
  device_identifier text not null,
  platform          device_platform not null default 'android',
  app_version       text,
  device_name       text,
  trusted           boolean not null default false,
  biometric_enabled boolean not null default false,
  last_seen_at      timestamptz not null default now(),
  revoked_at        timestamptz,
  created_at        timestamptz not null default now()
);

create index if not exists devices_user_idx on public.devices (user_id);
create unique index if not exists devices_user_identifier_idx
  on public.devices (user_id, device_identifier);

-- ------------------------------------------------------------
-- 4. ACCOUNT CONNECTIONS (future linked bank/e-wallet)
-- ------------------------------------------------------------

create table if not exists public.account_connections (
  id                       uuid primary key default gen_random_uuid(),
  user_id                  uuid not null references public.profiles(id) on delete cascade,
  institution_id           uuid not null references public.institutions(id),
  financial_account_id     uuid references public.accounts(id) on delete set null,
  provider                 text,
  provider_connection_id   text,
  status                   connection_status not null default 'manual',
  scopes                   text[] not null default '{}',
  consent_expires_at       timestamptz,
  last_synced_at           timestamptz,
  last_error_code          text,
  last_error_at            timestamptz,
  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now()
);

create index if not exists account_connections_user_idx
  on public.account_connections (user_id);
create index if not exists account_connections_status_idx
  on public.account_connections (status);

-- ------------------------------------------------------------
-- 5. EXTERNAL TRANSFERS (not internal — for bank/e-wallet transfers)
-- ------------------------------------------------------------

create table if not exists public.future_transfers (
  id                             uuid primary key default gen_random_uuid(),
  user_id                        uuid not null references public.profiles(id) on delete cascade,
  source_financial_account_id    uuid not null references public.accounts(id),
  destination_type               destination_type not null,
  destination_institution_id     uuid references public.institutions(id),
  destination_account_reference  text,
  recipient_name                 text,
  amount                         numeric(14,2) not null check (amount > 0),
  fee_amount                     numeric(14,2) not null default 0 check (fee_amount >= 0),
  total_amount                   numeric(14,2) not null check (total_amount > 0),
  currency                       text not null default 'IDR',
  provider                       text,
  provider_reference             text,
  status                         transfer_status not null default 'draft',
  idempotency_key                text,
  failure_code                   text,
  failure_message                text,
  created_at                     timestamptz not null default now(),
  authorized_at                  timestamptz,
  processed_at                   timestamptz,
  completed_at                   timestamptz,
  updated_at                     timestamptz not null default now()
);

create index if not exists future_transfers_user_idx
  on public.future_transfers (user_id);
create index if not exists future_transfers_status_idx
  on public.future_transfers (status);
create index if not exists future_transfers_provider_ref_idx
  on public.future_transfers (provider_reference) where provider_reference is not null;
create unique index if not exists future_transfers_idempotency_idx
  on public.future_transfers (idempotency_key) where idempotency_key is not null;

-- ------------------------------------------------------------
-- 6. TRANSFER RECIPIENTS
-- ------------------------------------------------------------

create table if not exists public.transfer_recipients (
  id                        uuid primary key default gen_random_uuid(),
  user_id                   uuid not null references public.profiles(id) on delete cascade,
  institution_id            uuid not null references public.institutions(id),
  recipient_type            destination_type not null,
  display_name              text not null,
  account_reference_masked  text,
  encrypted_reference       text,
  is_favorite               boolean not null default false,
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now()
);

create index if not exists transfer_recipients_user_idx
  on public.transfer_recipients (user_id);

-- ------------------------------------------------------------
-- 7. NOTIFICATIONS
-- ------------------------------------------------------------

create table if not exists public.notifications (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles(id) on delete cascade,
  type         notification_type not null,
  title        text not null,
  body         text,
  data         jsonb not null default '{}'::jsonb,
  is_read      boolean not null default false,
  created_at   timestamptz not null default now()
);

create index if not exists notifications_user_idx
  on public.notifications (user_id, is_read, created_at desc);

-- ------------------------------------------------------------
-- 8. FEATURE FLAGS
-- ------------------------------------------------------------

create table if not exists public.feature_flags (
  id          text primary key,
  enabled     boolean not null default false,
  description text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Seed default flags (all OFF)
insert into public.feature_flags (id, enabled, description) values
  ('linked_accounts',     false, 'Allow users to connect bank/e-wallet accounts'),
  ('bank_sync',           false, 'Enable bank account synchronization'),
  ('ewallet_sync',        false, 'Enable e-wallet synchronization'),
  ('transfers',           false, 'Enable external transfers'),
  ('transfer_recipient_validation', false, 'Validate transfer recipients via provider'),
  ('push_notifications',  false, 'Enable push notification delivery'),
  ('institution_catalog', true,  'Show institution catalog to users')
on conflict (id) do nothing;

-- ------------------------------------------------------------
-- 9. SECURITY EVENTS
-- ------------------------------------------------------------

create table if not exists public.security_events (
  id           bigint generated always as identity primary key,
  user_id      uuid references public.profiles(id) on delete cascade,
  event_category event_category not null,
  event_type   text not null,
  severity     smallint not null default 0,
  metadata     jsonb not null default '{}'::jsonb,
  ip_address   inet,
  device_id    uuid,
  created_at   timestamptz not null default now()
);

create index if not exists security_events_user_idx
  on public.security_events (user_id, created_at desc);
create index if not exists security_events_category_idx
  on public.security_events (event_category);

-- ------------------------------------------------------------
-- 10. COLUMNS ON EXISTING TABLES (backward-compatible)
-- ------------------------------------------------------------

-- accounts: expand for institution + connection support
alter table public.accounts
  add column if not exists institution_id uuid references public.institutions(id),
  add column if not exists masked_account_number text,
  add column if not exists last_four text,
  add column if not exists display_name text,
  add column if not exists is_primary boolean not null default false,
  add column if not exists connection_type connection_type not null default 'manual',
  add column if not exists connection_status connection_status not null default 'manual',
  add column if not exists last_synced_at timestamptz;

-- transactions: expand for status + metadata
alter table public.transactions
  add column if not exists title text,
  add column if not exists status transaction_status not null default 'completed',
  add column if not exists provider_reference text,
  add column if not exists metadata jsonb;

-- budgets: expand for alert threshold + optional category
alter table public.budgets
  add column if not exists alert_threshold numeric(5,2) not null default 80.00,
  alter column category_id drop not null;

-- categories: add archived state (soft delete; historical transactions keep
-- their category reference intact)
alter table public.categories
  add column if not exists is_archived boolean not null default false;

-- audit_events: expand for richer context
alter table public.audit_events
  add column if not exists event_category event_category,
  add column if not exists ip_address inet,
  add column if not exists device_id uuid;

-- ------------------------------------------------------------
-- 11. UPDATED_AT TRIGGERS for new tables
-- ------------------------------------------------------------

drop trigger if exists set_updated_at_institutions on public.institutions;
create trigger set_updated_at_institutions before update on public.institutions
  for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_account_connections on public.account_connections;
create trigger set_updated_at_account_connections before update on public.account_connections
  for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_future_transfers on public.future_transfers;
create trigger set_updated_at_future_transfers before update on public.future_transfers
  for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_transfer_recipients on public.transfer_recipients;
create trigger set_updated_at_transfer_recipients before update on public.transfer_recipients
  for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_feature_flags on public.feature_flags;
create trigger set_updated_at_feature_flags before update on public.feature_flags
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- 12. EXPAND RLS for transactions (now with status + title)
-- ------------------------------------------------------------

-- Rebuild the transactions policy to accommodate the new title/status columns.
-- The policy logic is the same (user owns the row + owns referenced account/category),
-- but we recreate it for clarity after the ALTER.

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
