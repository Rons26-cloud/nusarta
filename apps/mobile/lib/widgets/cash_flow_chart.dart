import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../data/models/transaction.dart';
import 'finance_transaction_entry.dart';

class CashFlowBucket {
  CashFlowBucket(this.date);
  final DateTime date;
  double income = 0, expense = 0;
  int count = 0;
  DateTime? singleTimestamp;
}

List<CashFlowBucket> cashFlowBuckets(
    List<Transaction> transactions, DateTime start, DateTime end,
    {required bool yearly}) {
  final count = yearly
      ? 12
      : DateTime.utc(end.year, end.month, end.day)
          .difference(DateTime.utc(start.year, start.month, start.day))
          .inDays;
  final buckets = List.generate(
      count.clamp(1, 366),
      (i) => CashFlowBucket(yearly
          ? DateTime(start.year, i + 1)
          : DateTime(start.year, start.month, start.day + i)));
  for (final t in transactions) {
    final date = t.occurredAt.toLocal();
    if (date.isBefore(start) ||
        !date.isBefore(end) ||
        t.kind == TransactionKind.transfer) {
      continue;
    }
    final index = yearly
        ? date.month - 1
        : DateTime.utc(date.year, date.month, date.day)
            .difference(DateTime.utc(start.year, start.month, start.day))
            .inDays;
    if (index < 0 || index >= buckets.length) continue;
    final bucket = buckets[index];
    if (t.kind == TransactionKind.income) {
      bucket.income += t.amount;
    } else {
      bucket.expense += t.amount;
    }
    bucket.count++;
    bucket.singleTimestamp = bucket.count == 1 ? date : null;
  }
  return buckets;
}

class CashFlowChart extends StatefulWidget {
  const CashFlowChart(
      {super.key,
      required this.transactions,
      required this.start,
      required this.end,
      this.hidden = false,
      this.yearly = false});
  final List<Transaction> transactions;
  final DateTime start, end;
  final bool hidden, yearly;

  @override
  State<CashFlowChart> createState() => _CashFlowChartState();
}

class _CashFlowChartState extends State<CashFlowChart> {
  late List<CashFlowBucket> _buckets;
  int? _selected;
  @override
  void initState() {
    super.initState();
    _aggregate();
  }

  @override
  void didUpdateWidget(CashFlowChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.transactions, widget.transactions) ||
        oldWidget.start != widget.start ||
        oldWidget.end != widget.end ||
        oldWidget.yearly != widget.yearly) {
      _aggregate();
    }
  }

  void _aggregate() {
    _buckets = cashFlowBuckets(widget.transactions, widget.start, widget.end,
        yearly: widget.yearly);
    _selected = null;
  }

  String _detailMoney(double value) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
          .format(value);
  String _money(double value) => NumberFormat.compactCurrency(
          locale: 'id_ID', symbol: 'Rp', decimalDigits: 1)
      .format(value);

  @override
  Widget build(BuildContext context) {
    final hasData = _buckets.any((b) => b.count > 0);
    final maxValue = _buckets.fold<double>(
        0, (v, b) => math.max(v, math.max(b.income, b.expense)));
    final maxY = maxValue == 0 ? 1.0 : maxValue * 1.2;
    final selected = _selected == null ? null : _buckets[_selected!];
    LineChartBarData series(bool income) => LineChartBarData(
          spots: [
            for (var i = 0; i < _buckets.length; i++)
              FlSpot(i.toDouble(),
                  income ? _buckets[i].income : _buckets[i].expense)
          ],
          color: income ? AppColors.income : AppColors.expense,
          barWidth: 2.5,
          isCurved: false,
          dotData: FlDotData(show: widget.yearly),
          belowBarData: BarAreaData(
              show: true,
              color: (income ? AppColors.income : AppColors.expense)
                  .withAlpha(12)),
        );
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Grafik arus kas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 16, runSpacing: 6, children: [
          Text('● Pemasukan',
              style: TextStyle(color: AppColors.income, fontSize: 12)),
          Text('● Pengeluaran',
              style: TextStyle(color: AppColors.expense, fontSize: 12)),
        ]),
        const SizedBox(height: 20),
        if (widget.hidden)
          const Text('Ringkasan disembunyikan.')
        else if (!hasData)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Belum ada arus kas pada periode ini.'))
        else ...[
          LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                    key: const ValueKey('cashflow-plot'),
                    behavior: HitTestBehavior.opaque,
                    // Tap only: vertical drags belong to the page scroll view.
                    onTapUp: (details) {
                      final plotWidth =
                          math.max(1.0, constraints.maxWidth - 62);
                      final fraction =
                          ((details.localPosition.dx - 54) / plotWidth)
                              .clamp(0.0, 1.0);
                      setState(() => _selected =
                          (fraction * (_buckets.length - 1)).round());
                    },
                    child: Semantics(
                        label:
                            'Grafik garis pemasukan dan pengeluaran. Ketuk untuk rincian.',
                        child: IgnorePointer(
                            child: SizedBox(
                          height: 220,
                          child: LineChart(
                              LineChartData(
                                minX: 0,
                                maxX: (_buckets.length - 1)
                                    .toDouble()
                                    .clamp(1, 366),
                                minY: 0,
                                maxY: maxY,
                                lineTouchData:
                                    const LineTouchData(enabled: false),
                                clipData: const FlClipData.all(),
                                gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: maxY / 4,
                                    getDrawingHorizontalLine: (_) => FlLine(
                                        color: Theme.of(context).dividerColor,
                                        strokeWidth: .6)),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 54,
                                          interval: maxY / 4,
                                          getTitlesWidget: (v, _) => Text(
                                              _money(v),
                                              style: const TextStyle(
                                                  fontSize: 9)))),
                                  bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 28,
                                          interval: 1,
                                          getTitlesWidget: (v, meta) {
                                            final i = v.round();
                                            if (i < 0 || i >= _buckets.length) {
                                              return const SizedBox.shrink();
                                            }
                                            final stride =
                                                widget.yearly ? 2 : 7;
                                            if (i % stride != 0 &&
                                                i != _buckets.length - 1) {
                                              return const SizedBox.shrink();
                                            }
                                            if (i != _buckets.length - 1 &&
                                                _buckets.length - 1 - i <
                                                    stride / 2) {
                                              return const SizedBox.shrink();
                                            }
                                            return SideTitleWidget(
                                                axisSide: meta.axisSide,
                                                child: Text(
                                                    DateFormat(
                                                            widget.yearly
                                                                ? 'MMM'
                                                                : 'd',
                                                            'id_ID')
                                                        .format(
                                                            _buckets[i].date),
                                                    style: const TextStyle(
                                                        fontSize: 10)));
                                          })),
                                ),
                                extraLinesData: ExtraLinesData(verticalLines: [
                                  if (_selected != null)
                                    VerticalLine(
                                        x: _selected!.toDouble(),
                                        color: AppColors.gold,
                                        strokeWidth: 1.5,
                                        dashArray: [4, 4]),
                                ]),
                                lineBarsData: [series(true), series(false)],
                              ),
                              duration: Duration.zero),
                        ))),
                  )),
          const SizedBox(height: 8),
          Text(
              widget.yearly
                  ? 'Jan–Des • ketuk grafik untuk detail'
                  : 'Harian • ketuk grafik untuk detail',
              style: Theme.of(context).textTheme.bodySmall),
          if (selected != null) ...[
            const Divider(height: 24),
            Text(
                selected.singleTimestamp != null
                    ? localTransactionDateTime(selected.singleTimestamp!)
                    : DateFormat(widget.yearly ? 'MMMM yyyy' : 'd MMMM yyyy',
                            'id_ID')
                        .format(selected.date),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${selected.count} transaksi'),
            Text('Pemasukan: ${_detailMoney(selected.income)}'),
            Text('Pengeluaran: ${_detailMoney(selected.expense)}'),
            Text('Net: ${_detailMoney(selected.income - selected.expense)}'),
          ],
        ],
      ]),
    ));
  }
}
