import { FEATURE_FLAGS, type FeatureFlagId } from "@nusarta/types";

// Feature flags: keep web, mobile, and database defaults aligned.
// Future integrations remain disabled until backend and provider support exist.
export const defaultFeatureFlags: Record<FeatureFlagId, boolean> = {
  linked_accounts: FEATURE_FLAGS.linked_accounts.defaultEnabled,
  bank_sync: FEATURE_FLAGS.bank_sync.defaultEnabled,
  ewallet_sync: FEATURE_FLAGS.ewallet_sync.defaultEnabled,
  transfers: FEATURE_FLAGS.transfers.defaultEnabled,
  transfer_recipient_validation:
    FEATURE_FLAGS.transfer_recipient_validation.defaultEnabled,
  push_notifications: FEATURE_FLAGS.push_notifications.defaultEnabled,
  institution_catalog: FEATURE_FLAGS.institution_catalog.defaultEnabled,
};

/** Lightweight in-app flag lookup with a provided (backend) map. */
export function isFeatureEnabled(
  feature: FeatureFlagId,
  overrides: Partial<Record<FeatureFlagId, boolean>> = {}
): boolean {
  return overrides[feature] ?? defaultFeatureFlags[feature];
}
