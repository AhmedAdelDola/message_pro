import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/logic/conversation/conversation_cubit.dart';
import 'package:message_pro/logic/notification/notification_cubit.dart';
import 'package:message_pro/logic/notification/notification_state.dart';
import 'package:message_pro/ui/screens/chat/chat_screen.dart';
import 'package:message_pro/ui/widgets/app_bar_progress_bar.dart';
import 'package:message_pro/ui/widgets/empty_state_widget.dart';
import 'widgets/notification_tile.dart';
import 'widgets/notification_tab_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'new';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;

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
                        ),
                      ),
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
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                LinearHeaderLoader(isLoading: state.isLoading),
                NotificationTabBar(
                  selectedFilter: _selectedFilter,
                  onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => cubit.loadNotifications(),
                    child: state.isLoading && items.isEmpty
                        ? const SizedBox.shrink()
                        : items.isEmpty
                            ? EmptyStateWidget(
                                lottieAsset: 'assets/animations/empty_notifications.json',
                                title: isArabic ? 'أنت على اطلاع دائم!' : 'You are up to date!',
                                description: isArabic ? 'لا توجد إشعارات حالياً' : 'There are no notifications here.',
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final notif = items[index];
                                  return NotificationTile(
                                    notification: notif,
                                    onTap: () async {
                                      if (!notif.isRead) {
                                        cubit.markAsRead(notif.id);
                                      }
                                      if (notif.conversationId != null) {
                                        final res = await context
                                            .read<ConversationCubit>()
                                            .getConversation(notif.conversationId!);
                                        res.fold((_) {}, (conv) {
                                          if (context.mounted) {
                                            try {
                                              context.read<ConversationCubit>().markConversationAsRead(conv.id);
                                            } catch (_) {}
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => ChatScreen(conversation: conv.copyWith(unreadCount: 0)),
                                              ),
                                            );
                                          }
                                        });
                                      }
                                    },
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
}
