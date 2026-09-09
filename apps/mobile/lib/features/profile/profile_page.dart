import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/update_provider.dart';
import '../../core/updates/update_models.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final displayName = user?.userMetadata?['display_name'] as String?;
    final shownName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : user?.email ?? 'Pengguna';
    final email = user?.email;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: const Icon(Icons.person, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            shownName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (email != null) ...[
            const SizedBox(height: 4),
            Text(
              email,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.neutral),
            ),
          ],
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Keamanan'),
                  subtitle: const Text('PIN, biometrik, perangkat & aktivitas'),
                  onTap: () => context.push('/settings'),
                ),
                for (final item in const [
                  (Icons.password_outlined, 'Ubah PIN', 'pin'),
                  (Icons.fingerprint, 'Biometrik', 'biometric'),
                  (Icons.timer_outlined, 'Kunci Otomatis', 'auto-lock'),
                  (Icons.brightness_6_outlined, 'Tema', 'theme'),
                ]) ListTile(leading: Icon(item.$1), title: Text(item.$2),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings?section='+item.$3)),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifikasi'),
                  onTap: () => context.push('/notifications'),
                ),
                ListTile(
                  leading: const Icon(Icons.swap_horiz_outlined),
                  title: const Text('Transfer (Bank/E-Wallet)'),
                  subtitle: const Text('Segera hadir'),
                  onTap: () => context.push('/transfer'),
                ),
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Tujuan Keuangan'),
                  onTap: () => context.push('/goals'),
                ),
                ListTile(
                  leading: const Icon(Icons.donut_small_outlined),
                  title: const Text('Budget'),
                  onTap: () => context.push('/budgets'),
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart_outlined),
                  title: const Text('Laporan'),
                  onTap: () => context.push('/reports'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Pusat Bantuan'),
                  subtitle: const Text('Tanya jawab umum penggunaan NUSARTA'),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const _HelpDialog(),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Tentang NUSARTA'),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const _AboutDialog(),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.system_update_outlined),
                  title: const Text('Periksa Pembaruan'),
                  onTap: () async {
                    final state = await ref.read(updateControllerProvider).check(force: true);
                    if (!context.mounted) return;
                    if (state.status == UpdateStatus.updateAvailable && state.release != null) {
                      showDialog(context: context, builder: (_) => AlertDialog(
                        title: const Text('Pembaruan Tersedia'),
                        content: Text('NUSARTA v${state.release!.version}\n\n${state.release!.releaseNotes}'),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Nanti')), ElevatedButton(onPressed: () { launchUrl(Uri.parse(state.release!.apkDownloadUrl), mode: LaunchMode.externalApplication); Navigator.pop(context); }, child: const Text('Update Sekarang'))],
                      ));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.status == UpdateStatus.error ? 'Tidak dapat memeriksa pembaruan. Coba lagi.' : 'Anda menggunakan versi terbaru.')));
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_remove_outlined,
                      color: AppColors.expense),
                  title: const Text('Hapus Akun',
                      style: TextStyle(color: AppColors.expense)),
                  subtitle:
                      const Text('Hapus akun dan semua data secara permanen'),
                  onTap: () => context.push('/delete-account'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.expense),
              title: const Text('Keluar',
                  style: TextStyle(color: AppColors.expense)),
              onTap: () async {
                await ref.read(authControllerProvider).signOut();
                await SecureStore.clear();
                if (context.mounted) {
                  context.go('/');
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'NUSARTA ${AppConfig.version}+${AppConfig.buildNumber}',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.neutral),
          ),
        ],
      ),
    );
  }
}

class _HelpDialog extends StatelessWidget {
  const _HelpDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pusat Bantuan'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HelpItem(
              question: 'Lupa PIN?',
              answer:
                  'PIN tidak dapat dilihat kembali. Keluar lalu masuk kembali '
                  'akan meminta konfigurasi ulang perangkat keamanan.',
            ),
            _HelpItem(
              question: 'Apa itu Pindah Saldo?',
              answer: 'Pindah saldo hanya memindahkan pencatatan antar akun '
                  'NUSARTA dan tidak mengirim uang melalui bank.',
            ),
            _HelpItem(
              question: 'Data saya aman?',
              answer:
                  'Semua data dilindungi autentikasi akun, PIN, dan kebijakan '
                  'akses per pengguna.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(answer, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tentang NUSARTA'),
      content: const SingleChildScrollView(
        child: Text(
          'NUSARTA (Nusa + Arta) adalah aplikasi pencatatan keuangan pribadi '
          'yang sederhana dan aman. "Keuanganmu, Dalam Kendalimu."\n\n'
          'Semua pencatatan bersifat manual dan tersimpan di akun kamu, '
          'dilindungi autentikasi serta PIN 6 digit.',
          style: TextStyle(fontSize: 13),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
