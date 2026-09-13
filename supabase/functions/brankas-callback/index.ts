const jsonHeaders = {
  "content-type": "application/json; charset=utf-8",
};

function json(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: jsonHeaders,
  });
}

function requestId(request: Request): string | null {
  return request.headers.get("x-request-id") ??
    request.headers.get("x-correlation-id");
}

function providerReference(payload: Record<string, unknown>): string | null {
  const candidates = [
    payload.provider_transaction_id,
    payload.providerTransactionId,
    payload.transaction_id,
    payload.transactionId,
    payload.reference,
    payload.reference_id,
    payload.referenceId,
    payload.id,
  ];
  const value = candidates.find((candidate) =>
    typeof candidate === "string" && candidate.trim().length > 0
  );
  return typeof value === "string" ? value.trim() : null;
}

function idempotencyKey(
  request: Request,
  payload: Record<string, unknown>,
): string | null {
  const supplied = request.headers.get("idempotency-key");
  if (supplied?.trim()) return supplied.trim();
  return providerReference(payload);
}

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  const contentType = request.headers.get("content-type")?.toLowerCase() ?? "";
  if (!contentType.includes("application/json")) {
    return json({ error: "content_type_must_be_application_json" }, 415);
  }

  let payload: unknown;
  try {
    payload = await request.json();
  } catch (_) {
    return json({ error: "invalid_json" }, 400);
  }

  if (payload === null || typeof payload !== "object" || Array.isArray(payload)) {
    return json({ error: "json_object_required" }, 400);
  }

  const body = payload as Record<string, unknown>;
  const providerRef = providerReference(body);
  const key = idempotencyKey(request, body);

  // No transfer state is changed here. Provider authentication/signature
  // verification and durable idempotency storage require Brankas' callback spec.
  return json({
    accepted: true,
    provider_reference_present: providerRef !== null,
    idempotency_key_present: key !== null,
    request_id_present: requestId(request) !== null,
    processing_status: "received",
  }, 202);
});
