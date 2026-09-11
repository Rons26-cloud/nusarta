import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/labels.dart';
import '../data/models/transaction.dart';
import 'amount_text.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.categoryName,
    this.accountName,
    this.onTap,
  });

  final Transaction transaction;
  final String? categoryName;
  final String? accountName;
  final VoidCallback? onTap;

  IconData get _icon => switch (transaction.kind) {
        TransactionKind.income => Icons.south_west,
        TransactionKind.expense => Icons.north_east,
        TransactionKind.transfer => Icons.swap_horiz,
      };

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.kind == TransactionKind.income;
    final isTransfer = transaction.kind == TransactionKind.transfer;

    final time = DateFormat.Hm('id_ID').format(transaction.occurredAt);
    final title = transaction.note?.isNotEmpty == true
        ? transaction.note!
        : (categoryName ?? transactionKindLabel(transaction.kind));

    final subtitleParts = <String>[
      if (accountName != null) accountName!,
      if (transaction.note?.isNotEmpty == true && categoryName != null)
        categoryName!,
      time,
    ];

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isIncome
            ? AppColors.income.withAlpha(31)
            : isTransfer
                ? AppColors.accent.withAlpha(38)
                : AppColors.expense.withAlpha(31),
        child: Icon(_icon,
            color: isIncome
                ? AppColors.income
                : isTransfer
                    ? AppColors.accent
                    : AppColors.expense),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(subtitleParts.join(' · ')),
        const SizedBox(height: 4),
        FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: isTransfer
                ? AmountText(
                    transaction.amount,
                    showSign: false,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: AppColors.accent),
                  )
                : AmountText(
                    transaction.amount,
                    isIncome: isIncome,
                    showSign: true,
                    style: Theme.of(context).textTheme.titleSmall,
                  )),
      ]),
    );
  }
}
