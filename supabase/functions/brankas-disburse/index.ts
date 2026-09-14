import { createClient } from "@supabase/supabase-js";
import {
  EXECUTION_MODE,
  reply,
  safeError,
  sandboxEnabled,
  validAmount,
  validIdentifier,
} from "../_shared/hub_sandbox.ts";

// Extends the existing endpoint. Brankas payout remains blocked until its
// destination/units/authorization contract is verified. No provider POST here.
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
    if (
      body.execution_mode !== EXECUTION_MODE || !validAmount(body.amount) ||
      !validIdentifier(body.destination_identifier)
    ) return reply({ error: "invalid_transfer" }, 400);
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
  } catch {
    return reply({ error: "request_unavailable" }, 400);
  }
}
if (import.meta.main) Deno.serve(disburse);
