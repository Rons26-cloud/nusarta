import { createClient } from "@supabase/supabase-js";
import {
  BrankasProviderError,
  merchantTxnIdForTransferId,
  retrieveSandboxDisbursement,
} from "../_shared/brankas_disburse.ts";

const headers = { "content-type": "application/json; charset=utf-8" };
const json = (body: Record<string, unknown>, status: number) =>
  new Response(JSON.stringify(body), { status, headers });

function dbClient() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}
function authClient() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { auth: { persistSession: false, autoRefreshToken: false } },
  );
}
function text(value: unknown, max = 100): string | null {
  if (typeof value !== "string") return null;
  const result = value.trim();
  return result.length > 0 && result.length <= max ? result : null;
}

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }
  const authorization = request.headers.get("authorization");
  if (!authorization?.toLowerCase().startsWith("bearer ")) {
    return json({ error: "authentication_required" }, 401);
  }
  if (
    !(request.headers.get("content-type")?.toLowerCase() ?? "").includes(
      "application/json",
    )
  ) return json({ error: "content_type_must_be_application_json" }, 415);
  let payload: unknown;
  try {
    payload = await request.json();
  } catch (_) {
    return json({ error: "invalid_json" }, 400);
  }
  if (
    payload === null || typeof payload !== "object" || Array.isArray(payload)
  ) return json({ error: "json_object_required" }, 400);
  const internalTransferId = text(
    (payload as Record<string, unknown>).internal_transfer_id,
  );
  if (!internalTransferId) {
    return json({ error: "internal_transfer_id_required" }, 400);
  }

  const auth = await authClient().auth.getUser(authorization.slice(7));
  if (auth.error || !auth.data.user) {
    return json({ error: "authentication_required" }, 401);
  }
  const db = dbClient();
  const { data: transfer } = await db.from("future_transfers").select(
    "id,user_id,status,provider,provider_reference",
  ).eq("id", internalTransferId).eq("user_id", auth.data.user.id).maybeSingle();
  if (!transfer) return json({ error: "transfer_not_found" }, 404);
  if (transfer.provider !== "brankas_disburse_sandbox") {
    return json({ error: "unsupported_provider" }, 409);
  }
  if (
    transfer.provider_reference &&
    ["success", "succeeded", "failed", "cancelled"].includes(
      String(transfer.status),
    )
  ) {
    return json({
      internal_transfer_id: transfer.id,
      status: transfer.status,
      provider_reference: transfer.provider_reference,
      reconciled: false,
    }, 200);
  }

  const merchantTxnId = merchantTxnIdForTransferId(transfer.id);
  try {
    const result = await retrieveSandboxDisbursement(merchantTxnId);
    const status = result.status === "succeeded"
      ? "success"
      : result.status === "failed"
      ? "failed"
      : result.status === "cancelled"
      ? "cancelled"
      : result.status === "processing"
      ? "processing"
      : result.status === "pending"
      ? "pending"
      : "unknown";
    const providerReference = result.providerReferenceId ??
      result.providerDisbursementId ?? transfer.provider_reference;
    if (status === "unknown") {
      return json({
        internal_transfer_id: transfer.id,
        status: transfer.status,
        reconciled: false,
      }, 200);
    }
    const { error: updateError } = await db.from("future_transfers").update({
      status,
      provider_reference: providerReference,
      completed_at: ["success", "failed", "cancelled"].includes(status)
        ? new Date().toISOString()
        : null,
    }).eq("id", transfer.id).eq("user_id", auth.data.user.id).eq(
      "status",
      transfer.status,
    );
    if (updateError) return json({ error: "reconciliation_write_failed" }, 503);
    return json({
      internal_transfer_id: transfer.id,
      status,
      provider_reference: providerReference,
      provider_status: result.providerStatus ?? null,
      reconciled: true,
    }, 200);
  } catch (error) {
    const code = error instanceof BrankasProviderError
      ? error.code
      : "provider_request_failed";
    return json({
      internal_transfer_id: transfer.id,
      status: transfer.status === "pending" ? "pending" : "unknown",
      reconciled: false,
      error: code,
    }, 502);
  }
});
