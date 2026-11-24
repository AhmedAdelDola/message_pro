import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/conversation.dart';

class ConversationActionSheet extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onToggleResolve;
  final VoidCallback onSnooze;
  final VoidCallback onToggleMute;
  final VoidCallback onTogglePin;

  const ConversationActionSheet({
    super.key,
    required this.conversation,
    required this.onToggleResolve,
    required this.onSnooze,
    required this.onToggleMute,
    required this.onTogglePin,
  });

  static Future<void> show({
    required BuildContext context,
    required Conversation conversation,
    required VoidCallback onToggleResolve,
    required VoidCallback onSnooze,
    required VoidCallback onToggleMute,
    required VoidCallback onTogglePin,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ConversationActionSheet(
        conversation: conversation,
        onToggleResolve: onToggleResolve,
        onSnooze: onSnooze,
        onToggleMute: onToggleMute,
        onTogglePin: onTogglePin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          // Pin / Unpin
          _buildActionRow(
            icon: Transform.rotate(
              angle: 0.5,
              child: Icon(
                conversation.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                color: conversation.isPinned ? AppColors.primary : textPrimary,
              ),
            ),
            label: conversation.isPinned
                ? (isArabic ? 'إلغاء تثبيت المحادثة' : 'Unpin Conversation')
                : (isArabic ? 'تثبيت المحادثة في الأعلى' : 'Pin Conversation'),
            textColor: conversation.isPinned ? AppColors.primary : textPrimary,
            borderColor: borderColor,
            onTap: () {
              Navigator.pop(context);
              onTogglePin();
            },
          ),
          // Resolve / Reopen
          _buildActionRow(
            icon: Icon(
              Icons.check_circle_outline_rounded,
              color: conversation.status == 'resolved' ? AppColors.success : textPrimary,
            ),
            label: conversation.status == 'resolved'
                ? (isArabic ? 'إعادة فتح المحادثة' : 'Reopen Conversation')
                : (isArabic ? 'إغلاق المحادثة' : 'Close Conversation'),
            textColor: conversation.status == 'resolved' ? AppColors.success : textPrimary,
            borderColor: borderColor,
            onTap: () {
              Navigator.pop(context);
              onToggleResolve();
            },
          ),
          // Snooze
          _buildActionRow(
            icon: Icon(Icons.access_time_rounded, color: textPrimary),
            label: isArabic ? 'تأجيل المحادثة' : 'Snooze Conversation',
            textColor: textPrimary,
            borderColor: borderColor,
            onTap: () {
              Navigator.pop(context);
              onSnooze();
            },
          ),
          // Mute / Unmute
          _buildActionRow(
            icon: Icon(
              conversation.muted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
              color: conversation.muted ? AppColors.success : textPrimary,
            ),
            label: conversation.muted
                ? (isArabic ? 'إلغاء كتم المحادثة' : 'Unmute Conversation')
                : (isArabic ? 'كتم المحادثة (Mute)' : 'Mute Conversation'),
            textColor: conversation.muted ? AppColors.success : textPrimary,
            borderColor: borderColor,
            onTap: () {
              Navigator.pop(context);
              onToggleMute();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required Widget icon,
    required String label,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
