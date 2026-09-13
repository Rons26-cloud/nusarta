import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { BrankasProviderError, createSandboxDisbursement, merchantTxnIdForTransferId, retrieveSandboxDisbursement } from "../_shared/brankas_disburse.ts";

const headers = { "content-type": "application/json; charset=utf-8" };
const json = (body: Record<string, unknown>, status: number) => new Response(JSON.stringify(body), { status, headers });
function text(value: unknown, max = 160): string | null {
  if (typeof value !== "string") return null;
  const valueText = value.trim();
  return valueText.length > 0 && valueText.length <= max ? valueText : null;
}
function authClient() {
  return createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, { auth: { persistSession: false, autoRefreshToken: false } });
}
function dbClient() {
  return createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
}
Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  if (!(request.headers.get("content-type")?.toLowerCase() ?? "").includes("application/json")) return json({ error: "content_type_must_be_application_json" }, 415);
  const authorization = request.headers.get("authorization");
  if (!authorization?.toLowerCase().startsWith("bearer ")) return json({ error: "authentication_required" }, 401);
  let payload: unknown;
  try { payload = await request.json(); } catch (_) { return json({ error: "invalid_json" }, 400); }
  if (payload === null || typeof payload !== "object" || Array.isArray(payload)) return json({ error: "json_object_required" }, 400);
  const idempotencyKey = text(request.headers.get("x-nusarta-request-key"), 128) ?? crypto.randomUUID();
  const body = payload as Record<string, unknown>;
  const sourceAccountId = text(body.source_account_id, 80);
  const destinationBank = text(body.destination_bank, 80);
  const destinationNumber = text(body.destination_number, 80);
  const currency = text(body.currency, 3);
  const amount = body.amount_minor;
  if (!sourceAccountId || !destinationBank || !destinationNumber || currency !== "IDR" || typeof amount !== "string" || !/^\d+$/.test(amount) || BigInt(amount) <= 0n) return json({ error: "invalid_disbursement_input" }, 400);

  const { data: userData, error: userError } = await authClient().auth.getUser(authorization.slice(7));
  if (userError || !userData.user) return json({ error: "authentication_required" }, 401);
  const db = dbClient();
  const { data: source } = await db.from("accounts").select("id").eq("id", sourceAccountId).eq("user_id", userData.user.id).eq("is_archived", false).maybeSingle();
  if (!source) return json({ error: "source_account_not_owned" }, 403);
  const providerSourceAccountId = Deno.env.get("BRANKAS_SOURCE_ACCOUNT_ID")?.trim();
  if (!providerSourceAccountId || !/^[0-9a-fA-F-]{36}$/.test(providerSourceAccountId)) return json({ error: "brankas_source_account_not_configured" }, 503);
  const { data: existing } = await db.from("future_transfers").select("id,status,provider_reference").eq("user_id", userData.user.id).eq("idempotency_key", idempotencyKey).maybeSingle();
  if (existing) return json({ internal_transfer_id: existing.id, status: existing.status, provider_reference: existing.provider_reference }, 200);
  const { data: created, error: createError } = await db.from("future_transfers").insert({ user_id: userData.user.id, source_financial_account_id: sourceAccountId, destination_type: "bank", amount: Number(amount) / 100, fee_amount: 0, total_amount: Number(amount) / 100, currency, provider: "brankas_disburse_sandbox", status: "draft", idempotency_key: idempotencyKey }).select("id").single();
  if (createError || !created) return json({ error: "transfer_record_unavailable" }, 503);
  const merchantTxnId = merchantTxnIdForTransferId(created.id);
  try {
    const result = await createSandboxDisbursement({ sourceAccountId: providerSourceAccountId, destinationBank, destinationNumber, destinationAddress: { line1: "NUSARTA Sandbox Test Address", line2: "NUSARTA Sandbox", city: "Jakarta", province: "DKI Jakarta", zip_code: "10110", country: "ID" }, amountMinor: String(Number(amount) / 100), currency, merchantTxnId, remark: text(body.remark, 140) ?? undefined });
    const dbStatus = result.status === "succeeded" ? "success" : result.status === "failed" ? "failed" : "pending";
    await db.from("future_transfers").update({ status: dbStatus, provider_reference: result.providerReferenceId ?? result.providerDisbursementId }).eq("id", created.id);
    return json({ internal_transfer_id: created.id, ...result }, 202);
  } catch (error) {
    const providerError = error instanceof BrankasProviderError ? error : new BrankasProviderError("provider_request_failed", 502);
    const failureStatus = providerError.code === "provider_network_error" ? "pending" : "failed";
    await db.from("future_transfers").update({ status: failureStatus, failure_code: providerError.code, failure_message: providerError.details ?? null }).eq("id", created.id);
    return json({ error: providerError.code, provider_error: providerError.details ?? null, internal_transfer_id: created.id }, providerError.httpStatus);
  }
});
