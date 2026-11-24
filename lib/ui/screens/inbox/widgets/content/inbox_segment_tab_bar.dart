import 'package:flutter/material.dart';
import 'package:message_pro/core/constants/app_colors.dart';

class InboxSegmentTabBar extends StatelessWidget {
  final String activeSegment;
  final ValueChanged<String> onSegmentChanged;
  final bool isDark;
  final bool isArabic;

  const InboxSegmentTabBar({
    super.key,
    required this.activeSegment,
    required this.onSegmentChanged,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final segmentContainerBg = isDark ? const Color(0xFF1E2024) : const Color(0xFFF1F2F4);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: segmentContainerBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildSegmentTab('all', isArabic ? 'الكل' : 'All'),
          _buildSegmentTab('mine', isArabic ? 'خاصتي' : 'Mine'),
          _buildSegmentTab('collaborating', isArabic ? 'المتعاونة' : 'Collaborating'),
          _buildSegmentTab('unassigned', isArabic ? 'غير معينة' : 'Unassigned'),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(String key, String label) {
    final isSelected = activeSegment == key;

    return Expanded(
      child: InkWell(
        onTap: () => onSegmentChanged(key),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF2C2E33) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
