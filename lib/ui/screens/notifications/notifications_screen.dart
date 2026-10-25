import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/notification_provider.dart';
import '../../widgets/empty_state_widget.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات (Notifications)'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => notifier.markAllAsRead(),
              child: const Text('قراءة الكل', style: TextStyle(fontSize: 13)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifier.loadNotifications(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.loadNotifications(),
        child: state.isLoading && state.notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.notifications.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.notifications_off_rounded,
                    title: 'لا توجد إشعارات',
                    description: 'أنت على اطلاع دائم، لا توجد إشعارات جديدة حالياً.',
                  )
                : ListView.separated(
                    itemCount: state.notifications.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    itemBuilder: (context, index) {
                      final item = state.notifications[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: item.isRead
                              ? Colors.grey.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.15),
                          child: Icon(
                            _getIcon(item.notificationType),
                            color: item.isRead ? Colors.grey : AppColors.primaryLight,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item.title ?? 'إشعار جديد',
                          style: TextStyle(
                            fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          item.message ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('dd/MM hh:mm a').format(item.createdAt),
                              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                            ),
                            if (!item.isRead) ...[
                              const SizedBox(height: 4),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          if (!item.isRead) {
                            notifier.markAsRead(item.id);
                          }
                        },
                      );
                    },
                  ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'conversation_assignment':
        return Icons.person_add_rounded;
      case 'conversation_mention':
        return Icons.alternate_email_rounded;
      case 'assigned_conversation_new_message':
        return Icons.message_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
