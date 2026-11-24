import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'modal/modal_radio_row.dart';

/// Clean dialog for changing conversation status and sorting order.
class FilterDropdownModal extends StatelessWidget {
  final String selectedStatus;
  final String sortBy;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onAdvancedFiltersTap;

  const FilterDropdownModal({
    super.key,
    required this.selectedStatus,
    required this.sortBy,
    required this.onStatusChanged,
    required this.onSortChanged,
    required this.onAdvancedFiltersTap,
  });

  static Future<void> show({
    required BuildContext context,
    required String selectedStatus,
    required String sortBy,
    required ValueChanged<String> onStatusChanged,
    required ValueChanged<String> onSortChanged,
    required VoidCallback onAdvancedFiltersTap,
  }) {
    return showDialog(
      context: context,
      builder: (_) => FilterDropdownModal(
        selectedStatus: selectedStatus,
        sortBy: sortBy,
        onStatusChanged: onStatusChanged,
        onSortChanged: onSortChanged,
        onAdvancedFiltersTap: onAdvancedFiltersTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark
        ? AppColors.textLightPrimary
        : AppColors.textDarkPrimary;
    final textSecondary = isDark
        ? AppColors.textLightSecondary
        : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'عرض' : 'Show',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            ModalRadioRow(
              label: isArabic ? 'جميع المحادثات' : 'All conversations',
              value: 'all',
              groupValue: selectedStatus,
              onChanged: onStatusChanged,
              textPrimary: textPrimary,
            ),
            ModalRadioRow(
              label: isArabic ? 'المحادثات المفتوحة' : 'Open conversations',
              value: 'open',
              groupValue: selectedStatus,
              onChanged: onStatusChanged,
              textPrimary: textPrimary,
            ),
            ModalRadioRow(
              label: isArabic ? 'المحادثات المغلقة' : 'Closed conversations',
              value: 'closed',
              groupValue: selectedStatus,
              onChanged: onStatusChanged,
              textPrimary: textPrimary,
            ),
            ModalRadioRow(
              label: isArabic ? 'المحادثات المؤجلة' : 'Snoozed conversations',
              value: 'snoozed',
              groupValue: selectedStatus,
              onChanged: onStatusChanged,
              textPrimary: textPrimary,
            ),
            const SizedBox(height: 14),
            Text(
              isArabic ? 'الترتيب حسب' : 'Sort by',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            ModalRadioRow(
              label: isArabic ? 'الأحدث' : 'Newest',
              value: 'newest',
              groupValue: sortBy,
              onChanged: onSortChanged,
              textPrimary: textPrimary,
            ),
            ModalRadioRow(
              label: isArabic ? 'الأقدم' : 'Oldest',
              value: 'oldest',
              groupValue: sortBy,
              onChanged: onSortChanged,
              textPrimary: textPrimary,
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                onAdvancedFiltersTap();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  isArabic ? 'تصفية متقدمة' : 'Advanced filters',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
