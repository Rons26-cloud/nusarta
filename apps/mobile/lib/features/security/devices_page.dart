import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/labels.dart';
import '../../data/models/device.dart';
import '../../providers/finance_providers.dart';
import '../../widgets/empty_state.dart';

class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  String _relative(DateTime time) {
    final diff = DateTime.now().difference(time.toLocal());
    if (diff.inDays >= 1) return '${diff.inDays} hari yang lalu';
    if (diff.inHours >= 1) return '${diff.inHours} jam yang lalu';
    if (diff.inMinutes >= 5) return '${diff.inMinutes} menit yang lalu';
    return 'Baru saja';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesProvider);
    final deviceId = ref.watch(currentDeviceIdProvider);

    final currentId = deviceId.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Perangkat')),
      body: devices.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Gagal memuat perangkat')),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.devices_other_outlined,
              title: 'Belum ada perangkat',
              message:
                  'Perangkat ini akan terdaftar saat kamu membuka aplikasi.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              for (final device in list)
                _buildDeviceTile(context, device, currentId),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Tidak ada perangkat yang dapat dicabut melalui aplikasi '
                  'di versi ini. Pengelolaan perangkat aktif akan tersedia di '
                  'perilisan keamanan berikutnya.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeviceTile(
      BuildContext context, Device device, String? currentId) {
    final isCurrent = device.deviceIdentifier == currentId;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withAlpha(26),
          child: Icon(
            switch (device.platform) {
              DevicePlatform.android || DevicePlatform.ios => Icons.smartphone,
              DevicePlatform.web => Icons.language,
              DevicePlatform.other => Icons.devices_other,
            },
            color: AppColors.primary,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                device.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.income.withAlpha(31),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Perangkat ini',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.income,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(devicePlatformLabel(device.platform)),
              Text(
                'Terakhir aktif ${_relative(device.lastSeenAt)}${device.appVersion == null ? '' : ' · v${device.appVersion}'}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.neutral),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
