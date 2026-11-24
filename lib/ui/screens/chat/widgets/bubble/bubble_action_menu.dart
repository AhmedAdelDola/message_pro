import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/services/haptic_service.dart';
import '../../../../../data/models/message.dart';
import '../../../../../data/models/user.dart';

void showBubbleActionMenu({
  required BuildContext context,
  required Message message,
  required User? currentUser,
  ValueChanged<Message>? onReply,
  ValueChanged<Message>? onEditMessage,
  ValueChanged<Message>? onDeleteMessage,
  void Function(Message message, String emoji)? onReact,
  VoidCallback? onRetry,
}) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textToCopy = message.cleanContent;

  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? const Color(0xFF161616) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF31343A) : const Color(0xFFEAEAEA),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (message.canReact) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF383838) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final emoji in ['👍', '❤️', '😂', '😮', '😢', '🙏'])
                    GestureDetector(
                      onTap: () {
                        HapticService.lightImpact();
                        Navigator.pop(ctx);
                        onReact?.call(message, emoji);
                      },
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  GestureDetector(
                    onTap: () {
                      HapticService.lightImpact();
                      Navigator.pop(ctx);
                      onReact?.call(message, '');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF383838) : const Color(0xFFE2E8F0),
                      ),
                      child: Icon(
                        Icons.block_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (message.canEditBy(currentUser) && onEditMessage != null)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_rounded, color: Color(0xFFF59E0B), size: 20),
              ),
              title: Text(
                isArabic ? 'تعديل الرسالة' : 'Edit Message',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: message.messageActions.remainingEditTime != null
                  ? Text(
                      isArabic
                          ? 'متبقي ${message.messageActions.remainingEditTime!.inMinutes} دقيقة للتعديل'
                          : '${message.messageActions.remainingEditTime!.inMinutes}m left to edit',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B)),
                    )
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                onEditMessage.call(message);
              },
            ),
          if (message.canDeleteBy(currentUser) && onDeleteMessage != null)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
              ),
              title: Text(
                isArabic ? 'حذف لدى الجميع' : 'Delete for everyone',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
              ),
              subtitle: message.messageActions.remainingDeleteTime != null
                  ? Text(
                      isArabic
                          ? 'متبقي ${_formatRemainingTime(message.messageActions.remainingDeleteTime!, isArabic)} للحذف'
                          : '${_formatRemainingTime(message.messageActions.remainingDeleteTime!, isArabic)} left to delete',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
                    )
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                onDeleteMessage.call(message);
              },
            ),
          if (onReply != null && !message.isDeleted)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4162E3).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.reply_rounded, color: Color(0xFF4162E3), size: 20),
              ),
              title: Text(
                isArabic ? 'رد على الرسالة' : 'Reply',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onReply.call(message);
              },
            ),
          if (textToCopy.isNotEmpty && !message.isDeleted)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.copy_rounded, color: Color(0xFF10B981), size: 20),
              ),
              title: Text(
                isArabic ? 'نسخ نص الرسالة' : 'Copy Message Text',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await Clipboard.setData(ClipboardData(text: textToCopy));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic ? 'تم نسخ نص الرسالة إلى الحافظة' : 'Message copied to clipboard',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          if (message.attachments.isNotEmpty)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.link_rounded, color: Color(0xFF8B5CF6), size: 20),
              ),
              title: Text(
                isArabic ? 'نسخ رابط المرفق' : 'Copy Attachment Link',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final url = message.attachments.first.dataUrl;
                await Clipboard.setData(ClipboardData(text: url));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic ? 'تم نسخ رابط المرفق إلى الحافظة' : 'Attachment link copied to clipboard',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          if (message.isFailed && onRetry != null)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.refresh_rounded, color: Color(0xFFEF4444), size: 20),
              ),
              title: Text(
                isArabic ? 'إعادة الإرسال' : 'Retry Sending',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onRetry.call();
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

String _formatRemainingTime(Duration duration, bool isArabic) {
  if (duration.inHours >= 1) {
    final hours = duration.inHours;
    return isArabic ? '$hours ساعة' : '${hours}h';
  }
  final minutes = duration.inMinutes;
  return isArabic ? '$minutes دقيقة' : '${minutes}m';
}
