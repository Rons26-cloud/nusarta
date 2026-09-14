import { createClient } from "@supabase/supabase-js";
import {
  BrankasProviderError,
  createSandboxDisbursement,
  merchantTxnIdForTransferId,
  validateDestinationAddress,
} from "../_shared/brankas_disburse.ts";
import type { DestinationAddress } from "../_shared/brankas_disburse.ts";
import {
  EXECUTION_MODE,
  reply,
  safeError,
  sandboxEnabled,
  validAmount,
  validIdentifier,
} from "../_shared/hub_sandbox.ts";

const sandboxTestDestination: DestinationAddress = {
  line1: "NUSARTA Sandbox Test Address",
  line2: "NUSARTA Sandbox",
  city: "Jakarta",
  province: "DKI Jakarta",
  zip_code: "10110",
  country: "ID",
};

function text(value: unknown, max = 160): string | null {
  if (typeof value !== "string") return null;
  const valueText = value.trim();
  return valueText.length > 0 && valueText.length <= max ? valueText : null;
}

function dbClient() {
  return createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
}

// Legacy sandbox disbursement path. The request does not carry an execution
// mode, so the destination is the Brankas sandbox test account. The shared
// createSandboxDisbursement enforces the destination_account.address contract
// before any provider network call.
async function sandboxDisbursement(
  body: Record<string, unknown>,
  userId: string,
  idempotencyKey: string,
): Promise<Response> {
  const sourceAccountId = text(body.source_account_id, 80);
  const destinationBank = text(body.destination_bank, 80);
  const destinationNumber = text(body.destination_number, 80);
  const currency = text(body.currency, 3);
  const amount = body.amount_minor;
  if (
    !sourceAccountId || !destinationBank || !destinationNumber ||
    currency !== "IDR" || typeof amount !== "string" || !/^\d+$/.test(amount) ||
    BigInt(amount) <= 0n
  ) return reply({ error: "invalid_disbursement_input" }, 400);
  const destinationHolderName = text(body.destination_holder_name, 200) ??
    "NUSARTA Sandbox Test Recipient";
  let destinationAddress: DestinationAddress = sandboxTestDestination;
  if (body.destination_address !== undefined) {
    const rawAddress = body.destination_address;
    try {
      validateDestinationAddress(rawAddress);
      destinationAddress = rawAddress;
    } catch (error) {
      return reply({
        error: error instanceof BrankasProviderError
          ? error.code
          : "destination_address_invalid",
      }, 400);
    }
  }
  const db = dbClient();
  const { data: source } = await db.from("accounts").select("id")
    .eq("id", sourceAccountId).eq("user_id", userId).eq("is_archived", false)
    .maybeSingle();
  if (!source) return reply({ error: "source_account_not_owned" }, 403);
  const providerSourceAccountId = Deno.env.get("BRANKAS_SOURCE_ACCOUNT_ID")?.trim();
  if (!providerSourceAccountId || !/^[0-9a-fA-F-]{36}$/.test(providerSourceAccountId)) {
    return reply({ error: "brankas_source_account_not_configured" }, 503);
  }
  const { data: existing } = await db.from("future_transfers")
    .select("id,status,provider_reference")
    .eq("user_id", userId).eq("idempotency_key", idempotencyKey).maybeSingle();
  if (existing) {
    return reply({
      internal_transfer_id: existing.id,
      status: existing.status,
      provider_reference: existing.provider_reference,
    }, 200);
  }
  const { data: created, error: createError } = await db.from("future_transfers")
    .insert({
      user_id: userId,
      source_financial_account_id: sourceAccountId,
      destination_type: "bank",
      amount: Number(amount) / 100,
      fee_amount: 0,
      total_amount: Number(amount) / 100,
      currency,
      provider: "brankas_disburse_sandbox",
      status: "draft",
      idempotency_key: idempotencyKey,
    }).select("id").single();
  if (createError || !created) return reply({ error: "transfer_record_unavailable" }, 503);
  const merchantTxnId = merchantTxnIdForTransferId(created.id);
  try {
    const result = await createSandboxDisbursement({
      sourceAccountId: providerSourceAccountId,
      destinationBank,
      destinationNumber,
      destinationHolderName,
      amountMinor: String(Number(amount) / 100),
      currency,
      merchantTxnId,
      destinationAddress,
      remark: text(body.remark, 140) ?? undefined,
    });
    const dbStatus = result.status === "succeeded"
      ? "success"
      : result.status === "failed" ? "failed" : "pending";
    await db.from("future_transfers")
      .update({
        status: dbStatus,
        provider_reference: result.providerReferenceId ?? result.providerDisbursementId,
      }).eq("id", created.id);
    return reply({ internal_transfer_id: created.id, ...result }, 202);
  } catch (error) {
    const providerError = error instanceof BrankasProviderError
      ? error
      : new BrankasProviderError("provider_request_failed", 502);
    await db.from("future_transfers")
      .update({
        status: providerError.code === "provider_network_error" ? "pending" : "failed",
        failure_code: providerError.code,
        failure_message: providerError.details ?? null,
      }).eq("id", created.id);
    return reply({
      error: providerError.code,
      provider_error: providerError.details ?? null,
      internal_transfer_id: created.id,
    }, providerError.httpStatus);
  }
}

export async function disburse(request: Request): Promise<Response> {
  if (request.method !== "POST") {
    return reply({ error: "method_not_allowed" }, 405);
  }
  if (!sandboxEnabled(Deno.env.get)) {
    return reply({ error: "sandbox_disabled" }, 503);
  }
  if (!request.headers.get("content-type")?.includes("application/json")) {
    return reply({ error: "invalid_content_type" }, 415);
  }
  const authorization = request.headers.get("authorization");
  if (!authorization?.match(/^Bearer \S+$/i)) {
    return reply({ error: "authentication_required" }, 401);
  }
  try {
    const body = await request.json();
    if (!body || typeof body !== "object" || Array.isArray(body)) {
      return reply({ error: "invalid_request" }, 400);
    }
    const authClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
    );
    const { data: auth, error: authError } = await authClient.auth.getUser(
      authorization.slice(7),
    );
    if (authError || !auth.user) {
      return reply({ error: "authentication_required" }, 401);
    }
    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    if (body.action === "connect") {
      const { data, error } = await db.rpc("hub_connect_simulated", {
        p_user: auth.user.id,
        p_institution: body.institution_id,
      });
      return error
        ? reply({ error: safeError(error.message) }, 409)
        : reply({ account: data, execution_mode: EXECUTION_MODE }, 201);
    }
    if (body.execution_mode === EXECUTION_MODE) {
      if (!validAmount(body.amount) || !validIdentifier(body.destination_identifier)) {
        return reply({ error: "invalid_transfer" }, 400);
      }
      const key = request.headers.get("x-nusarta-request-key");
      if (!key || key.length < 16 || key.length > 128) {
        return reply({ error: "idempotency_key_required" }, 400);
      }
      const { data, error } = await db.rpc("hub_create_transfer", {
        p_user: auth.user.id,
        p_source: body.source_account_id,
        p_destination: body.destination_institution_id,
        p_identifier: body.destination_identifier,
        p_amount: body.amount,
        p_key: key,
        p_own_destination: body.destination_account_id ?? null,
        p_note: body.note ?? null,
      });
      return error
        ? reply({ error: safeError(error.message) }, 409)
        : reply({ transfer: data, execution_mode: EXECUTION_MODE }, 202);
    }
    return await sandboxDisbursement(
      body,
      auth.user.id,
      text(request.headers.get("x-nusarta-request-key"), 128) ??
        crypto.randomUUID(),
    );
  } catch {
    return reply({ error: "request_unavailable" }, 400);
  }
}
if (import.meta.main) Deno.serve(disburse);