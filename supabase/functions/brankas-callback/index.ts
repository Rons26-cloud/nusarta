import { createClient } from "@supabase/supabase-js";
import {
  reply,
  safeError,
  sandboxEnabled,
  verifySimulationEvent,
} from "../_shared/hub_sandbox.ts";

// Explicit NUSARTA simulator protocol, NOT an invented Brankas signature spec.
// Real Brankas callbacks stay rejected until the provider contract is verified.
export async function callback(request: Request): Promise<Response> {
  if (request.method !== "POST") {
    return reply({ error: "method_not_allowed" }, 405);
  }
  if (!sandboxEnabled(Deno.env.get)) {
    return reply({ error: "callback_not_configured" }, 503);
  }
  if (!request.headers.get("content-type")?.includes("application/json")) {
    return reply({ error: "invalid_content_type" }, 415);
  }
  try {
    const event = await verifySimulationEvent(
      await request.text(),
      request.headers.get("x-nusarta-simulator-signature"),
      Deno.env.get("NUSARTA_SIMULATOR_CALLBACK_SECRET"),
    );
    if (!event) return reply({ error: "invalid_signature_or_event" }, 401);
    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const { data, error } = await db.rpc("hub_apply_simulation_event", {
      p_transfer: event.transfer_id,
      p_status: event.status,
    });
    return error
      ? reply({ error: safeError(error.message) }, 409)
      : reply({ accepted: true, status: data.status });
  } catch {
    return reply({ error: "callback_unavailable" }, 503);
  }
}
if (import.meta.main) Deno.serve(callback);
