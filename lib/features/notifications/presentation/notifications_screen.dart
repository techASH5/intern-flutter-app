import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/notification_model.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final notifications = state.sorted;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [AppColors.darkBackground, AppColors.darkCardBackground]
                : [AppColors.lightBackground1, AppColors.lightBackground2],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(LucideIcons.arrowLeft),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppColors.primaryViolet.withOpacity(0.1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Notifications',
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall),
                            if (state.unreadCount > 0)
                              Text(
                                '${state.unreadCount} unread',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: AppColors.primaryViolet,
                                        fontWeight: FontWeight.w600),
                              ),
                          ],
                        ),
                      ),
                      if (state.unreadCount > 0)
                        TextButton.icon(
                          onPressed: () => ref
                              .read(notificationsProvider.notifier)
                              .markAllRead(),
                          icon: const Icon(LucideIcons.checkCheck, size: 16),
                          label: const Text('Mark all read'),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryViolet),
                        ),
                    ],
                  ),
                ),
              ),

              if (state.isLoading && notifications.isEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const _NotifShimmer(),
                    childCount: 4,
                  ),
                )
              else if (notifications.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.bellOff,
                            size: 56, color: AppColors.primaryViolet),
                        const SizedBox(height: 16),
                        Text('All caught up!',
                            style:
                                Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text('No notifications at the moment',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _NotificationTile(
                        notification: notifications[i],
                        onTap: () => ref
                            .read(notificationsProvider.notifier)
                            .markRead(notifications[i].id),
                        onDelete: () => ref
                            .read(notificationsProvider.notifier)
                            .delete(notifications[i].id),
                      ),
                      childCount: notifications.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  Color get _typeColor {
    switch (notification.type) {
      case 'alert':
        return AppColors.overdueRed;
      case 'success':
        return AppColors.healthyGreen;
      default:
        return AppColors.primaryViolet;
    }
  }

  IconData get _typeIcon {
    switch (notification.type) {
      case 'alert':
        return LucideIcons.alertTriangle;
      case 'success':
        return LucideIcons.checkCircle2;
      default:
        return LucideIcons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 10),
        color: notification.isRead
            ? null
            : color.withOpacity(0.05),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_typeIcon, color: color, size: 20),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                              ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Delete
            IconButton(
              onPressed: onDelete,
              icon: const Icon(LucideIcons.x, size: 16),
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor:
                    Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM dd, yyyy').format(dt);
  }
}

class _NotifShimmer extends StatelessWidget {
  const _NotifShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c =
        isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: GlassCard(
        child: Row(children: [
          Container(
              width: 40,
              height: 40,
              decoration:
                  BoxDecoration(color: c, borderRadius: BorderRadius.circular(10))),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                      color: c, borderRadius: BorderRadius.circular(7))),
              const SizedBox(height: 6),
              Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: c, borderRadius: BorderRadius.circular(6))),
            ]),
          ),
        ]),
      ),
    );
  }
}
