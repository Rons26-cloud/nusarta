import 'package:flutter_test/flutter_test.dart';
import 'package:nusarta/core/utils/account_status.dart';
import 'package:nusarta/data/models/account.dart';

Account _account({
  ConnectionType type = ConnectionType.manual,
  ConnectionStatus status = ConnectionStatus.manual,
}) =>
    Account(
      id: 'a',
      userId: 'u',
      name: 'Test',
      type: AccountType.bank,
      balance: 0,
      connectionType: type,
      connectionStatus: status,
    );

void main() {
  test('V1 manual account maps to Manual badge', () {
    expect(badgeStateFor(_account()), AccountBadgeState.manual);
    expect(badgeLabelFor(AccountBadgeState.manual), 'Manual');
  });

  test('active non-manual connection maps to Connected', () {
    final connected = _account(
      type: ConnectionType.bankApi,
      status: ConnectionStatus.active,
    );
    expect(badgeStateFor(connected), AccountBadgeState.connected);
  });

  test('a manual account is never shown as Connected even if status active',
      () {
    final weird = _account(
      type: ConnectionType.manual,
      status: ConnectionStatus.active,
    );
    expect(badgeStateFor(weird), isNot(AccountBadgeState.connected));
  });

  test('lifecycle statuses map to reserved badges', () {
    expect(
      badgeStateFor(_account(status: ConnectionStatus.pending)),
      AccountBadgeState.pending,
    );
    expect(
      badgeStateFor(_account(status: ConnectionStatus.expired)),
      AccountBadgeState.needsAttention,
    );
    expect(
      badgeStateFor(_account(status: ConnectionStatus.error)),
      AccountBadgeState.needsAttention,
    );
    expect(
      badgeStateFor(_account(status: ConnectionStatus.revoked)),
      AccountBadgeState.revoked,
    );
    expect(
      badgeStateFor(_account(status: ConnectionStatus.disconnected)),
      AccountBadgeState.revoked,
    );
  });
}
