export type NusartaTransferStatus =
  | "pending"
  | "processing"
  | "succeeded"
  | "failed"
  | "cancelled"
  | "unknown";

export interface DisbursementInput {
  sourceAccountId: string;
  destinationBank: string;
  destinationNumber: string;
  destinationHolderName: string;
  amountMinor: string;
  currency: string;
  merchantTxnId: string;
  destinationAddress: DestinationAddress;
  remark?: string;
}

export interface DestinationAddress {
  line1: string;
  line2: string;
  city: string;
  province: string;
  zip_code: string;
  country: string;
}

export interface DisbursementResult {
  merchantTxnId: string;
  providerDisbursementId?: string;
  providerReferenceId?: string;
  providerStatus?: string;
  status: NusartaTransferStatus;
  feeMinor?: string;
  rawStatusKnown: boolean;
}

export class BrankasProviderError extends Error {
  constructor(
    public readonly code: string,
    public readonly httpStatus: number,
    public readonly details?: string,
  ) {
    super(code);
  }
}

const sandboxBaseUrl = "https://disburse.sandbox.bnk.to";
const timeoutMs = 15_000;

export function merchantTxnIdForTransferId(transferId: string): string {
  const compactId = transferId.replaceAll("-", "");
  const merchantTxnId = `ns-${compactId}`;
  if (merchantTxnId.length > 40) throw new BrankasProviderError("merchant_txn_id_invalid", 400);
  return merchantTxnId;
}

// Server-side validation, always executed BEFORE any provider configuration or
// network access. The Brankas sandbox rejects destination_account.address when
// it is missing, so the address contract is enforced locally with explicit
// error codes instead of passing a blank payload to the provider.
export function validateDestinationAddress(
  address: unknown,
): asserts address is DestinationAddress {
  if (address === null || typeof address !== "object" || Array.isArray(address)) {
    throw new BrankasProviderError("destination_address_required", 400);
  }
  const value = address as Record<string, unknown>;
  for (const key of ["line1", "city", "province", "zip_code", "country"] as const) {
    const field = value[key];
    if (
      typeof field !== "string" || field.trim().length === 0 ||
      field.trim().length > 200
    ) {
      throw new BrankasProviderError(
        "destination_address_invalid",
        400,
        `destination_address.${key} is required`,
      );
    }
  }
  if (
    value.line2 !== undefined && value.line2 !== "" && value.line2 !== null &&
    (typeof value.line2 !== "string" || value.line2.trim().length > 200)
  ) {
    throw new BrankasProviderError(
      "destination_address_invalid",
      400,
      "destination_address.line2 is invalid",
    );
  }
  const country = String(value.country).trim();
  if (!/^[A-Za-z]{2}$/.test(country)) {
    throw new BrankasProviderError("destination_country_invalid", 400);
  }
}

function validateDisbursementInput(input: DisbursementInput): void {
  if (!input.sourceAccountId.trim()) throw new BrankasProviderError("invalid_disbursement_input", 400);
  if (!input.destinationBank.trim() || input.destinationBank.length > 80) throw new BrankasProviderError("invalid_disbursement_input", 400);
  if (!input.destinationNumber.trim() || input.destinationNumber.length > 80) throw new BrankasProviderError("invalid_disbursement_input", 400);
  if (typeof input.destinationHolderName !== "string" || input.destinationHolderName.trim().length === 0 || input.destinationHolderName.length > 200) throw new BrankasProviderError("destination_holder_invalid", 400);
  validateDestinationAddress(input.destinationAddress);
  if (input.currency !== "IDR" || !/^\d+$/.test(input.amountMinor) || BigInt(input.amountMinor) <= 0n) throw new BrankasProviderError("invalid_disbursement_input", 400);
  if (input.merchantTxnId.length < 1 || input.merchantTxnId.length > 40) throw new BrankasProviderError("merchant_txn_id_invalid", 400);
}
function assertSandboxConfig(): void {
  const configuredEnv = Deno.env.get("BRANKAS_ENV")?.trim().toLowerCase();
  if (configuredEnv !== "sandbox") throw new BrankasProviderError("sandbox_only", 503);
  const configuredBase = Deno.env.get("BRANKAS_DISBURSE_BASE_URL")?.trim() || sandboxBaseUrl;
  let parsed: URL;
  try { parsed = new URL(configuredBase); } catch (_) {
    throw new BrankasProviderError("sandbox_base_url_invalid", 503);
  }
  if (parsed.protocol !== "https:" || parsed.hostname !== "disburse.sandbox.bnk.to" || parsed.port !== "" || (parsed.pathname !== "" && parsed.pathname !== "/") || parsed.search !== "" || parsed.hash !== "") {
    throw new BrankasProviderError("sandbox_base_url_invalid", 503);
  }
}

export function mapStatus(status: unknown): NusartaTransferStatus {
  switch (status) {
    case "CREATED":
    case "PENDING":
    case "NOT_PROCESSED":
      return "pending";
    case "FLAGGED":
      return "processing";
    case "SUCCESS":
      return "succeeded";
    case "FAILED":
    case "ERROR":
      return "failed";
    default:
      return "unknown";
  }
}

// Extracts a short, safe summary of a provider rejection body. It never echoes
// raw provider payloads, tokens or credentials, and always caps the length.
function safeProviderError(body: unknown): string | undefined {
  if (body === null || typeof body !== "object") return undefined;
  const parts: string[] = [];
  const push = (text: unknown): void => {
    if (typeof text !== "string") return;
    const cleaned = text.trim().replace(/\s+/g, " ");
    if (cleaned.length > 0 && cleaned.length <= 160) parts.push(cleaned);
  };
  const describe = (item: unknown): void => {
    if (typeof item === "string") {
      push(item);
      return;
    }
    if (Array.isArray(item)) {
      item.forEach(describe);
      return;
    }
    if (item === null || typeof item !== "object") return;
    const object = item as Record<string, unknown>;
    const message = object.message;
    const code = object.error_code ?? object.code;
    const field = object.field;
    const reason = object.reason;
    const combined = typeof field === "string" && field.trim().length > 0
      ? `${field.trim()} ${typeof message === "string" ? message : typeof reason === "string" ? reason : ""}`.trim()
      : typeof message === "string" ? message : typeof reason === "string" ? reason : undefined;
    push(combined);
    push(typeof code === "string" ? `code: ${code}` : undefined);
    if (combined === undefined && code === undefined && reason === undefined) {
      for (const value of Object.values(object)) describe(value);
    }
  };
  describe((body as Record<string, unknown>).errors);
  describe((body as Record<string, unknown>).message);
  describe((body as Record<string, unknown>).error);
  describe((body as Record<string, unknown>).code);
  return parts.length > 0 ? parts.slice(0, 4).join("; ") : undefined;
}

// Maps a provider HTTP rejection into a BrankasProviderError. Provider-side
// request rejections (4xx) keep their own status so callers can distinguish a
// rejected request from an infrastructure failure; 5xx/unknown stay 502. Only
// safe diagnostic text is included.
function providerHttpFailure(status: number, body: unknown): BrankasProviderError {
  const clientRejection = status >= 400 && status < 500;
  return new BrankasProviderError(
    `provider_http_${status}`,
    clientRejection ? status : 502,
    safeProviderError(body) ??
      (clientRejection
        ? "Provider rejected the request."
        : "Provider acceptance is unconfirmed."),
  );
}
function readFeeMinor(disbursement: Record<string, unknown>): string | undefined {
  const fees = disbursement.fees;
  if (!Array.isArray(fees)) return undefined;
  const total = fees.reduce((sum, item) => {
    if (item === null || typeof item !== "object") return sum;
    const amount = (item as Record<string, unknown>).amount;
    if (amount === null || typeof amount !== "object") return sum;
    const value = (amount as Record<string, unknown>).num;
    if (typeof value !== "string" || !/^\d+$/.test(value)) return sum;
    return sum + BigInt(value);
  }, 0n);
  return total > 0n ? total.toString() : undefined;
}

function parseResponse(body: unknown, merchantTxnId: string): DisbursementResult {
  if (body === null || typeof body !== "object") {
    throw new BrankasProviderError("provider_invalid_response", 502);
  }
  const result = (body as Record<string, unknown>).result;
  const first = Array.isArray(result) ? result[0] : undefined;
  if (first === null || typeof first !== "object") {
    throw new BrankasProviderError("provider_missing_result", 502);
  }
  const disbursement = (first as Record<string, unknown>).disbursement;
  if (disbursement === null || typeof disbursement !== "object") {
    throw new BrankasProviderError("provider_missing_disbursement", 502);
  }
  const value = disbursement as Record<string, unknown>;
  const providerStatus = typeof value.status === "string" ? value.status : undefined;
  const external = value.external;
  const externalReference = external !== null && typeof external === "object"
    ? (external as Record<string, unknown>).reference_id
    : undefined;
  return {
    merchantTxnId,
    providerDisbursementId: typeof value.disbursement_id === "string" ? value.disbursement_id : undefined,
    providerReferenceId: typeof externalReference === "string" ? externalReference : undefined,
    providerStatus,
    status: mapStatus(providerStatus),
    feeMinor: readFeeMinor(value),
    rawStatusKnown: providerStatus !== undefined && mapStatus(providerStatus) !== "unknown",
  };
}

export async function createSandboxDisbursement(
  input: DisbursementInput,
  options: { fetchImpl?: (
    url: string | URL,
    init?: RequestInit,
  ) => Promise<Response> } = {},
): Promise<DisbursementResult> {
  validateDisbursementInput(input);
  const apiKey = Deno.env.get("BRANKAS_API_KEY")?.trim();  if (!apiKey) throw new BrankasProviderError("provider_not_configured", 503);
  assertSandboxConfig();

  const address = input.destinationAddress;
  const addressPayload: {
    line1: string;
    line2?: string;
    city: string;
    province: string;
    zip_code: string;
    country: string;
  } = {
    line1: address.line1.trim(),
    line2: address.line2?.length > 0 ? address.line2.trim() : "",
    city: address.city.trim(),
    province: address.province.trim(),
    zip_code: address.zip_code.trim(),
    country: address.country.trim().toUpperCase(),
  };
  if (addressPayload.line2 === "") delete addressPayload.line2;
  const destinationAccount: Record<string, unknown> = {
    bank: input.destinationBank,
    number: input.destinationNumber,
    holder_name: input.destinationHolderName.trim(),
    type: "PERSONAL",
    address: addressPayload,
  };

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await (options.fetchImpl ?? fetch)(
      `${sandboxBaseUrl}/v2/disbursements`,
      {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-api-key": apiKey,
        },
        body: JSON.stringify({
          source_account_id: input.sourceAccountId,
          remark: input.remark,
          disbursements: [{
            merchant_txn_id: input.merchantTxnId,
            type: "PAYMENT",
            destination_account: destinationAccount,
            destination_amount: { num: input.amountMinor, cur: input.currency },
          }],
        }),
        signal: controller.signal,
      },
    );
    let body: unknown;
    try {
      body = await response.json();
    } catch (_) {
      if (!response.ok) throw providerHttpFailure(response.status, undefined);
      throw new BrankasProviderError("provider_invalid_json", 502);
    }
    if (!response.ok) throw providerHttpFailure(response.status, body);
    return parseResponse(body, input.merchantTxnId);
  } catch (error) {
    if (error instanceof BrankasProviderError) throw error;
    throw new BrankasProviderError("provider_network_error", 502);
  } finally {
    clearTimeout(timer);
  }
}

export async function retrieveSandboxDisbursement(merchantTxnId: string): Promise<DisbursementResult> {
  const apiKey = Deno.env.get("BRANKAS_API_KEY")?.trim();  if (!apiKey) throw new BrankasProviderError("provider_not_configured", 503);
  assertSandboxConfig();
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(`${sandboxBaseUrl}/v1/disbursements`, {
      method: "GET",
      headers: { "accept": "application/json", "x-api-key": apiKey },
      signal: controller.signal,
    });
    let body: unknown;
    try { body = await response.json(); } catch (_) {
      if (!response.ok) throw providerHttpFailure(response.status, undefined);
      throw new BrankasProviderError("provider_invalid_json", 502);
    }
    if (!response.ok) throw providerHttpFailure(response.status, body);
    if (body === null || typeof body !== "object") throw new BrankasProviderError("provider_invalid_response", 502);
    const items = (body as Record<string, unknown>).disbursements;
    if (!Array.isArray(items)) throw new BrankasProviderError("provider_missing_disbursements", 502);
    const found = items.find((item) => item !== null && typeof item === "object" && (item as Record<string, unknown>).merchant_txn_id === merchantTxnId);
    if (!found || typeof found !== "object") return { merchantTxnId, status: "unknown", rawStatusKnown: false };
    return parseResponse({ result: [{ disbursement: found }] }, merchantTxnId);
  } catch (error) {
    if (error instanceof BrankasProviderError) throw error;
    throw new BrankasProviderError("provider_network_error", 502);
  } finally { clearTimeout(timer); }
}
