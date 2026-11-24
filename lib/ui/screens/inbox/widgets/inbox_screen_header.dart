import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/constants/app_colors.dart';
import 'header/inbox_search_bar.dart';
import 'header/inbox_drawer_button.dart';
import 'header/inbox_workspace_button.dart';

/// Clean header for the Inbox screen.
/// Follows Single Responsibility Principle by orchestrating the Search Bar,
/// Drawer Button, Workspace Selector, and Header Action Buttons.
class InboxScreenHeader extends StatelessWidget {
  final bool isSearching;
  final TextEditingController searchController;
  final VoidCallback onOpenDrawer;
  final VoidCallback onWorkspacesTap;
  final VoidCallback onAddContactTap;
  final VoidCallback onStartSearch;
  final VoidCallback onCloseSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  const InboxScreenHeader({
    super.key,
    required this.isSearching,
    required this.searchController,
    required this.onOpenDrawer,
    required this.onWorkspacesTap,
    required this.onAddContactTap,
    required this.onStartSearch,
    required this.onCloseSearch,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return InboxSearchBar(
        searchController: searchController,
        onSearchChanged: onSearchChanged,
        onClearSearch: onClearSearch,
        onCloseSearch: onCloseSearch,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InboxDrawerButton(onTap: onOpenDrawer),
              const SizedBox(width: 8),
              InboxWorkspaceButton(onTap: onWorkspacesTap),
              const SizedBox(width: 10),
              // "Chats" tab with active blue underline indicator
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'المحادثات' : 'Chats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: isArabic ? 55 : 44,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: HugeIcon(icon: HugeIcons.strokeRoundedUserAdd01, color: textPrimary, size: 21),
                tooltip: isArabic ? 'جهة اتصال جديدة' : 'New Contact',
                onPressed: onAddContactTap,
              ),
              IconButton(
                icon: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: textPrimary, size: 21),
                tooltip: isArabic ? 'بحث' : 'Search',
                onPressed: onStartSearch,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
