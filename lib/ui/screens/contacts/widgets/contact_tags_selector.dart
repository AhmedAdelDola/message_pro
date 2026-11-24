import 'package:flutter/material.dart';
import 'package:message_pro/core/constants/app_colors.dart';

class ContactTagsSelector extends StatelessWidget {
  final List<String> availableTags;
  final List<String> selectedTags;
  final ValueChanged<String> onTagToggled;
  final VoidCallback onAddCustomTagTap;
  final String label;

  const ContactTagsSelector({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.onTagToggled,
    required this.onAddCustomTagTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final allTags = {...availableTags, ...selectedTags}.toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              InkWell(
                onTap: onAddCustomTagTap,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'إضافة وسم',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (allTags.isEmpty)
            Text(
              'لا توجد وسوم متاحة',
              style: TextStyle(color: textSecondary.withValues(alpha: 0.6), fontSize: 13),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: allTags.map((tag) {
                final isSelected = selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (_) => onTagToggled(tag),
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary),
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: isDark ? const Color(0xFF1E2024) : Colors.white,
                  side: BorderSide(color: isSelected ? AppColors.primary : borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
