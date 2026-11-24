import 'package:flutter/material.dart';
import 'package:message_pro/core/constants/app_colors.dart';

class NotificationTabBar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const NotificationTabBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
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
    );
  }

  Widget _buildTabItem(String key, String label, bool isDark) {
    final active = selectedFilter == key;
    return InkWell(
      onTap: () => onFilterChanged(key),
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
            color: active
                ? AppColors.primary
                : (isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary),
          ),
        ),
      ),
    );
  }
}
