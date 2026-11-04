import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/repositories/conversation_repository.dart';
import '../../../logic/notification/notification_cubit.dart';
import '../../../logic/notification/notification_state.dart';
import '../chat/chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'new'; // 'new', 'archived', 'all'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            final cubit = context.read<NotificationCubit>();

            var items = state.notifications;
            if (_selectedFilter == 'new') {
              items = items.where((n) => !n.isRead).toList();
            } else if (_selectedFilter == 'archived') {
              items = items.where((n) => n.isRead).toList();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row (matching Web/Mobile Header)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isArabic ? 'الإشعارات' : 'Notifications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          fontFamily: 'Gontserrat',
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: state.unreadCount > 0 ? () => cubit.markAllAsRead() : null,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              isArabic ? 'أرشفة الكل' : 'Archive all',
                              style: TextStyle(
                                color: state.unreadCount > 0 ? AppColors.primary : textSecondary.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                fontFamily: 'Gontserrat',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Horizontal Underline Filter Tabs (New | Archived | All)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                  ),
                  child: Row(
                    children: [
                      _buildTabItem('new', isArabic ? 'جديدة' : 'New', isDark),
                      const SizedBox(width: 24),
                      _buildTabItem('archived', isArabic ? 'مؤرشفة' : 'Archived', isDark),
                      const SizedBox(width: 24),
                      _buildTabItem('all', isArabic ? 'الكل' : 'All', isDark),
                    ],
                  ),
                ),

                // Notifications List
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => cubit.loadNotifications(),
                    child: state.isLoading && items.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          )
                        : items.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_none_rounded,
                                      size: 52,
                                      color: isDark ? const Color(0xFF80838D) : const Color(0xFFB0B4BA),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      isArabic ? 'أنت على اطلاع دائم!' : 'You are up to date!',
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        fontFamily: 'Gontserrat',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isArabic ? 'لا توجد إشعارات حالياً' : 'There are no notifications here.',
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 13,
                                        fontFamily: 'Gontserrat',
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final notif = items[index];
                                  final timeStr = _formatTimestamp(notif.createdAt, isArabic);

                                  return InkWell(
                                    onTap: () async {
                                      if (!notif.isRead) {
                                        cubit.markAsRead(notif.id);
                                      }
                                      if (notif.conversationId != null) {
                                        final res = await sl<IConversationRepository>()
                                            .getConversation(notif.conversationId!);
                                        res.fold(
                                          (_) {},
                                          (conv) {
                                            if (context.mounted) {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => ChatScreen(conversation: conv),
                                                ),
                                              );
                                            }
                                          },
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: notif.isRead
                                            ? Colors.transparent
                                            : (isDark ? AppColors.darkSurface : AppColors.brandSubtle.withValues(alpha: 0.3)),
                                        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Distinct colored icon circle matching the browser
                                          _buildNotificationBadge(notif.notificationType),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  notif.title ?? (isArabic ? 'إشعار جديد' : 'New Notification'),
                                                  style: TextStyle(
                                                    fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                                                    fontSize: 14,
                                                    color: textPrimary,
                                                    fontFamily: 'Gontserrat',
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  timeStr,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF80838D),
                                                    fontFamily: 'Gontserrat',
                                                  ),
                                                ),
                                                if (notif.message != null && notif.message!.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    notif.message!,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: textSecondary,
                                                      fontFamily: 'Gontserrat',
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (!notif.isRead)
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
                                },
                              ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabItem(String key, String label, bool isDark) {
    final active = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            fontFamily: 'Gontserrat',
            color: active
                ? AppColors.primary
                : (isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary),
          ),
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
        bg = const Color(0xFF2563EB); // Royal Blue
        icon = Icons.mark_email_unread_rounded;
        break;
      case 'message_created':
        bg = const Color(0xFF16A34A); // Green
        icon = Icons.chat_bubble_outline_rounded;
        break;
      case 'conversation_mention':
        bg = const Color(0xFF7C3AED); // Purple
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
