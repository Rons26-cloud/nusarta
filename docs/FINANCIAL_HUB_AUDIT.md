# Financial hub implementation and capability audit

Baseline: main at 9a2df87, clean working tree. No commit, push, deployment, provider POST, or hosted migration is authorized by this task.

## Existing implementation

- A full-history audit (git log --all -S/-G/--grep, branches, tags, deleted files, migrations, docs) found no payment-rail code other than the existing Brankas Disburse sandbox. Existing code is Brankas Disburse sandbox, including disburse, preflight, callback and reconcile Edge Functions. Brankas Sandbox is the sole payment rail.
- Existing accounts, account_connections, institutions, future_transfers and transfer_recipients are reused. Manual transactions remain a separate ledger.
- Existing dashboard added every active manual balance while describing some results as connected. Linked status alone and a timestamp did not establish provider provenance.
- Existing transfer UI used a new idempotency key on each request and had no NUSARTA authorization step. Existing provider registry was empty, feature disabled.
- Existing callback acknowledged arbitrary JSON without authenticating or updating transactions. Existing RLS allowed users to write their own transfer statuses and connections. Brankas source ownership validation did not establish connected-account debit capability.
- PIN hashing, Secure Storage, five-attempt lockout and local_auth remain intact. Provider branding reuses InstitutionLogoRegistry and InstitutionLogo with BoxFit.contain and fallback monograms.

## Implemented boundary

NUSARTA is a financial hub, never a deposit-taking wallet. Account balance provenance is live, sandbox, simulated or unavailable. Manual ledger values and unknown provenance do not enter the connected-account total. Only connected, active IDR balances are aggregated; missing balances are disclosed.

The existing registry has an opt-in debug simulator adapter (NUSARTA_SANDBOX=true). The existing brankas-disburse endpoint now fails closed for real payout and supports explicitly configured NUSARTA simulation only. It does not call the Brankas API (or any provider). Existing low-level Brankas adapter remains available for future verified integration work, not enabled here.

A server-side payment-rail contract now exists in supabase/functions/_shared/payment_rails.ts. The registered rail is brankas_sandbox with explicit, sandbox-scoped capability metadata: supportsBankTransfer=true, supportsEwalletTransfer=false, supportsBalanceRead=false, supportsAccountDebit=false. Adapter selection is a server-side concern only; no rail reports live balances or external-account debit, and no provider secret is stored anywhere in source control.

Simulation requires all of: debug app flag, server NUSARTA_EXECUTION_MODE=SANDBOX_SIMULATED_SOURCE, BRANKAS_ENV=sandbox, database financial_hub_sandbox flag, and per-institution simulation_supported metadata. These flags are not live integration support. No production flags are enabled by the migration.

Simulation accounts receive synthetic identifiers and an explicit test balance of IDR 1,000,000 from the server. They are not OAuth connections. Users may create multiple accounts at one institution. The application never asks for external PIN, password, OTP or CVV.

Transfers validate JWT, ownership, connection, institution capabilities, amount, destination, available balance including pending reservations, rate limit and idempotency in the backend. SQL locks serialize spending. Keys are retained on ambiguous client failures; no failure/success receipt is fabricated from a network exception. Fees in this simulator are explicitly zero, verified again in the persisted record. No shared NUSARTA wallet is created.

The source selector supports account-specific balances, a grouped modal and the existing primary-account setting. Own-account destinations exclude the source. Bank/wallet choices come from configured capabilities. Saved recipient masks are read from the existing table; the user must re-enter the full identifier because no existing secure resolver/decryptor was found. A mask is never submitted as a destination identifier.

PIN/biometric authorization is an application/device control. The backend independently verifies JWT and ownership. It does NOT claim cryptographic proof that a local PIN was entered. Live execution must remain disabled until transaction-bound server-verifiable authorization is implemented and reviewed.

## Callback and records

The existing callback route now accepts ONLY the documented NUSARTA simulator protocol: raw JSON containing transfer_id, status and timestamp (milliseconds), signed using HMAC-SHA256 in x-nusarta-simulator-signature. Timestamp tolerance is five minutes. The secret is server/operator-only, at least 32 characters. This is NOT a Brankas signature specification.

Only simulator records may consume these events. SQL applies success, failure, processing and reversal transitions atomically, handles duplicate/out-of-order events, records audit events/timestamps and adjusts only simulated account balances. Unknown Brankas reconciliation statuses preserve persisted state instead of attempting an invalid enum write. Existing historical Brankas records are not rewritten into simulation records.

Use scripts/simulate-hub-event.mjs only against localhost to deliver an operator-controlled simulation event. It never prints the signing secret/signature and never calls a payment rail. This task did not send any remote event.

## Database and verification

Migration: supabase/migrations/20260914014809_financial_hub_boundaries.sql. New migration only; old migration files are unchanged. Server-only connection/provenance fields and provider outcomes, account ownership, manual-ledger separation, atomic default-source selection, source balance reservation, rate limit, callback transitions and audit records are enforced.

Docker was unavailable. scripts/test-financial-hub-db.mjs applies the relevant original finance migrations plus the new migration to an isolated in-memory PostgreSQL WASM instance. It exercises actual SQL policies under authenticated/service roles, not a text-pattern mock. It stubs Supabase auth.users/auth.uid and omits unused pgcrypto/citext extensions; it does not validate hosted PostgREST, GoTrue, Storage, Edge gateway JWT settings or multi-connection contention. Full local Supabase integration remains a deployment prerequisite.

To reproduce SQL tests without changing app dependencies: npm install --prefix .local-backups/hub-tools --no-package-lock --no-save @electric-sql/pglite@0.5.8 then node scripts/test-financial-hub-db.mjs. Tooling is ignored. Application lockfiles are preserved.

Backend tasks: npx deno task --config supabase/deno.json lint, check, test. Import map retains the existing Supabase JS 2.45.4 pin; supabase/deno.lock records resolved remote dependencies. Deno check is the Edge type/build validation; there is no separate existing Edge build script.

## Local setup and remaining gates

Apply the migration only to a verified local/sandbox database, then opt in using supabase/seed/financial_hub_sandbox.sql. Keep the seed out of production. Populate the existing institution catalog first. Configure the local Edge environment using supabase/functions/.env.example; configure the callback gateway to allow this route to perform its own HMAC verification, and require JWT for disburse. Start mobile in debug with --dart-define=NUSARTA_SANDBOX=true and its configured local backend. Set PIN NUSARTA using the existing security settings before transfers.

No hosted schema, secrets, flags, Edge Functions or live provider configuration were changed. The deployed application's behavior is therefore not claimed to match this working tree until a separate reviewed deployment.

## Production blockers / gaps

- No real personal bank/e-wallet balance reader, external-account debit capability, live consent/OAuth, recipient inquiry or verified fee quote. Live adapters stay absent.
- Brankas destination contract, monetary units, approved fixtures and provider callback authentication remain unverified; the previous stabilization notes already identified these gaps.
- Device PIN is not a backend transaction signature; server-verifiable step-up authorization is required before real money movement.
- Saved recipients have no verified secure full-identifier resolver; full number re-entry is required.
- Official local assets exist for BCA, Mandiri, SeaBank, GoPay, OVO and several others; BRI, BNI, DANA and ShopeePay currently use safe provider-specific monograms. No invented logos were added.
- End-to-end hosted deployment, physical biometric hardware, and concurrent database sessions were not exercised. Emulator/widget tests are not a claim of production readiness.
