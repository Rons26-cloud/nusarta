export type ReleaseChannel = "stable" | "beta";

export interface ReleaseMeta {
  version: string;
  buildNumber: string;
  releaseDate: string;
  platform: "android";
  channel: ReleaseChannel;
  downloadUrl: string;
  apkFileName: string;
  checksumSha256: string;
  minimumAndroidVersion: string;
  fileSizeMb: string;
  notes: string[];
}

// Financial domain types (V1 + future-ready V1.5/V2/V3)

// V1 account types.
export type AccountType = "cash" | "bank" | "ewallet" | "custom";

// Transaction direction (V1).
export type TransactionKind = "income" | "expense" | "transfer";

// Transaction provenance (V1 uses 'manual'; future values reserved).
export type TransactionSource = "manual" | "imported" | "bank_api" | "wallet_api";

// Future-ready domain model (V1.5+)

// Institutions (banks, e-wallets, cash) in the catalog.
export type InstitutionType = "bank" | "ewallet" | "cash" | "other";

export interface Institution {
  id: string;
  code: string;
  name: string;
  institutionType: InstitutionType;
  logoUrl?: string;
  country: string;
  isActive: boolean;
  providerSupport: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

// Financial accounts (extends V1 `accounts` with connection fields).
export type FinancialConnectionType =
  | "manual"
  | "bank_api"
  | "ewallet_api"
  | "open_banking"
  | "payment_provider";

export type FinancialConnectionStatus =
  | "manual"
  | "disconnected"
  | "pending"
  | "active"
  | "expired"
  | "error"
  | "revoked";

export interface FinancialAccount {
  id: string;
  userId: string;
  institutionId?: string;
  name: string;
  type: AccountType;
  displayName?: string;
  maskedAccountNumber?: string;
  lastFour?: string;
  currency: string;
  connectionType: FinancialConnectionType;
  connectionStatus: FinancialConnectionStatus;
  provider?: string;
  providerAccountId?: string;
  isPrimary: boolean;
  isArchived: boolean;
  createdAt: string;
  updatedAt: string;
}

// Balance source distinguishes how a balance value was obtained.
export type BalanceSource = "calculated" | "manual" | "provider";

export interface AccountBalance {
  ledgerBalance: number;
  providerBalance?: number;
  availableBalance?: number;
  lastSyncedAt?: string;
  source: BalanceSource;
}

// Transactions (V1 + future status/source).
export type TransactionStatus =
  | "pending"
  | "completed"
  | "failed"
  | "reversed"
  | "cancelled";

export type TransactionFlow = "income" | "expense" | "transfer_in" | "transfer_out" | "adjustment" | "refund";

export interface FinancialTransaction {
  id: string;
  userId: string;
  financialAccountId: string;
  categoryId?: string;
  amount: number;
  currency: string;
  type: TransactionFlow;
  status: TransactionStatus;
  source: TransactionSource;
  title?: string;
  description?: string;
  occurredAt: string;
  providerReference?: string;
  transferId?: string;
  metadata?: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

// Account connections (future linked bank/e-wallet).
export interface AccountConnection {
  id: string;
  userId: string;
  institutionId: string;
  financialAccountId?: string;
  provider?: string;
  providerConnectionId?: string;
  status: FinancialConnectionStatus;
  scopes: string[];
  consentExpiresAt?: string;
  lastSyncedAt?: string;
  lastErrorCode?: string;
  lastErrorAt?: string;
  createdAt: string;
  updatedAt: string;
}

// External transfers (NOT internal transfer). Placeholder for V3.
export type TransferStatus =
  | "draft"
  | "awaiting_authorization"
  | "pending"
  | "processing"
  | "success"
  | "failed"
  | "reversed"
  | "cancelled";

export type DestinationType = "bank" | "ewallet" | "internal_future";

export interface Transfer {
  id: string;
  userId: string;
  sourceFinancialAccountId: string;
  destinationType: DestinationType;
  destinationInstitutionId?: string;
  destinationAccountReference?: string;
  recipientName?: string;
  amount: number;
  feeAmount: number;
  totalAmount: number;
  currency: string;
  provider?: string;
  providerReference?: string;
  status: TransferStatus;
  idempotencyKey?: string;
  failureCode?: string;
  failureMessage?: string;
  createdAt: string;
  authorizedAt?: string;
  processedAt?: string;
  completedAt?: string;
  updatedAt: string;
}

// Devices (device management).
export type DevicePlatform = "android" | "ios" | "web" | "other";

export interface Device {
  id: string;
  userId: string;
  deviceIdentifier: string;
  platform: DevicePlatform;
  appVersion?: string;
  deviceName?: string;
  trusted: boolean;
  biometricEnabled: boolean;
  lastSeenAt: string;
  revokedAt?: string;
  createdAt: string;
}

// Notifications.
export type NotificationType =
  | "transaction"
  | "budget"
  | "security"
  | "account_connection"
  | "transfer"
  | "system";

export interface AppNotification {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  body?: string;
  data: Record<string, unknown>;
  isRead: boolean;
  createdAt: string;
}

// Feature flags.
export interface FeatureFlag {
  id: string;
  enabled: boolean;
  description?: string;
  updatedAt: string;
}

// Feature flags: future capabilities default to OFF.
export const FEATURE_FLAG_IDS = [
  "linked_accounts",
  "bank_sync",
  "ewallet_sync",
  "transfers",
  "transfer_recipient_validation",
  "push_notifications",
  "institution_catalog",
] as const;

export type FeatureFlagId = (typeof FEATURE_FLAG_IDS)[number];

export const FEATURE_FLAGS: Record<
  FeatureFlagId,
  { label: string; description: string; defaultEnabled: boolean }
> = {
  linked_accounts: {
    label: "Linked Accounts",
    description: "Hubungkan rekening bank / e-wallet",
    defaultEnabled: false,
  },
  bank_sync: {
    label: "Bank Sync",
    description: "Sinkronisasi saldo bank",
    defaultEnabled: false,
  },
  ewallet_sync: {
    label: "E-Wallet Sync",
    description: "Sinkronisasi saldo e-wallet",
    defaultEnabled: false,
  },
  transfers: {
    label: "Transfers",
    description: "Transfer antar rekening / e-wallet",
    defaultEnabled: false,
  },
  transfer_recipient_validation: {
    label: "Recipient Validation",
    description: "Validasi penerima transfer",
    defaultEnabled: false,
  },
  push_notifications: {
    label: "Push Notifications",
    description: "Notifikasi push",
    defaultEnabled: false,
  },
  institution_catalog: {
    label: "Institution Catalog",
    description: "Katalog institusi (bank / e-wallet)",
    defaultEnabled: true,
  },
};
