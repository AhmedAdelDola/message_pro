import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/constants/app_svg_icons.dart';
import '../../logic/conversation/conversation_cubit.dart';
import '../../logic/conversation/conversation_state.dart';
import '../../logic/notification/notification_cubit.dart';
import '../../logic/notification/notification_state.dart';
import 'notifications/notifications_screen.dart';
import 'inbox/inbox_screen.dart';
import 'calls/calls_screen.dart';
import 'settings/settings_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Inbox is initial tab (index 1), matching C:\crm AppTabs.tsx
  int _currentIndex = 1;

  final List<Widget> _screens = const [
    NotificationsScreen(),
    InboxScreen(),
    CallsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAFAFA);
    final borderColor = isDark ? const Color(0xFF212121) : const Color(0xFFEAEAEA);
    const activeColor = Color(0xFF4162E3);
    const inactiveColor = Color(0xFF80838D);

    return BlocBuilder<ConversationCubit, ConversationState>(
      buildWhen: (prev, curr) => prev.conversations != curr.conversations,
      builder: (context, convState) {
        final unreadConvs = convState.conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

        return BlocBuilder<NotificationCubit, NotificationState>(
          buildWhen: (prev, curr) => prev.notifications != curr.notifications,
          builder: (context, notifState) {
            final unreadNotifs = notifState.unreadCount;

            return Scaffold(
              backgroundColor: bgColor,
              body: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border(
                    top: BorderSide(color: borderColor, width: 1),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTabItem(
                          index: 0,
                          label: isRTL ? 'الإشعارات' : 'Notifications',
                          iconBuilder: (color) => HugeIcon(icon: HugeIcons.strokeRoundedNotification01, color: color, size: 22),
                          badgeCount: unreadNotifs,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                        _buildTabItem(
                          index: 1,
                          label: isRTL ? 'المحادثات' : 'Inbox',
                          iconBuilder: (color) => HugeIcon(icon: HugeIcons.strokeRoundedBubbleChat, color: color, size: 22),
                          badgeCount: unreadConvs,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                        _buildTabItem(
                          index: 2,
                          label: isRTL ? 'المكالمات' : 'Calls',
                          iconBuilder: (color) => HugeIcon(icon: HugeIcons.strokeRoundedCall, color: color, size: 22),
                          badgeCount: 0,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                        _buildTabItem(
                          index: 3,
                          label: isRTL ? 'الإعدادات' : 'Settings',
                          iconBuilder: (color) => HugeIcon(icon: HugeIcons.strokeRoundedSettings01, color: color, size: 22),
                          badgeCount: 0,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabItem({
    required int index,
    required String label,
    required Widget Function(Color color) iconBuilder,
    required int badgeCount,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isFocused = _currentIndex == index;
    final itemColor = isFocused ? activeColor : inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: iconBuilder(itemColor),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2CA54A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Gontserrat',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'Gontserrat',
                  color: itemColor,
                  fontWeight: isFocused ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
