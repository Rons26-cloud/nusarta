-- ============================================================
-- NUSARTA — RLS for Future Foundation tables
--
-- Enables Row Level Security on all new tables from migration 005.
-- All user-owned tables have user-scoped policies via auth.uid().
-- The `institutions` catalog is read-only for authenticated users.
-- The `feature_flags` table is read-only (server/service-role manages it).
-- ============================================================

-- ------------------------------------------------------------
-- ENABLE RLS
-- ------------------------------------------------------------

alter table public.institutions enable row level security;
alter table public.devices enable row level security;
alter table public.account_connections enable row level security;
alter table public.future_transfers enable row level security;
alter table public.transfer_recipients enable row level security;
alter table public.notifications enable row level security;
alter table public.feature_flags enable row level security;
alter table public.security_events enable row level security;

-- ------------------------------------------------------------
-- INSTITUTIONS — read-only catalog for authenticated users
-- ------------------------------------------------------------

create policy "institutions_select_active" on public.institutions
  for select using (is_active = true);

-- Institutions are managed server-side / by admin. No client writes.

-- ------------------------------------------------------------
-- DEVICES — each user manages their own devices
-- ------------------------------------------------------------

create policy "devices_all_own" on public.devices
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ------------------------------------------------------------
-- ACCOUNT CONNECTIONS — user-owned
-- ------------------------------------------------------------

create policy "account_connections_all_own" on public.account_connections
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ------------------------------------------------------------
-- FUTURE TRANSFERS — user-owned
-- ------------------------------------------------------------

create policy "future_transfers_all_own" on public.future_transfers
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ------------------------------------------------------------
-- TRANSFER RECIPIENTS — user-owned
-- ------------------------------------------------------------

create policy "transfer_recipients_all_own" on public.transfer_recipients
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ------------------------------------------------------------
-- NOTIFICATIONS — user owns, can read/update own
-- ------------------------------------------------------------

create policy "notifications_select_own" on public.notifications
  for select using (auth.uid() = user_id);
create policy "notifications_update_own" on public.notifications
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Notifications are created server-side (function/service-role).

-- ------------------------------------------------------------
-- FEATURE FLAGS — read-only for authenticated users
-- ------------------------------------------------------------

create policy "feature_flags_select" on public.feature_flags
  for select using (true);

-- Feature flags are managed server-side only.

-- ------------------------------------------------------------
-- SECURITY EVENTS — user can read own
-- ------------------------------------------------------------

create policy "security_events_select_own" on public.security_events
  for select using (auth.uid() = user_id);

-- Security events are written server-side only.

-- ------------------------------------------------------------
-- GRANTS — client (authenticated) permissions
-- ------------------------------------------------------------

grant select on public.institutions to authenticated;
grant all on public.devices to authenticated;
grant all on public.account_connections to authenticated;
grant select, insert, update on public.future_transfers to authenticated;
grant all on public.transfer_recipients to authenticated;
grant select, update on public.notifications to authenticated;
grant select on public.feature_flags to authenticated;
grant select on public.security_events to authenticated;
