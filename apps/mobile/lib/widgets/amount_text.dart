import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';

/// Formats an amount as IDR and colors it by sign.
class AmountText extends StatelessWidget {
  const AmountText(
    this.amount, {
    super.key,
    this.showSign = false,
    this.isIncome,
    this.style,
  });

  final double amount;
  final bool showSign;
  final bool? isIncome;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyLarge!;
    final color = isIncome == null
        ? null
        : (isIncome! ? AppColors.income : AppColors.expense);

    final prefix =
        showSign ? (isIncome == false || amount < 0 ? '-' : '+') : '';
    final formatted = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(amount.abs());

    return Text(
      '$prefix$formatted',
      style: color == null ? base : base.copyWith(color: color),
    );
  }
}
