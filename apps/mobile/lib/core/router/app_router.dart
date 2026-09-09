import 'package:go_router/go_router.dart';

import '../../core/data/supabase_client.dart';
import '../../core/security/auto_lock_service.dart';
import '../../core/security/pin_service.dart';
import '../../features/accounts/accounts_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/budgets/budgets_page.dart';
import '../../features/dashboard/app_shell.dart';
import '../../features/goals/goals_page.dart';
import '../../features/lock/pin_setup_page.dart';
import '../../features/lock/pin_unlock_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/profile/delete_account_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/reports/reports_page.dart';
import '../../features/search/search_page.dart';
import '../../features/security/devices_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/splash/splash_page.dart';
import '../../features/transactions/transactions_page.dart';
import '../../features/transfers/transfer_page.dart';
import '../../features/welcome/welcome_page.dart';

/// Route gates: session, PIN setup, lock, then app.
final router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) async {
    // Branding only; the next route still passes every security gate below.
    if (state.matchedLocation == '/splash') return null;
    final loggedIn = SupabaseConfig.client.auth.currentUser != null;
    final location = state.matchedLocation;

    final hasPin = await PinService.isSet;

    // Signed out.
    if (!loggedIn) {
      if (location == '/login' || location == '/register') return null;
      return '/welcome';
    }

    // Signed in.
    if (location == '/login' ||
        location == '/register' ||
        location == '/welcome') {
      return hasPin ? '/' : '/pin-setup';
    }

    // PIN setup.
    if (!hasPin) {
      if (location == '/pin-setup') return null;
      return '/pin-setup';
    }

    // Auto-lock.
    if (location != '/lock') {
      final shouldLock = await AutoLockService.shouldLock();
      if (shouldLock) return '/lock';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/welcome', builder: (_, __) => const WelcomePage()),
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
    GoRoute(path: '/pin-setup', builder: (_, __) => const PinSetupPage()),
    GoRoute(path: '/lock', builder: (_, __) => const PinUnlockPage()),
    GoRoute(path: '/', builder: (_, __) => const AppShell()),
    GoRoute(
        path: '/transactions', builder: (_, __) => const TransactionsPage()),
    GoRoute(path: '/accounts', builder: (_, __) => const AccountsPage()),
    GoRoute(path: '/reports', builder: (_, __) => const ReportsPage()),
    GoRoute(path: '/budgets', builder: (_, __) => const BudgetsPage()),
    GoRoute(path: '/goals', builder: (_, __) => const GoalsPage()),
    GoRoute(path: '/search', builder: (_, __) => const SearchPage()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
    GoRoute(path: '/settings', builder: (_, state) => SettingsPage(section: state.uri.queryParameters['section'])),
    GoRoute(path: '/devices', builder: (_, __) => const DevicesPage()),
    GoRoute(
        path: '/notifications', builder: (_, __) => const NotificationsPage()),
    GoRoute(path: '/transfer', builder: (_, __) => const TransferPage()),
    GoRoute(
        path: '/delete-account', builder: (_, __) => const DeleteAccountPage()),
  ],
);
