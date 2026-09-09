import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';

/// Presentation only: values come from the existing providers.
class MoneyValue extends StatelessWidget {
  const MoneyValue(this.amount, {super.key, this.style, this.hidden = false});
  final double amount;
  final TextStyle? style;
  final bool hidden;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
            hidden
                ? 'Rp ••••••••'
                : NumberFormat.currency(
                        locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
                    .format(amount),
            maxLines: 1,
            style: style ?? Theme.of(context).textTheme.titleLarge),
      );
}

class FinanceSummary extends StatelessWidget {
  const FinanceSummary(
      {super.key,
      required this.title,
      required this.amount,
      required this.details});
  final String title;
  final double amount;
  final List<(String, double)> details;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.deepEmerald, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withAlpha(70)),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.goldLight, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          MoneyValue(amount,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800)),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Colors.white24)),
          Wrap(spacing: 24, runSpacing: 12, children: [
            for (final detail in details)
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(detail.$1,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                    NumberFormat.compactCurrency(
                            locale: 'id_ID', symbol: 'Rp', decimalDigits: 1)
                        .format(detail.$2),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ]),
          ]),
        ]),
      );
}
