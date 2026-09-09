import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/security/pin_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/security_event.dart';
import '../../providers/finance_providers.dart';
import '../../providers/lock_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key, this.section});
  final String? section;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _biometricKey = GlobalKey();
  final _autoLockKey = GlobalKey();
  bool? _biometric;
  int _autoLock = 5;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final controller = ref.read(lockControllerProvider);
    _biometric = await controller.isBiometricEnabled();
    _autoLock = await controller.autoLockMinutes;
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.section == 'pin') {
        showDialog(context: context, builder: (_) => const _ChangePinDialog());
      } else if (widget.section == 'theme') {
        _pickTheme(context);
      } else {
        final target = widget.section == 'biometric'
            ? _biometricKey.currentContext
            : widget.section == 'auto-lock'
                ? _autoLockKey.currentContext
                : null;
        if (target != null) Scrollable.ensureVisible(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(lockControllerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final devices = ref.watch(devicesProvider);
    final devicesSummary = devices.valueOrNull == null
        ? 'Memuat…'
        : '${devices.valueOrNull!.length} perangkat terdaftar';

    return Scaffold(
      appBar: AppBar(title: const Text('Keamanan & Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Keamanan', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'PIN, biometrik, kunci otomatis, dan perangkat',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.neutral),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  key: _biometricKey,
                  title: const Text('Buka dengan Biometrik'),
                  subtitle: const Text(
                      'Fingerprint / pengenalan wajah untuk membuka aplikasi'),
                  value: _biometric ?? false,
                  onChanged: _biometric == null
                      ? null
                      : (v) async {
                          setState(() => _biometric = v);
                          if (v) {
                            final ok = await controller.enableBiometric();
                            if (!ok) {
                              setState(() => _biometric = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Perangkat tidak mendukung biometrik.'),
                                  ),
                                );
                              }
                            }
                          } else {
                            await controller.disableBiometric();
                          }
                        },
                ),
                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text('Ubah PIN 6 digit'),
                  subtitle: const Text(
                      'Dibutuhkan untuk membuka aplikasi saat biometrik tidak dipakai'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const _ChangePinDialog(),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.devices_outlined),
                  title: const Text('Perangkat Terdaftar'),
                  subtitle: Text(devicesSummary),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/devices'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: const Text('Tema'),
                  subtitle: Text(_themeModeLabel(themeMode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickTheme(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Aktivitas Keamanan',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _SecurityActivitySection(),
          const SizedBox(height: 16),
          Text('Kunci Otomatis',
              key: _autoLockKey,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(_autoLockLabel(_autoLock)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final controller = ref.read(lockControllerProvider);
                final minutes = await _pickMinutes(context, _autoLock);
                if (minutes == null) return;
                setState(() => _autoLock = minutes);
                await controller.setAutoLockMinutes(minutes);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _autoLockLabel(int minutes) {
    if (minutes == 0) return 'Terkunci saat aplikasi dibuka kembali (Langsung)';
    return 'Terkunci setelah $minutes menit tanpa aktivitas';
  }

  String _themeModeLabel(String mode) => switch (mode) {
        'light' => 'Terang',
        'dark' => 'Gelap',
        _ => 'Mengikuti Sistem',
      };

  Future<void> _pickTheme(BuildContext context) async {
    final current = ref.read(themeModeProvider);
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Tema'),
        children: [
          for (final (value, label) in const [
            ('system', 'Mengikuti Sistem'),
            ('light', 'Terang'),
            ('dark', 'Gelap'),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, value),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(label,
                    style: TextStyle(
                        fontWeight: value == current ? FontWeight.bold : null)),
              ),
            ),
        ],
      ),
    );
    if (picked == null) return;
    await ref.read(themeModeProvider.notifier).set(picked);
  }

  Future<int?> _pickMinutes(BuildContext context, int current) {
    return showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Auto-lock'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 0),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('Langsung',
                  style: TextStyle(
                      fontWeight: current == 0 ? FontWeight.bold : null)),
            ),
          ),
          for (final m in [1, 5, 15, 30])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, m),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('$m menit',
                    style: TextStyle(
                        fontWeight: m == current ? FontWeight.bold : null)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChangePinDialog extends ConsumerStatefulWidget {
  const _ChangePinDialog();

  @override
  ConsumerState<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends ConsumerState<_ChangePinDialog> {
  bool _verifying = true;
  final _current = TextEditingController();
  final _newPin = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _newPin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(_verifying ? 'Masukkan PIN saat ini' : 'Set PIN baru'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _verifying ? _current : _newPin,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              counterText: '',
              labelText: _verifying ? 'PIN saat ini' : 'PIN baru (6 digit)',
            ),
            onChanged: (_) {
              if (_verifying && _current.text.length == 6) {
                _verifyAndProceed();
              }
            },
          ),
          if (!_verifying) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _confirm,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                  counterText: '', labelText: 'Ulangi PIN baru'),
              onChanged: (_) => setState(() => _error = null),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error!,
                  style: const TextStyle(color: AppColors.expense)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        if (!_verifying)
          FilledButton(
            onPressed: _verifying
                ? null
                : () async {
                    if (_newPin.text.length != 6) {
                      setState(() => _error = 'PIN harus 6 digit.');
                      return;
                    }
                    if (_newPin.text != _confirm.text) {
                      setState(() => _error = 'PIN tidak sama. Coba lagi.');
                      return;
                    }
                    await PinService.setPin(_newPin.text);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('PIN berhasil diperbarui.')),
                      );
                    }
                  },
            child: const Text('Simpan'),
          ),
      ],
    );
  }

  Future<void> _verifyAndProceed() async {
    final ok = await PinService.verify(_current.text);
    if (!mounted) return;
    if (!ok) {
      setState(() => _error = 'PIN salah.');
      return;
    }
    setState(() {
      _verifying = false;
      _current.clear();
      _error = null;
    });
  }
}

class _SecurityActivitySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(securityEventsProvider);
    return Card(
      child: events.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
        error: (_, __) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Gagal memuat aktivitas keamanan.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.neutral),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Belum ada aktivitas keamanan yang tercatat.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.neutral),
              ),
            );
          }
          return Column(
            children: [
              for (final (i, event) in list.indexed) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: _eventColor(event).withOpacity(0.12),
                    child: Icon(_eventIcon(event.category),
                        size: 18, color: _eventColor(event)),
                  ),
                  title: Text(_eventLabel(event),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(_relative(event.createdAt),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.neutral)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _relative(DateTime time) {
    final diff = DateTime.now().difference(time.toLocal());
    if (diff.inDays >= 1) {
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(time.toLocal());
    }
    if (diff.inHours >= 1) return '${diff.inHours} jam yang lalu';
    if (diff.inMinutes >= 5) return '${diff.inMinutes} menit yang lalu';
    return 'Baru saja';
  }

  IconData _eventIcon(SecurityEventCategory category) => switch (category) {
        SecurityEventCategory.auth => Icons.login_outlined,
        SecurityEventCategory.security => Icons.shield_outlined,
        SecurityEventCategory.connection => Icons.link_outlined,
        SecurityEventCategory.transfer => Icons.swap_horiz,
        SecurityEventCategory.account => Icons.account_balance_wallet_outlined,
        SecurityEventCategory.system => Icons.info_outline,
      };

  Color _eventColor(SecurityEvent event) {
    if (event.severity >= 2) return AppColors.expense;
    if (event.severity == 1) return AppColors.accent;
    return AppColors.primary;
  }

  String _eventLabel(SecurityEvent event) {
    final type = event.eventType.toLowerCase();
    if (type.contains('login') || type.contains('signin')) {
      return event.severity == 0 ? 'Login berhasil' : 'Percobaan masuk';
    }
    if (type.contains('pin')) {
      return event.severity == 0 ? 'PIN digunakan' : 'PIN salah';
    }
    if (type.contains('biometric')) {
      return event.severity == 0 ? 'Biometrik diaktifkan' : 'Biometrik dicegah';
    }
    if (type.contains('device') || type.contains('register')) {
      return 'Perangkat baru terdaftar';
    }
    if (type.contains('logout') || type.contains('signout')) return 'Keluar';
    return event.eventType.isEmpty ? 'Aktivitas keamanan' : event.eventType;
  }
}
