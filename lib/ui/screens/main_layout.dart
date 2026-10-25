import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../logic/conversation/conversation_cubit.dart';
import '../../logic/conversation/conversation_state.dart';
import '../../logic/notification/notification_cubit.dart';
import '../../logic/notification/notification_state.dart';
import 'inbox/inbox_screen.dart';
import 'calls/calls_screen.dart';
import 'notifications/notifications_screen.dart';
import 'settings/settings_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    InboxScreen(),
    CallsScreen(),
    NotificationsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ConversationCubit, ConversationState>(
      buildWhen: (prev, curr) => prev.conversations != curr.conversations,
      builder: (context, convState) {
        final unreadConvs = convState.conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

        return BlocBuilder<NotificationCubit, NotificationState>(
          buildWhen: (prev, curr) => prev.notifications != curr.notifications,
          builder: (context, notifState) {
            final unreadNotifs = notifState.unreadCount;

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
                      width: 1.h,
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
                        label: Text('$unreadConvs', style: TextStyle(fontSize: 10.sp)),
                        child: Icon(Icons.chat_bubble_outline_rounded, size: 22.r),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible: unreadConvs > 0,
                        label: Text('$unreadConvs', style: TextStyle(fontSize: 10.sp)),
                        child: Icon(Icons.chat_bubble_rounded, color: AppColors.primaryLight, size: 22.r),
                      ),
                      label: 'المحادثات',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.call_outlined, size: 22.r),
                      selectedIcon: Icon(Icons.call_rounded, color: AppColors.primaryLight, size: 22.r),
                      label: 'المكالمات',
                    ),
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible: unreadNotifs > 0,
                        label: Text('$unreadNotifs', style: TextStyle(fontSize: 10.sp)),
                        child: Icon(Icons.notifications_none_rounded, size: 22.r),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible: unreadNotifs > 0,
                        label: Text('$unreadNotifs', style: TextStyle(fontSize: 10.sp)),
                        child: Icon(Icons.notifications_rounded, color: AppColors.primaryLight, size: 22.r),
                      ),
                      label: 'الإشعارات',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined, size: 22.r),
                      selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primaryLight, size: 22.r),
                      label: 'الإعدادات',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
