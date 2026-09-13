import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Prank page: the "Claim Saldo Gratis" tile was left unfinished in the
/// original design brief. NUSARTA does not hand out free balances — this
/// page is deliberately a joke that also teaches users to recognize
/// giveaway/claim scams. It never touches balances, transactions, or APIs.
class ClaimFreeBalancePage extends StatefulWidget {
  const ClaimFreeBalancePage({super.key});

  @override
  State<ClaimFreeBalancePage> createState() => _ClaimFreeBalancePageState();
}

class _ClaimFreeBalancePageState extends State<ClaimFreeBalancePage> {
  bool _revealed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _revealed = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOff,
      appBar: AppBar(title: const Text('Saldo Gratis')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(
                      'assets/brand/fack.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(Icons.savings_outlined,
                          size: 140, color: AppColors.brandEmerald),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey(_revealed),
                      children: [
                        Text(
                          _revealed
                              ? 'Mana ada saldo gratis, tolol.'
                              : 'Saldo gratis untukmu!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _revealed
                              ? 'Klaim gacha GGL/Salim itu scam. Balik kerja.'
                              : 'Mengecek kelayakan akun (pura-pura)…',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.neutral),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_revealed)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(12),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: AppColors.primary.withAlpha(40)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              color: AppColors.brandEmerald),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'NUSARTA tidak pernah membagikan saldo gratis. '
                              'Jangan pernah membagikan PIN, OTP, atau kode '
                              'keamanan ke siapa pun.',
                              style: TextStyle(fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Kembali ke NUSARTA'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
