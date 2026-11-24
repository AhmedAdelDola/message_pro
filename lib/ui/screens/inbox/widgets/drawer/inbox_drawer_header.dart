import 'package:flutter/material.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/logic/conversation/conversation_cubit.dart';

class InboxDrawerHeader extends StatelessWidget {
  final bool isDark;
  final bool isArabic;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final bool hasActiveFilter;
  final ConversationCubit cubit;

  const InboxDrawerHeader({
    super.key,
    required this.isDark,
    required this.isArabic,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.hasActiveFilter,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16171D) : Colors.white,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.filter_list_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'تصفية المحادثات' : 'Filter Inbox',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Text(
                  isArabic ? 'اختر قناة أو موظف أو فريق' : 'By channel, agent, or team',
                  style: TextStyle(fontSize: 11.5, color: textSecondary),
                ),
              ],
            ),
          ),
          if (hasActiveFilter)
            TextButton(
              onPressed: () {
                cubit.clearAllFilters();
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Text(
                isArabic ? 'إعادة ضبط' : 'Reset',
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
