-- Explicit opt-in for an isolated LOCAL / SANDBOX database only.
-- Does not enable any bank or e-wallet live integration.
begin;
update public.feature_flags set enabled=true where id='financial_hub_sandbox';
update public.institutions set provider_support=provider_support || '{"simulation_supported":true}'::jsonb
where lower(code) in ('bca','bri','bni','mandiri','seabank','gopay','dana','ovo','shopeepay');
commit;
