import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/labels.dart';
import '../../data/models/notification.dart';
import '../../providers/finance_providers.dart';
import '../../widgets/empty_state.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  String _relative(DateTime time) {
    final diff = DateTime.now().difference(time.toLocal());
    if (diff.inDays >= 1) return '${diff.inDays} hari yang lalu';
    if (diff.inHours >= 1) return '${diff.inHours} jam yang lalu';
    if (diff.inMinutes >= 5) return '${diff.inMinutes} menit yang lalu';
    return 'Baru saja';
  }

  IconData _iconFor(AppNotificationType type) => switch (type) {
        AppNotificationType.transaction => Icons.receipt_long_outlined,
        AppNotificationType.budget => Icons.donut_small_outlined,
        AppNotificationType.security => Icons.shield_outlined,
        AppNotificationType.accountConnection => Icons.link_outlined,
        AppNotificationType.transfer => Icons.swap_horiz,
        AppNotificationType.system => Icons.campaign_outlined,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final hasUnread = notifications.valueOrNull?.any((n) => !n.isRead) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (hasUnread)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () =>
                    ref.read(notificationsControllerProvider).markAllRead(),
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Tandai dibaca'),
              ),
            ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Gagal memuat notifikasi')),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none,
              title: 'Belum ada notifikasi',
              message: 'Pembaruan transaksi, budget, dan keamanan akan '
                  'muncul di sini.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = list[index];
              return _NotificationTile(
                notification: n,
                relative: _relative(n.createdAt),
                icon: _iconFor(n.type),
                onTap: () {
                  if (!n.isRead) {
                    ref.read(notificationsControllerProvider).markRead(n.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.relative,
    required this.icon,
    required this.onTap,
  });

  final AppNotification notification;
  final String relative;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              notification.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight:
                    notification.isRead ? FontWeight.w400 : FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          if (!notification.isRead) ...[
            const SizedBox(width: 6),
            const Icon(Icons.circle, size: 8, color: AppColors.primary),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notification.body != null && notification.body!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                notification.body!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${notificationTypeLabel(notification.type)} · $relative',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.neutral),
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
