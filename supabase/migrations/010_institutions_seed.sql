-- ============================================================
-- NUSARTA — Institution catalog seed (V1.7)
--
-- Populates the informational catalog of Indonesian banks and
-- e-wallets. NO institution claims a live provider integration.
--
-- `provider_support` truth lives server-side and is the single
-- source of capability status rendered by the mobile app. Every
-- seed row intentionally reports integration_status = coming_soon
-- with all capability flags OFF until an official provider is
-- actually connected (OAuth/open-finance/SDK).
--
-- Idempotent: conflicts update capability metadata only.
-- ============================================================

insert into public.institutions (code, name, institution_type, country, is_active, provider_support)
values
  -- Indonesian banks
  ('bca',   'Bank Central Asia (BCA)',              'bank', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('mandiri','Bank Mandiri',                        'bank', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('bni',    'Bank Negara Indonesia (BNI)',         'bank', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('bri',    'Bank Rakyat Indonesia (BRI)',         'bank', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('cimb',   'CIMB Niaga',                          'bank', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('btpn',   'Bank BTPN (Jenius)',                  'bank', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('bsi',    'Bank Syariah Indonesia (BSI)',        'bank', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('jago',   'Bank Jago',                           'bank', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('seabank','SeaBank Indonesia',                   'bank', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('permata','Bank Permata',                        'bank', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('danamon','Bank Danamon',                        'bank', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('ocbc',   'OCBC NISP',                           'bank', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('dbs',    'DBS Indonesia',                       'bank', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('hsbc',   'HSBC Indonesia',                      'bank', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('btn',    'Bank Tabungan Negara (BTN)',          'bank', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('maybank','Maybank Indonesia',                   'bank', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  -- Indonesian e-wallets
  ('ovo',     'OVO',                                'ewallet', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('gopay',   'GoPay',                              'ewallet', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('dana',    'DANA',                               'ewallet', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('shopeepay','ShopeePay',                         'ewallet', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('linkaja', 'LinkAja',                            'ewallet', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('doku',    'DOKU Wallet',                        'ewallet', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('astrapay','AstraPay',                           'ewallet', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}'),
  ('isaku',   'i.Saku',                             'ewallet', 'ID', true,
   '{"provider": null, "integration_available": false, "integration_status": "coming_soon", "link_supported": false, "sync_supported": false, "transfer_supported": false}')
on conflict (code) do update set
  provider_support = excluded.provider_support,
  updated_at = now();