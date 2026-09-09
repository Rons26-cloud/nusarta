import 'package:flutter_test/flutter_test.dart';
import 'package:nusarta/core/config/feature_flags.dart';

void main() {
  test('future capabilities default to OFF in V1', () {
    expect(FeatureFlags.isEnabled(FeatureFlag.linkedAccounts), isFalse);
    expect(FeatureFlags.isEnabled(FeatureFlag.bankSync), isFalse);
    expect(FeatureFlags.isEnabled(FeatureFlag.ewalletSync), isFalse);
    expect(FeatureFlags.isEnabled(FeatureFlag.transfers), isFalse);
    expect(FeatureFlags.isEnabled(FeatureFlag.transferRecipientValidation),
        isFalse);
    expect(FeatureFlags.isEnabled(FeatureFlag.pushNotifications), isFalse);
  });

  test('institution catalog is informational and enabled', () {
    expect(FeatureFlags.isEnabled(FeatureFlag.institutionCatalog), isTrue);
  });

  test('overrides take precedence', () {
    expect(
      FeatureFlags.isEnabled(FeatureFlag.transfers,
          overrides: {FeatureFlag.transfers: true}),
      isTrue,
    );
  });
}
