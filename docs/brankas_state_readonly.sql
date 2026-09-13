select id, user_id, amount, currency, provider, provider_reference, status,
       idempotency_key, failure_code, failure_message, created_at, updated_at,
       authorized_at, processed_at, completed_at
from public.future_transfers
where id in (
  'a81200b7-f9c4-4964-9b2a-ec5cc0a09a53'::uuid,
  'fd6ab443-5d7d-4bf9-9883-5f8f804ce233'::uuid
)
order by id;
