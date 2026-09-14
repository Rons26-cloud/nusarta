import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/transfer_record.dart';
import '../../widgets/institution_logo.dart';
import '../connections/financial_provider_adapter.dart';

/// NUSARTA receipt sheet. Reusable for a verified [TransferRecord] — success,
/// pending, failed, cancelled, etc. Success visuals only appear for a
/// provider-confirmed SUCCESS (see [TransferRecord.isSuccess]).
class ReceiptDetailPage extends StatelessWidget {
  const ReceiptDetailPage({
    super.key,
    required this.record,
    this.onBack,
    this.onShare,
  });

  final TransferRecord record;
  final VoidCallback? onBack;
  final Future<void> Function(String text)? onShare;

  static final _currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  static final _date = DateFormat('EEE, d MMM yyyy • HH:mm', 'id_ID');

  String get _summaryText {
    final b = StringBuffer('NUSARTA — Keuanganmu, Dalam Kendalimu.\n');
    if (record.isSimulation) {
      b.writeln('SANDBOX · Simulasi, tidak ada uang nyata berpindah.');
    }
    b.writeln(TransferStatusLabels.title(record.status));
    b.writeln('Sumber: ${record.sourceAccountName} ${record.sourceMasked}');
    b.writeln('Tujuan: ${record.recipientInstitutionName} '
        '${record.recipientMasked}');
    if (record.recipientName != null) {
      b.writeln('Penerima: ${record.recipientName}');
    }
    b.writeln('Nominal: ${_currency.format(record.amount)}');
    b.writeln('Biaya Admin: ${_currency.format(record.fee)}');
    b.writeln('Total: ${_currency.format(record.total)}');
    b.writeln('Status: ${TransferStatusLabels.title(record.status)}');
    b.writeln('Referensi: ${record.reference}');
    return b.toString();
  }

  Future<void> _share(BuildContext context) async {
    final action = onShare;
    if (action != null) {
      await action(_summaryText);
      return;
    }
    await Clipboard.setData(ClipboardData(text: _summaryText));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ringkasan struk disalin ke klipbor.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = record.status;
    final success = record.isSuccess;
    final icon = switch (status) {
      TransferStepStatus.reversed => Icons.undo_rounded,
      TransferStepStatus.success => Icons.check_circle_rounded,
      TransferStepStatus.processing ||
      TransferStepStatus.authorized =>
        Icons.hourglass_top_rounded,
      TransferStepStatus.cancelled => Icons.cancel_outlined,
      TransferStepStatus.expired => Icons.timer_off_outlined,
      _ => Icons.error_outline_rounded,
    };
    final bannerColor = success
        ? AppColors.primary
        : status == TransferStepStatus.processing ||
                status == TransferStepStatus.authorized
            ? AppColors.gold
            : AppColors.expense;

    return Scaffold(
      backgroundColor: AppColors.backgroundOff,
      appBar: AppBar(title: const Text('Struk NUSARTA')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [AppColors.deepEmerald, AppColors.primaryDark]),
                  ),
                  child: CustomPaint(
                    painter: _ReceiptOrnament(),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Image.asset('assets/brand/logo.png',
                              height: 44, fit: BoxFit.contain),
                          const SizedBox(height: 6),
                          const Text('Keuanganmu, Dalam Kendalimu.',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 20),
                          Icon(icon, size: 54, color: AppColors.goldLight),
                          const SizedBox(height: 12),
                          Text(TransferStatusLabels.title(record.status),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 19)),
                          const SizedBox(height: 6),
                          Text(
                              record.isSimulation
                                  ? 'SANDBOX · Simulasi, tidak ada uang nyata berpindah.'
                                  : TransferStatusLabels.subtitle(status),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DetailRowGroup(
                        label: 'Sumber',
                        child: Row(children: [
                          InstitutionLogo(
                              code: record.recipientInstitutionCode,
                              name: record.sourceInstitutionName,
                              size: 34),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(record.sourceAccountName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                Text(record.sourceMasked,
                                    style: TextStyle(
                                        color: AppColors.neutral,
                                        fontSize: 12.5)),
                              ])),
                        ])),
                    const Divider(height: 22),
                    _DetailRow(
                        label: 'Tujuan',
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${record.recipientInstitutionName} '
                                  '${record.recipientMasked}'),
                            ])),
                    if (record.recipientName != null) ...[
                      const Divider(height: 22),
                      _DetailRow(
                          label: 'Nama Penerima',
                          child: Text(record.recipientName!)),
                    ],
                    const Divider(height: 22),
                    _DetailRow(
                        label: 'Nominal',
                        child: Text(_currency.format(record.amount))),
                    const Divider(height: 22),
                    _DetailRow(
                        label: 'Biaya Admin',
                        child: Text(_currency.format(record.fee))),
                    const Divider(height: 22),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          Text(_currency.format(record.total),
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: AppColors.heading)),
                        ]),
                    const Divider(height: 22),
                    _DetailRow(
                        label: 'Tanggal & Waktu',
                        child: Text(_date.format(record.occurredAt))),
                    const Divider(height: 22),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Status',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: bannerColor.withAlpha(24),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                                TransferStatusLabels.title(record.status),
                                style: TextStyle(
                                    color: bannerColor,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ]),
                    const Divider(height: 22),
                    _DetailRow(
                        label: 'Referensi',
                        child: Text(record.reference,
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 12.5))),
                    if (record.message != null) ...[
                      const Divider(height: 22),
                      Text(record.message!,
                          style: TextStyle(
                              color: AppColors.expense, fontSize: 12.5)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Transaksi diproses melalui penyedia jasa resmi. NUSARTA tidak '
              'menyimpan dana, PIN, kata sandi, atau kode OTP Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.neutral, fontSize: 11.5),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _share(context),
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Bagikan Struk'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onBack ?? () => Navigator.pop(context),
              child: const Text('Kembali ke Beranda'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRowGroup extends StatelessWidget {
  const _DetailRowGroup({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.neutral,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          child,
        ],
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 150,
              child: Text(
                label,
                style: TextStyle(color: AppColors.neutral, fontSize: 13.5),
              )),
          Expanded(child: child),
        ],
      );
}

class _ReceiptOrnament extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..color = AppColors.gold.withAlpha(110)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final path = Path()
      ..moveTo(size.width * .45, size.height)
      ..quadraticBezierTo(size.width * .62, size.height * .55, size.width * 1.1,
          size.height * .3);
    canvas.drawPath(path, gold);
    final fine = Paint()
      ..color = Colors.white.withAlpha(20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(
          Rect.fromLTWH(size.width * .3 - i * 16, size.height * .08 + i * 12,
              size.width * .9 + i * 16, size.height * 1.3),
          3.6,
          1.2,
          false,
          fine);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
