// Server-side payment-rail contract.
//
// NUSARTA is a financial hub/intermediary, not a bank, custodian, or wallet.
// A rail is only ever described by what it actually implements today, and all
// rails registered here are sandbox-scoped. None of them claims live account
// balances or live account debit, because the product has no such capability
// yet. Capability flags are intentionally static data checked by the UI, so a
// capability must never be reported as available while it is not.
//
// A rail receives the *internal* transfer id as its external id (externalId).
// Each adapter maps that id to its own merchant/external id format.
//
// The registry currently holds the single NUSARTA rail: Brankas Disburse
// Sandbox. The interface is kept general so a future provider can be added by
// registering a second adapter without changing the orchestration contract.
import {
  BrankasProviderError,
  createSandboxDisbursement,
  merchantTxnIdForTransferId,
  retrieveSandboxDisbursement,
} from "./brankas_disburse.ts";
import { EXECUTION_MODE } from "./hub_sandbox.ts";

export const RAIL_BRANKAS_SANDBOX = "brankas_sandbox" as const;
export type RailCode = typeof RAIL_BRANKAS_SANDBOX;

export type RailEnvironment = "sandbox" | "live";

export interface RailCapabilities {
  environment: RailEnvironment;
  supportsBankTransfer: boolean;
  supportsEwalletTransfer: boolean;
  supportsBalanceRead: boolean;
  supportsAccountDebit: boolean;
}

export type RailTransferStatus =
  | "pending"
  | "processing"
  | "succeeded"
  | "failed"
  | "cancelled"
  | "unknown";

export interface RailTransferRequest {
  externalId: string;
  bankCode: string;
  accountNumber: string;
  accountHolderName: string;
  amountMinor: string;
  currency: string;
  destinationAddress?: {
    line1: string;
    line2: string;
    city: string;
    province: string;
    zip_code: string;
    country: string;
  };
  description?: string;
}

export interface RailTransferResult {
  externalId: string;
  providerReference?: string;
  providerStatus?: string;
  status: RailTransferStatus;
  rawStatusKnown: boolean;
}

export interface RailWebhookResult {
  event: string;
  externalId?: string;
  status: RailTransferStatus;
}

export interface PaymentRail {
  readonly code: RailCode;
  readonly capabilities: RailCapabilities;
  createTransfer(input: RailTransferRequest): Promise<RailTransferResult>;
  getTransferStatus(externalId: string): Promise<RailTransferResult>;
  handleWebhook(raw: string, headers: Headers): Promise<RailWebhookResult | null>;
}

const capabilities: RailCapabilities = {
  environment: "sandbox",
  supportsBankTransfer: true,
  supportsEwalletTransfer: false,
  supportsBalanceRead: false,
  supportsAccountDebit: false,
};

const registry: Record<RailCode, RailCapabilities> = {
  [RAIL_BRANKAS_SANDBOX]: capabilities,
};

export function isRailCode(value: unknown): value is RailCode {
  return value === RAIL_BRANKAS_SANDBOX;
}

export function railCapabilities(code: RailCode): RailCapabilities {
  return registry[code];
}

// A rail is reachable only when the platform sandbox execution mode is active
// AND the rail explicitly opts into its sandbox environment. Nothing is ever
// enabled by default.
export function railEnabled(
  code: RailCode,
  env: (key: string) => string | undefined,
): boolean {
  if (env("NUSARTA_EXECUTION_MODE") !== EXECUTION_MODE) return false;
  if (code !== RAIL_BRANKAS_SANDBOX) return false;
  return env("BRANKAS_ENV")?.trim().toLowerCase() === "sandbox";
}

export const brankasSandboxRail: PaymentRail = {
  code: RAIL_BRANKAS_SANDBOX,
  capabilities: registry[RAIL_BRANKAS_SANDBOX],
  async createTransfer(input) {
    const sourceAccountId = Deno.env.get("BRANKAS_SOURCE_ACCOUNT_ID")?.trim();
    if (!sourceAccountId) throw new BrankasProviderError("provider_not_configured", 503);
    if (!input.destinationAddress) {
      throw new BrankasProviderError("destination_address_invalid", 400);
    }
    const result = await createSandboxDisbursement({
      sourceAccountId,
      destinationBank: input.bankCode,
      destinationNumber: input.accountNumber,
      destinationHolderName: input.accountHolderName,
      amountMinor: input.amountMinor,
      currency: input.currency,
      merchantTxnId: merchantTxnIdForTransferId(input.externalId),
      destinationAddress: input.destinationAddress,
      remark: input.description,
    });
    return {
      externalId: input.externalId,
      providerReference: result.providerDisbursementId ?? result.providerReferenceId,
      providerStatus: result.providerStatus,
      status: result.status,
      rawStatusKnown: result.rawStatusKnown,
    };
  },
  async getTransferStatus(externalId) {
    const result = await retrieveSandboxDisbursement(
      merchantTxnIdForTransferId(externalId),
    );
    return {
      externalId,
      providerReference: result.providerDisbursementId ?? result.providerReferenceId,
      providerStatus: result.providerStatus,
      status: result.status,
      rawStatusKnown: result.rawStatusKnown,
    };
  },
  // Real Brankas callbacks stay rejected until their contract is verified.
  handleWebhook() {
    return Promise.resolve(null);
  },
};

export function createRail(code: RailCode): PaymentRail {
  if (!isRailCode(code)) throw new BrankasProviderError("unsupported_rail", 400);
  return brankasSandboxRail;
}