import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/updates/github_release_source.dart';
import '../../core/updates/update_models.dart';
import '../../providers/update_provider.dart';

class VersionPage extends ConsumerStatefulWidget {
  const VersionPage({super.key});

  @override
  ConsumerState<VersionPage> createState() => _VersionPageState();
}

class _VersionPageState extends ConsumerState<VersionPage> {
  PackageInfo? _info;
  TestReleaseInfo? _testing;
  bool _onTesting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    PackageInfo? info;
    TestReleaseInfo? testing;
    try {
      info = await PackageInfo.fromPlatform();
    } catch (_) {}
    try {
      testing = await latestTestRelease();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _info = info;
      _testing = testing;
      _onTesting =
          testing != null && info != null && testing.version == info.version;
    });
  }

  Future<void> _check(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    final update = ref.watch(updateStateProvider);
    final version = _info?.version ?? AppConfig.version;
    final build = _info?.buildNumber ?? AppConfig.buildNumber;

    return Scaffold(
      backgroundColor: AppColors.backgroundOff,
      appBar: AppBar(title: const Text('Versi Aplikasi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.deepEmerald, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.gold.withAlpha(90)),
            ),
            child: Column(children: [
              Image.asset('assets/brand/logo.png',
                  width: 96, height: 56, fit: BoxFit.contain),
              const SizedBox(height: 12),
              Text('NUSARTA $version+$build',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Chip(
                avatar: Icon(
                    _onTesting
                        ? Icons.science_outlined
                        : Icons.check_circle_outline,
                    size: 16,
                    color: _onTesting ? AppColors.gold : AppColors.goldLight),
                label: Text(_onTesting ? 'Versi Pengujian' : 'Rilis Stabil'),
                backgroundColor: Colors.white.withAlpha(20),
                labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          const Text('PEMBARUAN APLIKASI',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(children: [
              ListTile(
                leading: Icon(
                    update.status == UpdateStatus.checking
                        ? Icons.sync_rounded
                        : update.status == UpdateStatus.updateAvailable
                            ? Icons.system_update_alt_rounded
                            : update.status == UpdateStatus.error
                                ? Icons.error_outline
                                : Icons.verified_outlined,
                    color: AppColors.brandEmerald),
                title: const Text('Periksa Pembaruan'),
                subtitle: Text(_statusLabel(update)),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: update.status == UpdateStatus.checking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh_rounded),
                      label: Text(update.status == UpdateStatus.checking
                          ? 'Memeriksa…'
                          : 'Cek Sekarang'),
                      onPressed: update.status == UpdateStatus.checking
                          ? null
                          : () => _check(context),
                    ),
                  ),
                  if (update.status == UpdateStatus.updateAvailable &&
                      update.release != null) ...[
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                        tooltip: 'Unduh pembaruan',
                        onPressed: () => launchUrl(
                            Uri.parse(update.release!.apkDownloadUrl),
                            mode: LaunchMode.externalApplication),
                        icon: const Icon(Icons.download_rounded)),
                  ],
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          if (_onTesting && _testing != null)
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading:
                    Icon(Icons.science_outlined, color: AppColors.brandEmerald),
                title: const Text('Rilis Pengujian'),
                subtitle: Text('${_testing!.tagName} tersedia'),
                trailing: const Icon(Icons.download_rounded),
                onTap: () => launchUrl(Uri.parse(_testing!.apkDownloadUrl),
                    mode: LaunchMode.externalApplication),
              ),
            ),
          const SizedBox(height: 6),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading:
                  Icon(Icons.build_outlined, color: AppColors.brandEmerald),
              title: const Text('Info Build'),
              subtitle: Text('Channel: ${_onTesting ? 'testing' : 'stable'}\n'
                  'Platform: Android'),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(UpdateState update) => switch (update.status) {
        UpdateStatus.idle => 'Belum diperiksa',
        UpdateStatus.checking => 'Memeriksa versi terbaru…',
        UpdateStatus.latest => 'Anda menggunakan versi terbaru',
        UpdateStatus.updateAvailable =>
          'Versi ${update.release?.version} tersedia',
        UpdateStatus.error => 'Gagal memeriksa pembaruan',
      };
}
