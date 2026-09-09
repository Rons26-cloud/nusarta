import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
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
    );
  }
}
