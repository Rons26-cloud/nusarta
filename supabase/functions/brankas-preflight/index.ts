import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const reply = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: {
    "content-type": "application/json", "cache-control": "no-store",
  } });

export async function preflight(request: Request): Promise<Response> {
  if (request.method !== "POST") return reply({ error: "method_not_allowed" }, 405);
  const authorization = request.headers.get("authorization");
  if (!authorization?.match(/^Bearer \S+$/i)) return reply({ error: "authentication_required" }, 401);
  try {
    // The caller's JWT is forwarded to Postgres: RLS evaluates auth.uid().
    const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: auth, error: authError } = await db.auth.getUser(authorization.slice(7));
    if (authError || !auth.user) return reply({ error: "authentication_required" }, 401);
    const [source, transfers] = await Promise.all([
      db.from("accounts").select("id,connection_type,connection_status")
        .eq("user_id", auth.user.id).eq("is_archived", false).order("id").limit(1).maybeSingle(),
      db.from("future_transfers").select("id,status")
        .eq("user_id", auth.user.id).eq("provider", "brankas_disburse_sandbox")
        .not("status", "in", "(success,failed,reversed,cancelled)")
        .order("created_at").limit(1).maybeSingle(),
    ]);
    if (source.error || transfers.error) return reply({ error: "preflight_lookup_failed", ready_for_manual_tap: false }, 503);
    const providerSource = Deno.env.get("BRANKAS_SOURCE_ACCOUNT_ID")?.trim() ?? "";
    const sourceReady = Boolean(source.data) && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(providerSource);
    const sandbox = Deno.env.get("BRANKAS_ENV")?.trim().toLowerCase() === "sandbox" &&
      (Deno.env.get("BRANKAS_DISBURSE_BASE_URL")?.trim() || "https://disburse.sandbox.bnk.to").replace(/\/$/, "") === "https://disburse.sandbox.bnk.to";
    // Fail closed: the deployed guard and official destination are not verified.
    return reply({
      auth_user_present: true,
      brankas_source_account_configured: providerSource.length > 0,
      brankas_api_key_configured: Boolean(Deno.env.get("BRANKAS_API_KEY")?.trim()),
      source_account_ready: sourceReady,
      source_financial_account_id: source.data?.id ?? null,
      source_account_kind: source.data?.connection_type === "manual" ? "manual" : "link_unverified",
      active_pending_transfer: Boolean(transfers.data),
      active_transfer_id: transfers.data?.id ?? null,
      active_transfer_status: transfers.data?.status ?? null,
      duplicate_guard_ready: false,
      sandbox_environment: sandbox,
      ready_for_manual_tap: false,
      reason: "deployment_and_destination_unverified",
    });
  } catch (_) {
    return reply({ error: "preflight_unavailable", ready_for_manual_tap: false }, 503);
  }
}
Deno.serve(preflight);
