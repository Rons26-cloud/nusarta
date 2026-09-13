import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class OnboardingTutorialPage extends StatefulWidget {
  const OnboardingTutorialPage({super.key});

  @override
  State<OnboardingTutorialPage> createState() => _OnboardingTutorialPageState();
}

class _OnboardingTutorialPageState extends State<OnboardingTutorialPage> {
  final _controller = PageController();
  int _index = 0;

  static const _steps = <_TutorialStep>[
    _TutorialStep(
      title: 'Selamat Datang di NUSARTA',
      description: 'Keuanganmu dalam kendalimu. Catat, pantau, dan rencanakan '
          'semua dari satu aplikasi yang aman.',
      preview: _WelcomePreview(),
    ),
    _TutorialStep(
      title: 'Tambahkan Transaksi',
      description: 'Catat pemasukan dan pengeluaran dalam hitungan detik. '
          'Pilih akun, kategori, tanggal, dan catatan.',
      preview: _TransactionPreview(),
    ),
    _TutorialStep(
      title: 'Hubungkan Akun Finansial',
      description: 'Sinkronisasi akun bank dan e-wallet melalui provider '
          'resmi segera hadir di menu Akun.',
      preview: _LinkPreview(),
    ),
    _TutorialStep(
      title: 'Pantau Pengeluaran',
      description: 'Dashboard menampilkan saldo, alur kas, dan pengeluaran '
          'terbaru agar keuanganmu selalu terlihat.',
      preview: _DashboardPreview(),
    ),
    _TutorialStep(
      title: 'Buat Budget',
      description:
          'Tetapkan batas pengeluaran per kategori dan pantau seberapa '
          'dekat kamu melewati batas.',
      preview: _BudgetPreview(),
    ),
    _TutorialStep(
      title: 'Buat Tujuan',
      description: 'Rencanakan target finansial dengan nominal dan tenggat. '
          'Pantau progresnya setiap saat.',
      preview: _GoalPreview(),
    ),
    _TutorialStep(
      title: 'Gunakan Laporan',
      description: 'Lihat pemasukan, pengeluaran, dan ringkasan per periode '
          'dalam tampilan yang mudah dipahami.',
      preview: _ReportPreview(),
    ),
    _TutorialStep(
      title: 'Keamanan PIN & Biometrik',
      description: 'Lindungi NUSARTA dengan PIN 6 digit dan biometrik '
          'perangkat. Semua verifikasi berlangsung lokal.',
      preview: _SecurityPreview(),
    ),
    _TutorialStep(
      title: 'Transfer',
      description: 'Transfer ke bank/e-wallet akan aktif lewat provider '
          'resmi. Semua transaksi diverifikasi server-side.',
      preview: _TransferPreview(),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int target) {
    _controller.animateToPage(target.clamp(0, _steps.length - 1),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _steps.length - 1;
    return Scaffold(
      backgroundColor: AppColors.backgroundOff,
      appBar: AppBar(
        title: const Text('Panduan NUSARTA'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Lewati'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Row(children: [
              for (var i = 0; i < _steps.length; i++)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= _index
                          ? AppColors.primary
                          : AppColors.neutral.withAlpha(45),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ]),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _steps.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => _steps[i].build(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: Row(children: [
              if (_index > 0)
                OutlinedButton(
                  onPressed: () => _goTo(_index - 1),
                  child: const Text('Kembali'),
                ),
              const Spacer(),
              if (last)
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('Selesai'),
                )
              else
                FilledButton(
                  onPressed: () => _goTo(_index + 1),
                  child: const Text('Lanjut'),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _TutorialStep {
  const _TutorialStep({
    required this.title,
    required this.description,
    required this.preview,
  });
  final String title;
  final String description;
  final Widget preview;

  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.deepEmerald, AppColors.primaryDark]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.gold.withAlpha(80)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: preview,
              ),
            ),
            const SizedBox(height: 24),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(description,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.neutral, height: 1.55)),
          ],
        ),
      );
}

class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.cream,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(child: child),
          ),
        ),
      );
}

class _WelcomePreview extends StatelessWidget {
  const _WelcomePreview();

  @override
  Widget build(BuildContext context) => _PreviewFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                color: AppColors.goldLight, size: 56),
            const SizedBox(height: 14),
            Text('NUSARTA',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2)),
            const SizedBox(height: 6),
            Text('Keuanganmu, Dalam Kendalimu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.neutral, fontSize: 13)),
            const SizedBox(height: 22),
            const _FakeButton(label: 'Mulai'),
          ],
        ),
      );
}

class _TransactionPreview extends StatelessWidget {
  const _TransactionPreview();

  @override
  Widget build(BuildContext context) => _PreviewFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TransactionRow(
                icon: Icons.shopping_bag_outlined,
                label: 'Belanja kebutuhan',
                category: 'Belanja',
                amount: '-Rp245.000',
                amountColor: AppColors.expense),
            const SizedBox(height: 8),
            _TransactionRow(
                icon: Icons.trending_up,
                label: 'Gaji bulan ini',
                category: 'Pemasukan',
                amount: '+Rp5.200.000',
                amountColor: AppColors.income),
          ],
        ),
      );
}

class _LinkPreview extends StatelessWidget {
  const _LinkPreview();

  @override
  Widget build(BuildContext context) => const _PreviewFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InstitutionMini(label: 'BCA', type: 'Bank'),
            SizedBox(height: 8),
            _InstitutionMini(label: 'GoPay', type: 'E-Wallet'),
            SizedBox(height: 8),
            _InstitutionMini(label: 'DANA', type: 'E-Wallet'),
          ],
        ),
      );
}

class _DashboardPreview extends StatelessWidget {
  const _DashboardPreview();

  @override
  Widget build(BuildContext context) => _PreviewFrame(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Total Saldo',
                  style: TextStyle(color: AppColors.neutral, fontSize: 12)),
              const SizedBox(height: 2),
              const Text('Rp12.845.000',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              const _BarRow(left: 11, right: 5),
              const _BarRow(left: 7, right: 9),
              const _BarRow(left: 13, right: 3),
            ]),
      );
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.left, required this.right});
  final double left;
  final double right;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(
              flex: left.toInt(),
              child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(110),
                      borderRadius: BorderRadius.circular(5)))),
          const SizedBox(width: 6),
          Expanded(
              flex: right.toInt(),
              child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                      color: AppColors.gold.withAlpha(120),
                      borderRadius: BorderRadius.circular(5)))),
        ]),
      );
}

class _BudgetPreview extends StatelessWidget {
  const _BudgetPreview();

  @override
  Widget build(BuildContext context) => const _PreviewFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BudgetBar(label: 'Makanan', used: 0.62),
            SizedBox(height: 10),
            _BudgetBar(label: 'Transportasi', used: 0.35),
            SizedBox(height: 10),
            _BudgetBar(label: 'Belanja', used: 0.88),
          ],
        ),
      );
}

class _BudgetBar extends StatelessWidget {
  const _BudgetBar({required this.label, required this.used});
  final String label;
  final double used;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          LayoutBuilder(
              builder: (context, constraints) => Stack(children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                          color: AppColors.neutral.withAlpha(40),
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    FractionallySizedBox(
                        widthFactor: used,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                              color: used > 0.8
                                  ? AppColors.expense
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(4)),
                        )),
                  ])),
        ],
      );
}

class _GoalPreview extends StatelessWidget {
  const _GoalPreview();

  @override
  Widget build(BuildContext context) => const _PreviewFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GoalRow(name: 'Dana Darurat', target: 'Rp10.000.000', pct: '45%'),
            SizedBox(height: 10),
            _GoalRow(name: 'Kamera Baru', target: 'Rp8.500.000', pct: '70%'),
          ],
        ),
      );
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.name,
    required this.target,
    required this.pct,
  });
  final String name;
  final String target;
  final String pct;

  @override
  Widget build(BuildContext context) {
    final fraction = double.parse(pct.replaceAll('%', '')) / 100;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.neutral.withAlpha(35))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13))),
            Text(pct,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w800)),
          ]),
          Text(target,
              style: TextStyle(color: AppColors.neutral, fontSize: 12)),
          const SizedBox(height: 6),
          FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(3)))),
        ],
      ),
    );
  }
}

class _ReportPreview extends StatelessWidget {
  const _ReportPreview();

  @override
  Widget build(BuildContext context) => _PreviewFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatBox(
                label: 'Pemasukan',
                value: 'Rp8.300.000',
                color: AppColors.income),
            const SizedBox(height: 10),
            _StatBox(
                label: 'Pengeluaran',
                value: 'Rp4.215.000',
                color: AppColors.expense),
            const SizedBox(height: 10),
            const _StatBox(
                label: 'Selisih',
                value: '+Rp4.085.000',
                color: AppColors.primary),
          ],
        ),
      );
}

class _StatBox extends StatelessWidget {
  const _StatBox(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(color: AppColors.neutral, fontSize: 12))),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 14)),
        ]),
      );
}

class _SecurityPreview extends StatelessWidget {
  const _SecurityPreview();

  @override
  Widget build(BuildContext context) => _PreviewFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fingerprint, color: AppColors.gold, size: 52),
            const SizedBox(height: 12),
            Text('Buka dengan Biometrik',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
            const SizedBox(height: 6),
            Text('PIN 6 digit tetap tersedia sebagai cadangan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.neutral, fontSize: 12)),
          ],
        ),
      );
}

class _TransferPreview extends StatelessWidget {
  const _TransferPreview();

  @override
  Widget build(BuildContext context) => _PreviewFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_horiz_rounded,
                color: AppColors.gold, size: 52),
            const SizedBox(height: 12),
            Text('Transfer',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Segera Hadir',
                style: TextStyle(
                    color: AppColors.gold, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Aktif hanya melalui provider resmi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.neutral, fontSize: 12)),
          ],
        ),
      );
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.icon,
    required this.label,
    required this.category,
    required this.amount,
    required this.amountColor,
  });
  final IconData icon;
  final String label;
  final String category;
  final String amount;
  final Color amountColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.neutral.withAlpha(35))),
        child: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: amountColor.withAlpha(22),
            child: Icon(icon, color: amountColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                Text(category,
                    style: TextStyle(color: AppColors.neutral, fontSize: 11.5)),
              ])),
          Text(amount,
              style:
                  TextStyle(color: amountColor, fontWeight: FontWeight.w800)),
        ]),
      );
}

class _InstitutionMini extends StatelessWidget {
  const _InstitutionMini({required this.label, required this.type});
  final String label;
  final String type;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.neutral.withAlpha(35))),
        child: Row(children: [
          CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withAlpha(20),
              child: Text(label.substring(0, 1),
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w800))),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13))),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.gold.withAlpha(24),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(type,
                  style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700))),
        ]),
      );
}

class _FakeButton extends StatelessWidget {
  const _FakeButton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      );
}
