import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/device_repository.dart';
import '../../features/accounts/accounts_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/reports/reports_page.dart';
import '../../features/transactions/transactions_page.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ShellScaffold();
  }
}

class _ShellScaffold extends StatefulWidget {
  const _ShellScaffold();

  @override
  State<_ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<_ShellScaffold> {
  int _index = 0;
  final _visited = <int>{0};

  static const _pages = [
    DashboardPage(),
    TransactionsPage(),
    AccountsPage(),
    ReportsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeviceRepository.ensureRegistered();
    });
  }

  void _onDestinationSelected(int index) {
    if (_index == index) return;
    setState(() {
      _visited.add(index);
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final systemUi = SystemUiOverlayStyle(
      statusBarColor: AppColors.deepEmerald,
      systemNavigationBarColor: Theme.of(context).colorScheme.surface,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness:
          Theme.of(context).brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUi,
      child: Scaffold(
        extendBody: false,
        body: IndexedStack(
          index: _index,
          children: [
            // Lazy keep-alive: a tab is built only on its first visit, then
            // kept alive so scroll position and state survive tab switches.
            for (var i = 0; i < _pages.length; i++)
              _visited.contains(i)
                  ? TickerMode(
                      enabled: i == _index,
                      child: RepaintBoundary(child: _pages[i]))
                  : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onDestinationSelected,
          backgroundColor: Theme.of(context).colorScheme.surface,
          indicatorColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          animationDuration: const Duration(milliseconds: 160),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Beranda'),
            NavigationDestination(
                icon: Icon(Icons.swap_vert),
                selectedIcon: Icon(Icons.swap_vert),
                label: 'Transaksi'),
            NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: 'Akun'),
            NavigationDestination(
                icon: Icon(Icons.pie_chart_outline),
                selectedIcon: Icon(Icons.pie_chart),
                label: 'Laporan'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Lainnya'),
          ],
        ),
      ),
    );
  }
}
