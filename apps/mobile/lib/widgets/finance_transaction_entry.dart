import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/labels.dart';
import '../data/models/transaction.dart';
import 'finance_summary.dart';

String localTransactionDateTime(DateTime timestamp, {bool full = false}) =>
    DateFormat(full ? 'd MMMM yyyy • HH:mm:ss' : 'd MMM yyyy • HH:mm', 'id_ID')
        .format(timestamp.toLocal());

String localUtcOffset(DateTime timestamp) {
  final offset = timestamp.toLocal().timeZoneOffset;
  final minutes = offset.inMinutes.abs();
  return 'UTC${offset.isNegative ? '-' : '+'}${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
}

class FinanceTransactionEntry extends StatelessWidget {
  const FinanceTransactionEntry(
      {super.key,
      required this.transaction,
      required this.categoryName,
      required this.accountName,
      this.hidden = false});
  final Transaction transaction;
  final String categoryName, accountName;
  final bool hidden;

  String get title => transaction.title?.trim().isNotEmpty == true
      ? transaction.title!
      : transaction.note?.trim().isNotEmpty == true
          ? transaction.note!
          : categoryName;

  @override
  Widget build(BuildContext context) {
    final income = transaction.kind == TransactionKind.income;
    final color = income
        ? AppColors.income
        : transaction.kind == TransactionKind.expense
            ? AppColors.expense
            : AppColors.primary;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: hidden
            ? null
            : () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => FractionallySizedBox(
                    heightFactor: .8,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              Expanded(
                                  child: Text('Detail Transaksi',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge)),
                              IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  tooltip: 'Tutup',
                                  icon: const Icon(Icons.close)),
                            ]),
                            MoneyValue(transaction.amount,
                                style: TextStyle(
                                    color: color,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 16),
                            for (final field in <(String, String)>[
                              ('Deskripsi', title),
                              ('Tipe', transactionKindLabel(transaction.kind)),
                              ('Kategori', categoryName),
                              ('Akun', accountName),
                              (
                                'Tanggal transaksi',
                                DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                                    .format(transaction.occurredAt.toLocal())
                              ),
                              (
                                'Jam transaksi',
                                '${DateFormat('HH:mm:ss', 'id_ID').format(transaction.occurredAt.toLocal())} ${localUtcOffset(transaction.occurredAt)}'
                              ),
                              (
                                'Catatan',
                                transaction.note?.trim().isNotEmpty == true
                                    ? transaction.note!
                                    : 'Tidak ada catatan'
                              ),
                              ('Status', transaction.status.name),
                              if (transaction.providerReference?.isNotEmpty ==
                                  true)
                                ('Referensi', transaction.providerReference!),
                              if (transaction.id.isNotEmpty)
                                ('ID transaksi', transaction.id),
                            ])
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(field.$1,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium),
                                      const SizedBox(height: 3),
                                      SelectableText(field.$2),
                                    ]),
                              ),
                          ]),
                    ),
                  ),
                ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
                backgroundColor: color.withAlpha(24),
                child: Icon(income ? Icons.south_west : Icons.north_east,
                    color: color)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('$categoryName • $accountName',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 5),
                  Text(localTransactionDateTime(transaction.occurredAt),
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Text(transactionKindLabel(transaction.kind),
                      style: TextStyle(color: color, fontSize: 12)),
                  MoneyValue(transaction.amount,
                      hidden: hidden,
                      style: TextStyle(
                          color: color,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                ])),
          ]),
        ),
      ),
    );
  }
}
