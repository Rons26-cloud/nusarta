// Payment-rail tests. NUSARTA's single payment rail is Brankas Disburse
// Sandbox. Orchestration-level guarantees (duplicate-submit protection,
// idempotency, failed/reversed transitions, ownership, replay protection and
// rate limiting) are verified in tests/hub_sandbox_test.ts and the PGlite
// database test; mobile transfer_authorization_test.dart verifies that PIN/
// biometric authorization happens before any submission.
import {
  brankasSandboxRail,
  createRail,
  isRailCode,
  RAIL_BRANKAS_SANDBOX,
  railCapabilities,
  railEnabled,
  type RailCode,
} from "../functions/_shared/payment_rails.ts";
import {
  mapStatus,
} from "../functions/_shared/brankas_disburse.ts";
import { EXECUTION_MODE } from "../functions/_shared/hub_sandbox.ts";

const assert = (value: unknown) => {
  if (!value) throw new Error("assertion failed");
};

async function assertRejects(
  promise: Promise<unknown>,
  errorMessage: string,
): Promise<void> {
  let thrown: unknown;
  try {
    await promise;
  } catch (error) {
    thrown = error;
  }
  if (thrown === undefined || (thrown as Error).message !== errorMessage) {
    throw new Error(`expected rejection "${errorMessage}", got ${thrown}`);
  }
}

function env(overrides: Record<string, string | undefined>) {
  return (key: string): string | undefined => overrides[key];
}

const input = () => ({
  externalId: "9fb8c0a2-3e65-4c1a-9e0b-2ad7d9a0c123",
  bankCode: "BCA",
  accountNumber: "1234567890",
  accountHolderName: "Dummy Recipient Name",
  amountMinor: "250000",
  currency: "IDR",
  destinationAddress: {
    line1: "Jl. Sudirman 1",
    line2: "Lantai 2",
    city: "Jakarta",
    province: "DKI Jakarta",
    zip_code: "10220",
    country: "ID",
  },
});

Deno.test("brankas_sandbox is the registered rail", () => {
  const code: RailCode = RAIL_BRANKAS_SANDBOX;
  assert(isRailCode("brankas_sandbox"));
  assert(railCapabilities(code).environment === "sandbox");
  assert(createRail(code).code === RAIL_BRANKAS_SANDBOX);
});

Deno.test("unsupported rail codes are rejected", () => {
  assert(!isRailCode("xendit_sandbox"));
  assert(!isRailCode("gopay"));
  assert(!isRailCode("dana"));
  assert(!isRailCode(undefined));
  assert(!isRailCode(""));
});

Deno.test("brankas capability flags match the implementation", () => {
  const caps = railCapabilities(RAIL_BRANKAS_SANDBOX);
  assert(caps.environment === "sandbox");
  assert(caps.supportsBankTransfer);
  assert(!caps.supportsEwalletTransfer);
  assert(!caps.supportsBalanceRead);
  assert(!caps.supportsAccountDebit);
  assert(createRail(RAIL_BRANKAS_SANDBOX).capabilities === caps);
});

Deno.test("rail is gated off by default and requires explicit sandbox opt-in", () => {
  const code = RAIL_BRANKAS_SANDBOX;
  assert(!railEnabled(code, env({})));
  assert(!railEnabled(code, env({ "NUSARTA_EXECUTION_MODE": EXECUTION_MODE })));
  assert(!railEnabled(code, env({ "BRANKAS_ENV": "sandbox" })));
  assert(!railEnabled(code, env({ "NUSARTA_EXECUTION_MODE": EXECUTION_MODE, "BRANKAS_ENV": "live" })));
  assert(railEnabled(code, env({ "NUSARTA_EXECUTION_MODE": EXECUTION_MODE, "BRANKAS_ENV": "sandbox" })));
});

Deno.test("transfer request is routed to the Brankas sandbox client", async () => {
  const code = RAIL_BRANKAS_SANDBOX;
  const keys = [
    "BRANKAS_SOURCE_ACCOUNT_ID",
    "BRANKAS_API_KEY",
    "BRANKAS_ENV",
  ];
  const saved: Record<string, string | undefined> = {};
  for (const key of keys) saved[key] = Deno.env.get(key);

  try {
    Deno.env.delete("BRANKAS_SOURCE_ACCOUNT_ID");
    Deno.env.delete("BRANKAS_API_KEY");
    // Missing source account id fails closed before any network call.
    await assertRejects(
      createRail(code).createTransfer(input()),
      "provider_not_configured",
    );

    Deno.env.set("BRANKAS_SOURCE_ACCOUNT_ID", "src-123");
    // Destination address is Brankas-specific requirement for this rail.
    await assertRejects(
      createRail(code).createTransfer({ ...input(), destinationAddress: undefined }),
      "destination_address_invalid",
    );

    // Config present but no secret key: reaches the Brankas client and stops
    // before any network call.
    await assertRejects(
      createRail(code).createTransfer(input()),
      "provider_not_configured",
    );
  } finally {
    for (const key of keys) {
      const value = saved[key];
      if (value === undefined) Deno.env.delete(key);
      else Deno.env.set(key, value);
    }
  }
});

Deno.test("brankas callback/status mapping", async () => {
  assert(mapStatus("CREATED") === "pending");
  assert(mapStatus("PENDING") === "pending");
  assert(mapStatus("NOT_PROCESSED") === "pending");
  assert(mapStatus("FLAGGED") === "processing");
  assert(mapStatus("SUCCESS") === "succeeded");
  assert(mapStatus("FAILED") === "failed");
  assert(mapStatus("ERROR") === "failed");
  assert(mapStatus("SOMETHING_UNKNOWN") === "unknown");

  // Real Brankas webhooks stay closed until their contract is verified; the
  // orchestrator never trusts an unverified callback.
  const result = await brankasSandboxRail.handleWebhook("{}", new Headers());
  assert(result === null);
});