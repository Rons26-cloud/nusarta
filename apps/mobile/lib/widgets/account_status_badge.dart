import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/account_status.dart';
import '../data/models/account.dart';

class AccountStatusBadge extends StatelessWidget {
  const AccountStatusBadge({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final state = badgeStateFor(account);
    final (background, foreground) = _colorsFor(state);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        badgeLabelFor(state),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }

  (Color, Color) _colorsFor(AccountBadgeState state) => switch (state) {
        AccountBadgeState.manual => (
            const Color(0xFFE2E8E6),
            AppColors.neutral,
          ),
        AccountBadgeState.connected => (
            AppColors.income.withAlpha(31),
            AppColors.income,
          ),
        AccountBadgeState.pending => (
            AppColors.accentLight.withAlpha(64),
            AppColors.accent,
          ),
        AccountBadgeState.needsAttention => (
            AppColors.expense.withAlpha(26),
            AppColors.expense,
          ),
        AccountBadgeState.revoked => (
            const Color(0xFFE2E8E6),
            AppColors.neutral,
          ),
      };
}
