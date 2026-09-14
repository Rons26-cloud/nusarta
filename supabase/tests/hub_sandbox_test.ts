import {
  EXECUTION_MODE,
  safeError,
  sandboxEnabled,
  validAmount,
  validIdentifier,
  verifySimulationEvent,
} from "../functions/_shared/hub_sandbox.ts";
import { disburse } from "../functions/brankas-disburse/index.ts";
import { callback } from "../functions/brankas-callback/index.ts";
const assert = (value: unknown) => {
  if (!value) throw new Error("assertion failed");
};
Deno.test("production payout is disabled", async () => {
  Deno.env.delete("NUSARTA_EXECUTION_MODE");
  assert(
    (await disburse(new Request("https://local.test", { method: "POST" })))
      .status === 503,
  );
});
Deno.test("sandbox requires both explicit gates", () => {
  assert(!sandboxEnabled(() => EXECUTION_MODE));
  assert(
    sandboxEnabled((k) => k === "BRANKAS_ENV" ? "sandbox" : EXECUTION_MODE),
  );
});
for (const amount of [0, -1, NaN, Infinity, 1.5, 100000001, "100"]) {
  Deno.test(
    "reject amount " + String(amount),
    () => assert(!validAmount(amount)),
  );
}
Deno.test("valid whole IDR amount", () => assert(validAmount(100000)));
Deno.test("provider type identifier validation", () => {
  assert(validIdentifier("1234567890"));
  assert(!validIdentifier("1234567890", true));
  assert(validIdentifier("081234567890", true));
  assert(!validIdentifier("123"));
});
Deno.test("error output excludes provider raw data", () =>
  assert(safeError("unexpected detail") === "operation_unavailable"));
const secret = "test-only-simulator-key-not-a-real-secret";
const now = 1700000000000;
const raw = JSON.stringify({
  transfer_id: "00000000-0000-0000-0000-000000000001",
  status: "success",
  timestamp: now,
});
async function sign(body: string) {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  return [
    ...new Uint8Array(
      await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(body)),
    ),
  ].map((b) => b.toString(16).padStart(2, "0")).join("");
}
Deno.test("authentic simulator event", async () =>
  assert(
    (await verifySimulationEvent(raw, await sign(raw), secret, now))?.status ===
      "success",
  ));
Deno.test("forged callback", async () =>
  assert(
    await verifySimulationEvent(raw, "0".repeat(64), secret, now) === null,
  ));
Deno.test("tampered status", async () =>
  assert(
    await verifySimulationEvent(
      raw.replace("success", "failed"),
      await sign(raw),
      secret,
      now,
    ) === null,
  ));
Deno.test("stale event replay rejected", async () =>
  assert(
    await verifySimulationEvent(raw, await sign(raw), secret, now + 300001) ===
      null,
  ));
Deno.test("missing callback key rejected", async () =>
  assert(
    await verifySimulationEvent(raw, await sign(raw), undefined, now) === null,
  ));
Deno.test("Brankas callback without verified contract remains disabled", async () => {
  Deno.env.delete("NUSARTA_EXECUTION_MODE");
  assert(
    (await callback(new Request("https://local.test", { method: "POST" })))
      .status === 503,
  );
});
Deno.test("simulator endpoint requires authenticated user", async () => {
  Deno.env.set("NUSARTA_EXECUTION_MODE", EXECUTION_MODE);
  Deno.env.set("BRANKAS_ENV", "sandbox");
  try {
    assert(
      (await disburse(
        new Request("https://local.test", {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: "{}",
        }),
      )).status === 401,
    );
  } finally {
    Deno.env.delete("NUSARTA_EXECUTION_MODE");
    Deno.env.delete("BRANKAS_ENV");
  }
});
