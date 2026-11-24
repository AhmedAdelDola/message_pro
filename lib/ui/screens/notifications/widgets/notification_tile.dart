import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/data/models/notification_item.dart';

class NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final timeStr = _formatTimestamp(notification.createdAt, isArabic);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.transparent
              : (isDark ? AppColors.darkSurface : AppColors.brandSubtle.withValues(alpha: 0.3)),
          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationBadge(notification.notificationType),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title ?? (isArabic ? 'إشعار جديد' : 'New Notification'),
                    style: TextStyle(
                      fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                      fontSize: 14,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF80838D),
                    ),
                  ),
                  if (notification.message != null && notification.message!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.message!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBadge(String? type) {
    Color bg;
    IconData icon;

    switch (type) {
      case 'conversation_creation':
      case 'assigned_conversation_new_message':
        bg = const Color(0xFF2563EB);
        icon = Icons.mark_email_unread_rounded;
        break;
      case 'message_created':
        bg = const Color(0xFF16A34A);
        icon = Icons.chat_bubble_outline_rounded;
        break;
      case 'conversation_mention':
        bg = const Color(0xFF7C3AED);
        icon = Icons.alternate_email_rounded;
        break;
      default:
        bg = AppColors.primary;
        icon = Icons.notifications_none_rounded;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  String _formatTimestamp(DateTime dt, bool isArabic) {
    final now = DateTime.now();
    final isToday = now.year == dt.year && now.month == dt.month && now.day == dt.day;
    final timeFormat = DateFormat('h:mm a').format(dt);

    if (isToday) {
      return isArabic ? 'اليوم في $timeFormat' : 'Today at $timeFormat';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = yesterday.year == dt.year && yesterday.month == dt.month && yesterday.day == dt.day;
    if (isYesterday) {
      return isArabic ? 'أمس في $timeFormat' : 'Yesterday at $timeFormat';
    }
    return DateFormat('MMM d, h:mm a').format(dt);
  }
}
