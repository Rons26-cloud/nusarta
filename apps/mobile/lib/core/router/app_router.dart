import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/data/supabase_client.dart';
import '../../core/security/auto_lock_service.dart';
import '../../core/security/pin_service.dart';
import '../../core/startup/startup_gate.dart';
import '../../features/about/about_nusarta_page.dart';
import '../../features/accounts/account_detail_page.dart';
import '../../features/accounts/accounts_page.dart';
import '../../features/auth/email_verification_success_page.dart';
import '../../features/auth/forgot_password_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/otp_verification_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/auth/reset_password_page.dart';
import '../../features/budgets/budgets_page.dart';
import '../../features/connections/link_accounts_page.dart';
import '../../features/dashboard/app_shell.dart';

import '../../features/goals/goals_page.dart';
import '../../features/help/help_center_page.dart';
import '../../features/legal/privacy_page.dart';
import '../../features/legal/terms_page.dart';
import '../../features/lock/pin_setup_page.dart';
import '../../features/lock/pin_unlock_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/onboarding/link_account_tutorial_page.dart';
import '../../features/onboarding/onboarding_tutorial_page.dart';
import '../../features/profile/delete_account_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/reports/reports_page.dart';
import '../../features/search/search_page.dart';
import '../../features/security/devices_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/splash/splash_page.dart';
import '../../features/startup/startup_error_page.dart';
import '../../features/transactions/transactions_page.dart';
import '../../features/transfers/transfer_page.dart';
import '../../features/version/version_page.dart';
import '../../features/welcome/welcome_page.dart';
import '../../providers/auth_provider.dart';
import '../../providers/password_recovery_provider.dart';

/// Route gates: session, PIN setup, lock, then app.
final router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) async {
    // Branding only; the next route still passes every security gate below.
    if (state.matchedLocation == '/splash' ||
        state.matchedLocation == '/startup-error') {
      return null;
    }
    final loggedIn = SupabaseConfig.isInitialized &&
        SupabaseConfig.client.auth.currentSession != null;
    final recoveryLocation = state.matchedLocation;
    if (PasswordRecoveryController.active) {
      return recoveryLocation == '/reset-password' ? null : '/reset-password';
    }
    if (recoveryLocation == '/reset-password') return '/forgot-password';
    if (!loggedIn &&
        (recoveryLocation == '/forgot-password' ||
            recoveryLocation == '/recovery-otp')) {
      return null;
    }
    if (!AppConfig.isConfigured || !SupabaseConfig.isInitialized) {
      // A clean install is allowed to reach onboarding even when the optional
      // backend configuration is absent. Login and sync surface their own
      // actionable errors when the public client is unavailable.
      if (!loggedIn &&
          (state.matchedLocation == '/welcome' ||
              state.matchedLocation == '/login' ||
              state.matchedLocation == '/register' ||
              state.matchedLocation == '/otp' ||
              state.matchedLocation == '/email-verification-success')) {
        return null;
      }
      return '/login';
    }
    final location = state.matchedLocation;

    // Verification success is an intermediate screen before the existing PIN gate.
    if (location == '/email-verification-success') return null;

    // Signed out.
    if (!loggedIn) {
      if (location == '/login' ||
          location == '/register' ||
          location == '/otp' ||
          location == '/email-verification-success') {
        return null;
      }
      return '/login';
    }

    final hasPin = await startupBool(PinService.isSet);
    if (hasPin == null) return '/startup-error';
    SupabaseConfig.log('PIN state complete');

    // Signed in.
    if (location == '/login' ||
        location == '/register' ||
        location == '/welcome') {
      if (!hasPin) return '/pin-setup';
      final locked = await startupBool(AutoLockService.shouldLock());
      if (locked == null) return '/startup-error';
      return locked ? '/lock' : '/';
    }

    // PIN setup.
    if (!hasPin) {
      if (location == '/pin-setup') return null;
      return '/pin-setup';
    }

    // Auto-lock.
    if (location != '/lock') {
      final shouldLock = await startupBool(AutoLockService.shouldLock());
      if (shouldLock == null) return '/startup-error';
      SupabaseConfig.log('lock state complete');
      if (shouldLock) return '/lock';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
    GoRoute(
      path: '/startup-error',
      builder: (_, __) => const StartupErrorPage(),
    ),
    GoRoute(path: '/welcome', builder: (_, __) => const WelcomePage()),
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
    GoRoute(
        path: '/forgot-password',
        builder: (_, state) => ForgotPasswordPage(
            email: state.extra is String ? state.extra! as String : '')),
    GoRoute(
        path: '/recovery-otp',
        builder: (_, state) {
          final email = state.extra is String ? state.extra! as String : '';
          if (email.isEmpty) return const ForgotPasswordPage();
          return Consumer(builder: (context, ref, _) {
            final recovery = ref.read(passwordRecoveryProvider);
            return OtpVerificationPage(
              email: email,
              purpose: OtpPurpose.passwordRecovery,
              recoveryArtwork: true,
              verifyCode: (code) => recovery.verify(email, code),
              resendCode: () => recovery.request(email),
              onVerified: () => context.go('/reset-password'),
            );
          });
        }),
    GoRoute(
        path: '/reset-password', builder: (_, __) => const ResetPasswordPage()),
    GoRoute(
      path: '/otp',
      builder: (_, state) {
        final email = state.extra is String ? state.extra! as String : '';
        return OtpVerificationPage(email: email);
      },
    ),
    GoRoute(
      path: '/email-verification-success',
      builder: (_, __) => const EmailVerificationSuccessPage(),
    ),
    GoRoute(path: '/pin-setup', builder: (_, __) => const PinSetupPage()),
    GoRoute(path: '/lock', builder: (_, __) => const PinUnlockPage()),
    GoRoute(path: '/', builder: (_, __) => const AppShell()),
    GoRoute(
      path: '/transactions',
      builder: (_, __) => const TransactionsPage(),
    ),
    GoRoute(path: '/accounts', builder: (_, __) => const AccountsPage()),
    GoRoute(
      path: '/account-detail',
      builder: (_, state) => AccountDetailPage(
          accountId: state.uri.queryParameters['accountId'] ?? ''),
    ),
    GoRoute(path: '/reports', builder: (_, __) => const ReportsPage()),
    GoRoute(path: '/budgets', builder: (_, __) => const BudgetsPage()),
    GoRoute(path: '/goals', builder: (_, __) => const GoalsPage()),
    GoRoute(path: '/search', builder: (_, __) => const SearchPage()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
    GoRoute(
      path: '/profile/claim-free-balance',
      redirect: (_, __) => '/help',
    ),
    GoRoute(path: '/help', builder: (_, __) => const HelpCenterPage()),
    GoRoute(path: '/about', builder: (_, __) => const AboutNusartaPage()),
    GoRoute(path: '/privacy', builder: (_, __) => const PrivacyPage()),
    GoRoute(path: '/terms', builder: (_, __) => const TermsPage()),
    GoRoute(path: '/version', builder: (_, __) => const VersionPage()),
    GoRoute(
      path: '/settings',
      builder: (_, state) =>
          SettingsPage(section: state.uri.queryParameters['section']),
    ),
    GoRoute(path: '/devices', builder: (_, __) => const DevicesPage()),
    GoRoute(
      path: '/notifications',
      builder: (_, __) => const NotificationsPage(),
    ),
    GoRoute(path: '/transfer', builder: (_, __) => const TransferPage()),
    GoRoute(
      path: '/link-accounts',
      builder: (_, __) => const LinkAccountsPage(),
    ),
    GoRoute(
      path: '/tutorial',
      builder: (_, __) => const OnboardingTutorialPage(),
    ),
    GoRoute(
      path: '/tutorial/link-account',
      builder: (_, __) => const LinkAccountTutorialPage(),
    ),
    GoRoute(
      path: '/delete-account',
      builder: (_, __) => const DeleteAccountPage(),
    ),
  ],
);
