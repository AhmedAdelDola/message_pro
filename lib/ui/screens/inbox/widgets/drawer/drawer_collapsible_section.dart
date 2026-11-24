import 'package:flutter/material.dart';
import 'package:message_pro/core/constants/app_colors.dart';

class DrawerCollapsibleSection extends StatelessWidget {
  final String title;
  final IconData sectionIcon;
  final int count;
  final bool isExpanded;
  final bool hasActiveFilter;
  final VoidCallback onToggle;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final List<Widget> children;

  const DrawerCollapsibleSection({
    super.key,
    required this.title,
    required this.sectionIcon,
    required this.count,
    required this.isExpanded,
    required this.hasActiveFilter,
    required this.onToggle,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191A20) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasActiveFilter ? AppColors.primary : borderColor,
          width: hasActiveFilter ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: hasActiveFilter
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : (isDark ? const Color(0xFF22242B) : const Color(0xFFEAECEF)),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      sectionIcon,
                      size: 15,
                      color: hasActiveFilter ? AppColors.primary : textSecondary,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: hasActiveFilter ? AppColors.primary : textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: hasActiveFilter
                          ? AppColors.primary
                          : (isDark ? const Color(0xFF282A33) : const Color(0xFFE2E4E9)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: hasActiveFilter ? Colors.white : textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, thickness: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
