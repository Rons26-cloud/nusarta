import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/feature_flags.dart';
import '../core/security/secure_store.dart';
import '../data/models/account.dart';
import '../data/models/category.dart';
import '../data/models/device.dart';
import '../data/models/finance.dart';
import '../data/models/institution.dart';
import '../data/models/notification.dart';
import '../data/models/security_event.dart';
import '../data/models/transaction.dart';
import '../data/repositories/account_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/device_repository.dart';
import '../data/repositories/finance_repository.dart';
import '../data/repositories/institution_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/security_repository.dart';
import '../data/repositories/transaction_repository.dart';
import 'auth_provider.dart';

// Account providers
final accountsProvider = FutureProvider<List<Account>>(
  (ref) {
    ref.watch(currentUserProvider.select((user) => user?.id));
    return AccountRepository.listAll();
  },
);

final accountsControllerProvider = Provider<AccountsController>((ref) {
  return AccountsController(ref);
});

class AccountsController {
  AccountsController(this._ref);
  final Ref _ref;

  Future<Account> create(
      {required String name,
      required AccountType type,
      double balance = 0}) async {
    final account = await AccountRepository.createSimple(
        name: name, type: type, balance: balance);
    _ref.invalidate(accountsProvider);
    return account;
  }

  Future<Account> createAccount({
    required String name,
    required AccountType type,
    double balance = 0,
    String? institutionId,
    String? lastFour,
    String? maskedAccountNumber,
    String? displayName,
    bool isPrimary = false,
  }) async {
    final account = await AccountRepository.createAccount(
      name: name,
      type: type,
      balance: balance,
      institutionId: institutionId,
      lastFour: lastFour,
      maskedAccountNumber: maskedAccountNumber,
      displayName: displayName,
      isPrimary: isPrimary,
    );
    _ref.invalidate(accountsProvider);
    return account;
  }

  Future<void> setPrimary(String id, {required bool isPrimary}) async {
    await AccountRepository.setPrimary(id, isPrimary: isPrimary);
    _ref.invalidate(accountsProvider);
  }

  Future<void> update(Account account) async {
    await AccountRepository.update(account);
    _ref.invalidate(accountsProvider);
  }

  Future<void> delete(String id) async {
    await AccountRepository.delete(id);
    _ref.invalidate(accountsProvider);
  }

  Future<void> archive(String id, bool archived) async {
    await AccountRepository.archive(id, archived);
    _ref.invalidate(accountsProvider);
  }
}

// Transaction providers
final transactionsProvider = FutureProvider<List<Transaction>>(
  (ref) {
    ref.watch(currentUserProvider.select((user) => user?.id));
    return TransactionRepository.list();
  },
);

final transactionsControllerProvider = Provider<TransactionsController>((ref) {
  return TransactionsController(ref);
});

class TransactionsController {
  TransactionsController(this._ref);
  final Ref _ref;

  Future<void> addIncomeExpense(Transaction t) async {
    await TransactionRepository.create(t);
    _ref.invalidate(transactionsProvider);
    _ref.invalidate(accountsProvider);
  }

  Future<void> update(Transaction t) async {
    await TransactionRepository.update(t);
    _ref.invalidate(transactionsProvider);
    _ref.invalidate(accountsProvider);
  }

  Future<void> delete(String id) async {
    await TransactionRepository.delete(id);
    _ref.invalidate(transactionsProvider);
    _ref.invalidate(accountsProvider);
  }

  Future<void> transfer(InternalTransfer transfer) async {
    await TransactionRepository.createTransfer(transfer);
    _ref.invalidate(transactionsProvider);
    _ref.invalidate(accountsProvider);
  }
}

// Category providers
final categoriesProvider =
    FutureProvider.family<List<Category>, TransactionKind?>(
  (ref, kind) {
    ref.watch(currentUserProvider.select((user) => user?.id));
    return CategoryRepository.list(kind: kind);
  },
);

final allCategoriesProvider = FutureProvider<List<Category>>((ref) {
  ref.watch(currentUserProvider.select((user) => user?.id));
  return CategoryRepository.list();
});

// Budget & goal providers
final budgetsProvider = FutureProvider<List<Budget>>((ref) {
  ref.watch(currentUserProvider.select((user) => user?.id));
  return BudgetRepository.listAll();
});

final budgetsControllerProvider = Provider<BudgetsController>((ref) {
  return BudgetsController(ref);
});

class BudgetsController {
  BudgetsController(this._ref);
  final Ref _ref;

  Future<void> create(Budget budget) async {
    await BudgetRepository.create(budget);
    _ref.invalidate(budgetsProvider);
  }

  Future<void> delete(String id) async {
    await BudgetRepository.delete(id);
    _ref.invalidate(budgetsProvider);
  }
}

final goalsProvider = FutureProvider<List<FinancialGoal>>((ref) {
  ref.watch(currentUserProvider.select((user) => user?.id));
  return GoalRepository.listActive();
});

final goalsControllerProvider = Provider<GoalsController>((ref) {
  return GoalsController(ref);
});

class GoalsController {
  GoalsController(this._ref);
  final Ref _ref;

  Future<void> create(FinancialGoal goal) async {
    await GoalRepository.create(goal);
    _ref.invalidate(goalsProvider);
  }

  Future<void> update(FinancialGoal goal) async {
    await GoalRepository.update(goal);
    _ref.invalidate(goalsProvider);
  }

  Future<void> delete(String id) async {
    await GoalRepository.delete(id);
    _ref.invalidate(goalsProvider);
  }
}

// Feature flags: gate future capabilities. V1 defaults are all OFF except
// the informational institution catalog.
final featureFlagProvider =
    Provider<FeatureFlags>((ref) => FeatureFlags.instance);

// Institution catalog (informational metadata only in V1).
final institutionsProvider = FutureProvider<List<Institution>>((ref) async {
  if (!FeatureFlags.isEnabled(FeatureFlag.institutionCatalog)) return const [];
  return InstitutionRepository.listActive();
});

final devicesProvider = FutureProvider<List<Device>>(
  (ref) {
    ref.watch(currentUserProvider.select((user) => user?.id));
    return DeviceRepository.listMine();
  },
);

final currentDeviceIdProvider = FutureProvider<String>(
  (ref) => AppSecureStore.getOrCreateDeviceId(),
);

final notificationsProvider = FutureProvider<List<AppNotification>>(
  (ref) {
    ref.watch(currentUserProvider.select((user) => user?.id));
    return NotificationRepository.listMine();
  },
);

final notificationsControllerProvider = Provider<NotificationsController>(
  (ref) => NotificationsController(ref),
);

class NotificationsController {
  NotificationsController(this._ref);
  final Ref _ref;

  Future<void> markRead(String id) async {
    await NotificationRepository.markRead(id);
    _ref.invalidate(notificationsProvider);
  }

  Future<void> markAllRead() async {
    await NotificationRepository.markAllRead();
    _ref.invalidate(notificationsProvider);
  }
}

final securityEventsProvider = FutureProvider<List<SecurityEvent>>(
  (ref) {
    ref.watch(currentUserProvider.select((user) => user?.id));
    return SecurityRepository.listMine();
  },
);
