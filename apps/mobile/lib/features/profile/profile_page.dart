import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/data/supabase_client.dart';
import '../../core/security/pin_service.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/updates/update_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_providers.dart';
import '../../providers/lock_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/update_provider.dart';
import '../../widgets/settings_section.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final rawName = metadata['display_name'] as String?;
    final name = rawName == null || rawName.trim().isEmpty
        ? 'Pengguna NUSARTA'
        : rawName.trim();
    final email = user?.email?.trim();
    final phone = user?.phone?.trim();
    final verified = user?.emailConfirmedAt != null;
    final devices = ref.watch(devicesProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOff,
      appBar: AppBar(title: const Text('Profil & Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _ProfileCard(
            name: name,
            email: email,
            verified: verified,
            onEdit: () => _editProfile(context),
          ),
          SettingsSection(title: 'AKUN', children: [
            _item(context, Icons.person_outline, 'Informasi Pribadi',
                'Kelola nama dan identitas akun', null,
                onTap: () => _editProfile(context)),
            _item(context, Icons.mail_outline, 'Email',
                email ?? 'Belum tersedia', null,
                onTap: () => _emailAction(context, ref)),
            if (phone != null && phone.isNotEmpty)
              _item(
                  context, Icons.phone_outlined, 'Nomor Telepon', phone, null),
            _item(
                context,
                Icons.account_balance_wallet_outlined,
                'Akun Keuangan',
                'Kelola akun bank, e-wallet, dan tunai',
                '/accounts'),
            _item(context, Icons.flag_outlined, 'Tujuan Keuangan',
                'Pantau target finansialmu', '/goals'),
          ]),
          SettingsSection(title: 'KEAMANAN', children: [
            _statusItem(
                context,
                Icons.password_outlined,
                'PIN NUSARTA',
                PinService.isSet,
                'Aktif',
                'Belum diatur',
                '/settings?section=pin'),
            _statusItem(
                context,
                Icons.fingerprint,
                'Biometrik',
                ref.read(lockControllerProvider).isBiometricEnabled(),
                'Aktif',
                'Nonaktif',
                '/settings?section=biometric'),
            _item(context, Icons.lock_clock_outlined, 'Kunci Otomatis',
                'Atur durasi penguncian', '/settings?section=auto-lock'),
            _item(
                context,
                Icons.devices_outlined,
                'Perangkat',
                devices.when(
                    data: (v) => '${v.length} perangkat',
                    loading: () => 'Memuat…',
                    error: (_, __) => 'Tidak tersedia'),
                '/devices'),
            _item(context, Icons.history_outlined, 'Aktivitas Keamanan',
                'Riwayat login dan keamanan', '/settings'),
          ]),
          SettingsSection(title: 'PREFERENSI', children: [
            _item(context, Icons.brightness_6_outlined, 'Tema',
                _themeLabel(themeMode), '/settings?section=theme'),
            _item(context, Icons.currency_exchange_outlined, 'Mata Uang',
                'Rupiah (IDR)', null),
            _item(context, Icons.notifications_none_rounded, 'Notifikasi',
                'Segera hadir', '/notifications'),
          ]),
          SettingsSection(title: 'DATA & PRIVASI', children: [
            _item(context, Icons.privacy_tip_outlined, 'Privasi & Keamanan',
                'Pelajari perlindungan data NUSARTA', null),
            _item(context, Icons.download_outlined, 'Kelola Data',
                'Data pencatatan tetap milikmu', null),
            _item(context, Icons.person_remove_outlined, 'Hapus Akun',
                'Hapus akun dan data secara permanen', '/delete-account',
                destructive: true),
          ]),
          SettingsSection(title: 'BANTUAN & INFORMASI', children: [
            _item(context, Icons.help_outline_rounded, 'Pusat Bantuan',
                'Jawaban untuk pertanyaan umum', null,
                onTap: () => _showHelp(context)),
            _item(context, Icons.info_outline_rounded, 'Tentang NUSARTA',
                'Keuanganmu, Dalam Kendalimu.', null,
                onTap: () => _showAbout(context)),
            _item(context, Icons.policy_outlined, 'Kebijakan Privasi',
                'Segera hadir', null),
            _item(context, Icons.description_outlined, 'Syarat & Ketentuan',
                'Segera hadir', null),
            _item(context, Icons.system_update_outlined, 'Versi Aplikasi',
                'NUSARTA ${AppConfig.version}+${AppConfig.buildNumber}', null,
                onTap: () => _checkUpdate(context, ref)),
          ]),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar dari Akun'),
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.expense,
              backgroundColor: AppColors.expense.withOpacity(.08),
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String title,
      String subtitle, String? route,
      {VoidCallback? onTap, bool destructive = false}) {
    return ListTile(
      leading: Icon(icon,
          color: destructive ? AppColors.expense : AppColors.primary),
      title: Text(title,
          style: destructive
              ? const TextStyle(
                  color: AppColors.expense, fontWeight: FontWeight.w700)
              : null),
      subtitle: Text(subtitle),
      trailing: route == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap ?? (route == null ? null : () => context.push(route)),
    );
  }

  Widget _statusItem(BuildContext context, IconData icon, String title,
      Future<bool> status, String yes, String no, String route) {
    return FutureBuilder<bool>(
      future: status,
      builder: (context, snapshot) => _item(
        context,
        icon,
        title,
        snapshot.connectionState == ConnectionState.waiting
            ? 'Memuat…'
            : snapshot.data == true
                ? yes
                : no,
        route,
      ),
    );
  }

  String _themeLabel(String mode) => switch (mode) {
        'light' => 'Terang',
        'dark' => 'Gelap',
        _ => 'Mengikuti Sistem',
      };

  Future<void> _emailAction(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user?.emailConfirmedAt != null) {
      _showInfo(context, 'Email terverifikasi',
          'Email akun ini sudah terverifikasi.');
      return;
    }
    final email = user?.email;
    if (email == null || email.isEmpty) return;
    try {
      await SupabaseConfig.client.auth
          .resend(type: OtpType.signup, email: email);
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email verifikasi dikirim ulang.')));
    } catch (_) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengirim ulang verifikasi.')));
    }
  }

  Future<void> _editProfile(BuildContext context) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final name = TextEditingController(
        text: user.userMetadata?['display_name'] as String? ?? '');
    final phone = TextEditingController(text: user.phone ?? '');
    final email = TextEditingController(text: user.email ?? '');
    final saved = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Informasi Pribadi'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: name,
                    textCapitalization: TextCapitalization.words,
                    decoration:
                        const InputDecoration(labelText: 'Nama Lengkap')),
                const SizedBox(height: 12),
                TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration:
                        const InputDecoration(labelText: 'Nomor Telepon')),
                const SizedBox(height: 12),
                TextField(
                    enabled: false,
                    controller: email,
                    decoration: const InputDecoration(
                        labelText: 'Email (dikelola Supabase)')),
                if (user.emailConfirmedAt == null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Email belum terverifikasi. Verifikasi diperlukan untuk '
                    'reset PIN dan pemulihan akun.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.neutral),
                  ),
                ],
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Batal')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Simpan'))
              ],
            ));
    if (saved != true) {
      name.dispose();
      phone.dispose();
      email.dispose();
      return;
    }
    try {
      await SupabaseConfig.client.auth.updateUser(UserAttributes(
          data: {'display_name': name.text.trim()},
          phone: phone.text.trim().isEmpty ? null : phone.text.trim()));
      try {
        await SupabaseConfig.client.from('profiles').update({
          'display_name': name.text.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String()
        }).eq('id', user.id);
      } catch (_) {
        // The auth metadata is authoritative; the profile row may not exist.
      }
      ref.invalidate(currentUserProvider);
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil berhasil diperbarui.')));
    } catch (_) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil belum berhasil disimpan.')));
    } finally {
      name.dispose();
      phone.dispose();
      email.dispose();
    }
  }

  void _showInfo(BuildContext context, String title, String body) =>
      showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
                  title: Text(title),
                  content: Text(body),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tutup'))
                  ]));
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari NUSARTA?'),
        content: const Text('Anda perlu masuk kembali untuk mengakses akun.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Keluar')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(authControllerProvider).signOut();
    await SecureStore.clear();
    if (context.mounted) context.go('/login');
  }

  Future<void> _checkUpdate(BuildContext context, WidgetRef ref) async {
    final state = await ref.read(updateControllerProvider).check(force: true);
    if (!context.mounted) return;
    if (state.status == UpdateStatus.updateAvailable && state.release != null) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Pembaruan Tersedia'),
          content: Text(
              'NUSARTA v${state.release!.version}\n\n${state.release!.releaseNotes}'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Nanti')),
            FilledButton(
              onPressed: () {
                launchUrl(Uri.parse(state.release!.apkDownloadUrl),
                    mode: LaunchMode.externalApplication);
                Navigator.pop(context);
              },
              child: const Text('Update Sekarang'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(state.status == UpdateStatus.error
            ? 'Tidak dapat memeriksa pembaruan. Coba lagi.'
            : 'Anda menggunakan versi terbaru.'),
      ));
    }
  }

  void _showHelp(BuildContext context) => showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Pusat Bantuan'),
          content: Text(
              'Lupa PIN? Keluar lalu masuk kembali untuk mengatur ulang keamanan perangkat.\n\nPencatatan NUSARTA bersifat manual dan tidak mengakses PIN bank.'),
        ),
      );

  void _showAbout(BuildContext context) => showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Tentang NUSARTA'),
          content: Text(
              'NUSARTA (Nusa + Arta) membantu kamu mengelola pencatatan keuangan pribadi dengan aman.\n\nKeuanganmu, Dalam Kendalimu.'),
        ),
      );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard(
      {required this.name,
      required this.email,
      required this.verified,
      this.onEdit});
  final String name;
  final String? email;
  final bool verified;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final initial =
        name.trim().isEmpty ? 'N' : name.trim().substring(0, 1).toUpperCase();
    final shownEmail = email == null || email!.isEmpty
        ? 'Email belum tersedia'
        : _maskEmail(email!);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.deepEmerald, AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withAlpha(90)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x18031D16), blurRadius: 18, offset: Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.cream,
              child: Text(initial,
                  style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w800))),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(shownEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 9),
                Row(children: [
                  Icon(verified ? Icons.verified_rounded : Icons.info_outline,
                      size: 16, color: AppColors.goldLight),
                  const SizedBox(width: 5),
                  Flexible(
                      child: Text(
                          verified
                              ? 'Akun Terverifikasi'
                              : 'Verifikasi email diperlukan',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.goldLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)))
                ]),
              ])),
          const SizedBox(width: 8),
          Image.asset('assets/brand/logo.png',
              width: 46, height: 28, fit: BoxFit.contain),
          if (onEdit != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onEdit,
              tooltip: 'Ubah profil',
              color: Colors.white,
              icon: const Icon(Icons.edit_outlined, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

String _maskEmail(String email) {
  final parts = email.split('@');
  if (parts.length != 2 || parts.first.length < 3) return email;
  return '${parts.first.substring(0, 3)}***@${parts.last}';
}
