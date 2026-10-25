import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../logic/notification/notification_cubit.dart';
import '../../../logic/notification/notification_state.dart';
import '../../widgets/empty_state_widget.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        final cubit = context.read<NotificationCubit>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('الإشعارات (Notifications)'),
            actions: [
              if (state.unreadCount > 0)
                TextButton(
                  onPressed: () => cubit.markAllAsRead(),
                  child: Text('قراءة الكل', style: TextStyle(fontSize: 13.sp)),
                ),
              IconButton(
                icon: Icon(Icons.refresh_rounded, size: 22.r),
                onPressed: () => cubit.loadNotifications(),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => cubit.loadNotifications(),
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
                          height: 1.h,
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                        itemBuilder: (context, index) {
                          final item = state.notifications[index];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 20.r,
                              backgroundColor: item.isRead
                                  ? Colors.grey.withValues(alpha: 0.15)
                                  : AppColors.primary.withValues(alpha: 0.15),
                              child: Icon(
                                _getIcon(item.notificationType),
                                color: item.isRead ? Colors.grey : AppColors.primaryLight,
                                size: 20.r,
                              ),
                            ),
                            title: Text(
                              item.title ?? 'إشعار جديد',
                              style: TextStyle(
                                fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                            subtitle: Text(
                              item.message ?? '',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  DateFormat('dd/MM hh:mm a').format(item.createdAt),
                                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
                                ),
                                if (!item.isRead) ...[
                                  SizedBox(height: 4.h),
                                  Container(
                                    width: 8.r,
                                    height: 8.r,
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
                                cubit.markAsRead(item.id);
                              }
                            },
                          );
                        },
                      ),
          ),
        );
      },
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
