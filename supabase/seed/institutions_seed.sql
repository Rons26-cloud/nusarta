-- ============================================================
-- NUSARTA — Institution catalog seed (informational only)
--
-- This catalog lists institutions that a user *may* create as a manual
-- account. It NEVER claims a live data integration is available:
--   * provider_support defaults to {} for all rows.
--   * integration_available stays false/absent (see apps/mobile model:
--     Institution.hasProviderIntegration reads this key).
--
-- Integration availability is a separate concern that will only be set
-- when an official provider is onboarded (V2+), never before.
-- Idempotent: safe to run more than once.
-- ============================================================

insert into public.institutions (code, name, institution_type, country, is_active, provider_support) values
  ('cash',       'Cash',              'cash',    'ID', true, '{}'),
  ('bca',        'BCA',               'bank',    'ID', true, '{}'),
  ('bri',        'BRI',               'bank',    'ID', true, '{}'),
  ('bni',        'BNI',               'bank',    'ID', true, '{}'),
  ('mandiri',    'Bank Mandiri',      'bank',    'ID', true, '{}'),
  ('seabank',    'SeaBank',           'bank',    'ID', true, '{}'),
  ('jago',       'Bank Jago',         'bank',    'ID', true, '{}'),
  ('gopay',      'GoPay',             'ewallet', 'ID', true, '{}'),
  ('dana',       'DANA',              'ewallet', 'ID', true, '{}'),
  ('ovo',        'OVO',               'ewallet', 'ID', true, '{}'),
  ('shopeepay',  'ShopeePay',         'ewallet', 'ID', true, '{}')
on conflict (code) do nothing;