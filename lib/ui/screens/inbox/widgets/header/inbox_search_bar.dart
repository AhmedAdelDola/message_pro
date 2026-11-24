import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../core/constants/app_colors.dart';

class InboxSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onCloseSearch;

  const InboxSearchBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onCloseSearch,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inputBg = isDark ? AppColors.darkSurface : const Color(0xFFF1F2F4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: isArabic ? 'بحث في المحادثات...' : 'Search conversations...',
                        hintStyle: TextStyle(
                          color: textSecondary.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: onSearchChanged,
                    ),
                  ),
                  if (searchController.text.isNotEmpty)
                    InkWell(
                      onTap: onClearSearch,
                      child: Icon(Icons.close_rounded, size: 18, color: textSecondary),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.close_rounded, color: textPrimary, size: 22),
            onPressed: onCloseSearch,
          ),
        ],
      ),
    );
  }
}
