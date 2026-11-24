import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/conversation.dart';

class ConversationTileHeader extends StatelessWidget {
  final Conversation conversation;
  final String displayName;
  final String formattedTime;
  final bool isArabic;
  final bool isDark;

  const ConversationTileHeader({
    super.key,
    required this.conversation,
    required this.displayName,
    required this.formattedTime,
    required this.isArabic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final isClosed = conversation.status == 'resolved' || conversation.status == 'closed';
    final isSnoozed = conversation.status == 'snoozed' || conversation.snoozedUntil != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              if (isClosed) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
              if (isSnoozed) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFA8900).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFFFA8900).withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.snooze_rounded, size: 11, color: Color(0xFFFA8900)),
                      const SizedBox(width: 3),
                      Text(
                        isArabic ? 'مؤجلة' : 'Snoozed',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFA8900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (conversation.muted) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.notifications_off_rounded,
                  size: 13,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (conversation.isPinned) ...[
          Transform.rotate(
            angle: 0.5,
            child: Icon(
              Icons.push_pin_rounded,
              size: 15,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          formattedTime,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF80838D),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
