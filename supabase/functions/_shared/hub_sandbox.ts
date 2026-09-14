export const EXECUTION_MODE = "SANDBOX_SIMULATED_SOURCE";
export function sandboxEnabled(
  env: (key: string) => string | undefined,
): boolean {
  return env("NUSARTA_EXECUTION_MODE") === EXECUTION_MODE &&
    env("BRANKAS_ENV") === "sandbox";
}
export function validAmount(value: unknown): value is number {
  return typeof value === "number" && Number.isSafeInteger(value) &&
    value > 0 && value <= 100000000;
}
export function validIdentifier(
  value: unknown,
  wallet = false,
): value is string {
  return typeof value === "string" &&
    (wallet ? /^08[0-9]{8,13}$/ : /^[0-9]{6,20}$/).test(value);
}
export function reply(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json",
      "cache-control": "no-store",
    },
  });
}
export function safeError(message: string): string {
  return [
    "sandbox_disabled",
    "invalid_transfer",
    "idempotency_conflict",
    "rate_limited",
    "source_not_eligible",
    "connection_not_active",
    "destination_not_supported",
    "invalid_wallet_identifier",
    "destination_not_owned",
    "insufficient_balance",
    "account_limit",
    "unsupported_transfer",
    "invalid_status",
  ].find((code) => message.includes(code)) ?? "operation_unavailable";
}
export interface SimulationEvent {
  transfer_id: string;
  status: string;
  timestamp: number;
}
export async function verifySimulationEvent(
  raw: string,
  signature: string | null,
  secret: string | undefined,
  now = Date.now(),
): Promise<SimulationEvent | null> {
  if (
    !secret || secret.length < 32 || !signature ||
    !/^[0-9a-f]{64}$/.test(signature) || raw.length > 4096
  ) return null;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["verify"],
  );
  const bytes = Uint8Array.from(
    signature.match(/../g)!,
    (h) => parseInt(h, 16),
  );
  if (
    !await crypto.subtle.verify(
      "HMAC",
      key,
      bytes,
      new TextEncoder().encode(raw),
    )
  ) return null;
  let event: SimulationEvent;
  try {
    event = JSON.parse(raw);
  } catch {
    return null;
  }
  if (
    !event || typeof event !== "object" ||
    !Number.isSafeInteger(event.timestamp) ||
    Math.abs(now - event.timestamp) > 300000 ||
    !/^[0-9a-f-]{36}$/i.test(event.transfer_id) ||
    !["processing", "success", "failed", "reversed"].includes(event.status)
  ) return null;
  return event;
}
