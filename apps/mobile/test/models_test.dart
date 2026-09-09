import 'package:flutter_test/flutter_test.dart';
import 'package:nusarta/data/models/account.dart';
import 'package:nusarta/data/models/device.dart';
import 'package:nusarta/data/models/institution.dart';
import 'package:nusarta/data/models/notification.dart';
import 'package:nusarta/data/models/transaction.dart';

void main() {
  group('Account', () {
    test('parses from database row', () {
      final account = Account.fromMap({
        'id': 'a1',
        'user_id': 'u1',
        'name': 'BCA',
        'type': 'bank',
        'balance': 1500000,
        'currency_code': 'IDR',
        'is_archived': false,
        'is_linked': false,
      });
      expect(account.name, 'BCA');
      expect(account.type, AccountType.bank);
      expect(account.balance, 1500000);
      expect(account.connectionType, ConnectionType.manual);
      expect(account.connectionStatus, ConnectionStatus.manual);
      expect(account.isPrimary, isFalse);
    });

    test('parses full V1.5 row', () {
      final account = Account.fromMap({
        'id': 'a2',
        'user_id': 'u1',
        'name': 'Rekening Gaji',
        'display_name': 'Rekening Gaji',
        'type': 'bank',
        'balance': 1000000,
        'currency_code': 'IDR',
        'is_archived': false,
        'institution_id': 'inst-1',
        'masked_account_number': '•••• 1234',
        'last_four': '1234',
        'is_primary': true,
        'connection_type': 'bank_api',
        'connection_status': 'active',
        'last_synced_at': '2026-09-08T08:00:00Z',
      });
      expect(account.institutionId, 'inst-1');
      expect(account.lastFour, '1234');
      expect(account.maskedAccountNumber, '•••• 1234');
      expect(account.isPrimary, isTrue);
      expect(account.connectionType, ConnectionType.bankApi);
      expect(account.connectionStatus, ConnectionStatus.active);
      expect(account.lastSyncedAt, isNotNull);
    });

    test('round-trips through toMap with connection fields', () {
      const account = Account(
        id: 'a3',
        userId: 'u1',
        name: 'DANA',
        type: AccountType.ewallet,
        balance: 50000,
        institutionId: 'inst-2',
        lastFour: '4321',
        maskedAccountNumber: '•••• 4321',
        displayName: 'DANA',
        isPrimary: true,
        connectionType: ConnectionType.manual,
        connectionStatus: ConnectionStatus.manual,
      );
      final map = account.toMap();
      expect(map['institution_id'], 'inst-2');
      expect(map['last_four'], '4321');
      expect(map['masked_account_number'], '•••• 4321');
      expect(map['is_primary'], isTrue);
      expect(map['connection_type'], 'manual');
      expect(map['connection_status'], 'manual');
    });

    test('maps connection enum db values', () {
      expect(ConnectionType.bankApi.dbValue, 'bank_api');
      expect(ConnectionType.fromDb('ewallet_api'), ConnectionType.ewalletApi);
      expect(ConnectionType.fromDb('unknown'), ConnectionType.manual);
      expect(ConnectionStatus.fromDb('pending'), ConnectionStatus.pending);
      expect(ConnectionStatus.fromDb('unknown'), ConnectionStatus.manual);
    });
  });

  group('Institution', () {
    test('parses catalog row and exposes integration availability', () {
      final inst = Institution.fromMap({
        'id': 'inst-1',
        'code': 'bca',
        'name': 'BCA',
        'institution_type': 'bank',
        'country': 'ID',
        'is_active': true,
        'provider_support': {'integration_available': false},
      });
      expect(inst.name, 'BCA');
      expect(inst.isBank, isTrue);
      expect(inst.isEwallet, isFalse);
      expect(inst.hasProviderIntegration, isFalse);
    });
  });

  group('Device', () {
    test('parses row and flags revocation', () {
      final device = Device.fromMap({
        'id': 'd1',
        'user_id': 'u1',
        'device_identifier': 'abc-123',
        'platform': 'android',
        'app_version': '1.0.0+1',
        'device_name': 'NUSARTA (Android)',
        'trusted': true,
        'biometric_enabled': true,
        'last_seen_at': '2026-09-08T08:00:00Z',
        'created_at': '2026-09-01T08:00:00Z',
      });
      expect(device.platform, DevicePlatform.android);
      expect(device.isActive, isTrue);
      expect(device.displayName, 'NUSARTA (Android)');
    });

    test('revoked device is inactive', () {
      final device = Device.fromMap({
        'id': 'd2',
        'user_id': 'u1',
        'device_identifier': 'x',
        'platform': 'ios',
        'last_seen_at': '2026-09-08T08:00:00Z',
        'revoked_at': '2026-09-08T09:00:00Z',
        'created_at': '2026-09-01T08:00:00Z',
      });
      expect(device.platform, DevicePlatform.ios);
      expect(device.isActive, isFalse);
      expect(DevicePlatform.fromDb('web'), DevicePlatform.web);
      expect(DevicePlatform.fromDb('unknown'), DevicePlatform.other);
    });
  });

  group('AppNotification', () {
    test('parses row and type mapping', () {
      final n = AppNotification.fromMap({
        'id': 'n1',
        'user_id': 'u1',
        'type': 'budget',
        'title': 'Budget hampir tercapai',
        'body': 'Pengeluaran makanan mencapai 90%.',
        'data': {'amount': 45000},
        'is_read': false,
        'created_at': '2026-09-08T08:00:00Z',
      });
      expect(n.type, AppNotificationType.budget);
      expect(n.title, 'Budget hampir tercapai');
      expect(n.isRead, isFalse);
      expect(n.type.isV1Supported, isTrue);
    });

    test('reserved types are not V1-supported and map db values', () {
      expect(
          AppNotificationType.accountConnection.dbValue, 'account_connection');
      expect(
          AppNotificationType.fromDb('transfer'), AppNotificationType.transfer);
      expect(AppNotificationType.transfer.isV1Supported, isFalse);
      expect(AppNotificationType.security.isV1Supported, isTrue);
      expect(AppNotificationType.fromDb('unknown'), AppNotificationType.system);
    });
  });

  group('Transaction', () {
    test('parses manual source', () {
      final t = Transaction.fromMap({
        'id': 't1',
        'user_id': 'u1',
        'account_id': 'a1',
        'kind': 'income',
        'source': 'manual',
        'amount': 50000,
        'occurred_at': '2026-09-06T10:00:00Z',
      });
      expect(t.kind, TransactionKind.income);
      expect(t.source, TransactionSource.manual);
      expect(t.amount, 50000);
    });

    test('isManual true for manual source', () {
      final manual = Transaction(
        id: 'x',
        userId: 'u',
        accountId: 'a',
        kind: TransactionKind.expense,
        amount: 100,
        occurredAt: DateTime(2026, 9, 6),
      );
      expect(manual.source.isManual, isTrue);
    });
  });
}
