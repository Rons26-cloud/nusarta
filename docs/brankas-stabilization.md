# Brankas stabilization — prepared, NOT applied

The active files changed during inspection. No active source, database row, deployed Edge Function, logo, account UI, or theme was changed by this task. Applying the patch requires stopping the concurrent writer and reviewing its baseline first. The deployed endpoint is NOT confirmed frozen.

## Evidence

- Supabase project ogdccbbwfktrvhnkorvt rejected the narrowly scoped read query. Run brankas_state_readonly.sql; it selects only the two requested IDs and 15 allowed columns.
- Transfer A (a81200b7-f9c4-4964-9b2a-ec5cc0a09a53): current DB state UNKNOWN. Earlier user context said failed with no provider reference; no fresh verification.
- Transfer B (fd6ab443-5d7d-4bf9-9883-5f8f804ce233): runtime evidence shows provider_http_400; classify PROVIDER_REJECTED on that evidence, not success. Current DB state/reference remain unverified.
- Initial local merchant ID format was nusarta-{uuid} (44 characters). Concurrent changes switched it to ns-{compact uuid} (35), including historical reconciliation. The prepared patch uses nusa-{compact uuid} (37) only for NOT_SUBMITTED and retains the observed historical format for the two existing IDs. No existing row is rewritten.

## Request contract

Official references: https://api-reference.brankas.com/#create-disbursements and https://docs.brankas.com/docs/get-started-with-disburse

DestinationAccount documents bank, number, holder_name, account type, and address. Address keys are line1, line2, city, province, zip_code, country. The reference does not label individual address fields as mandatory/optional for this integration. Runtime specifically rejected the missing address object. The prepared validator conservatively requires all except line2; this is a local gate, not a claim about exact provider requirements. Official destination values and a current sandbox fixture/contract remain required; documentation example placeholders and invented Jakarta addresses are not approved destination data.

## Prepared safeguards

- Hard block in handler before authentication/database access and adapter before config/network access. No environment/client override enables POST.
- Existing debug UI preserved; action becomes a guarded local notice with no network invocation or credentials.
- Safe 4xx classification is retained even for non-JSON bodies. Known rejection responses persist failed plus a fixed safe code/message; ambiguous failures remain pending for investigation, with no automatic retry. Raw provider strings/tokens are not echoed.
- Reconciliation is restricted to the two existing IDs, retains ownership checks and historical merchant IDs, requires a reference, and preserves DB status on unknown/error results. It is not invoked by this task.
- Existing amount conversion was preserved from the concurrent baseline; monetary-unit validation against the current provider contract remains an additional prerequisite before unfreezing.

## Validation

11 offline tests passed with network access and DB clients blocked. Strict TypeScript check: 0 diagnostics using a minimal local Deno/Supabase declaration shim (no remote integration test). Prepared Dart file parses successfully. No emulator action, Edge Function invocation, or provider POST was performed.

SAFE_FOR_ONE_MANUAL_RETRY: NO
