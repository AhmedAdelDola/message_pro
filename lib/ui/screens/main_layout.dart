import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notification_provider.dart';
import '../../providers/conversation_provider.dart';
import 'inbox/inbox_screen.dart';
import 'calls/calls_screen.dart';
import 'notifications/notifications_screen.dart';
import 'settings/settings_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    InboxScreen(),
    CallsScreen(),
    NotificationsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);
    final convState = ref.watch(conversationProvider);
    final unreadConvs = convState.conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
    final unreadNotifs = notificationState.unreadCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          indicatorColor: AppColors.primary.withValues(alpha: 0.15),
          elevation: 0,
          destinations: [
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unreadConvs > 0,
                label: Text('$unreadConvs'),
                child: const Icon(Icons.chat_bubble_outline_rounded),
              ),
              selectedIcon: Badge(
                isLabelVisible: unreadConvs > 0,
                label: Text('$unreadConvs'),
                child: const Icon(Icons.chat_bubble_rounded, color: AppColors.primaryLight),
              ),
              label: 'المحادثات',
            ),
            const NavigationDestination(
              icon: Icon(Icons.call_outlined),
              selectedIcon: Icon(Icons.call_rounded, color: AppColors.primaryLight),
              label: 'المكالمات',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unreadNotifs > 0,
                label: Text('$unreadNotifs'),
                child: const Icon(Icons.notifications_none_rounded),
              ),
              selectedIcon: Badge(
                isLabelVisible: unreadNotifs > 0,
                label: Text('$unreadNotifs'),
                child: const Icon(Icons.notifications_rounded, color: AppColors.primaryLight),
              ),
              label: 'الإشعارات',
            ),
            const NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primaryLight),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}
