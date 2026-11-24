import 'package:flutter/material.dart';
import '../../../../../data/models/message.dart';

class ComposerReplyBanner extends StatelessWidget {
  final Message? replyingToMessage;
  final bool isDark;
  final bool isArabic;
  final VoidCallback? onCancelReply;

  const ComposerReplyBanner({
    super.key,
    required this.replyingToMessage,
    required this.isDark,
    required this.isArabic,
    this.onCancelReply,
  });

  @override
  Widget build(BuildContext context) {
    final msg = replyingToMessage;
    if (msg == null) return const SizedBox.shrink();

    final isSenderMe = msg.isOutgoing;
    final senderName = isSenderMe
        ? (isArabic ? 'أنت' : 'You')
        : (msg.senderName ?? (isArabic ? 'العميل' : 'Customer'));

    String contentPreview = '';
    if (msg.content != null && msg.content!.trim().isNotEmpty) {
      contentPreview = msg.content!.trim();
    } else if (msg.attachments.isNotEmpty) {
      final type = msg.attachments.first.fileType.toLowerCase();
      if (type == 'image') {
        contentPreview = isArabic ? '📷 صورة' : '📷 Photo';
      } else if (type == 'video') {
        contentPreview = isArabic ? '🎥 فيديو' : '🎥 Video';
      } else if (type == 'audio') {
        contentPreview = isArabic ? '🎵 تسجيل صوتي' : '🎵 Audio';
      } else {
        contentPreview = isArabic ? '📎 ملف مرفق' : '📎 Attachment';
      }
    } else {
      contentPreview = isArabic ? 'رسالة' : 'Message';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2128) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          right: isArabic
              ? const BorderSide(color: Color(0xFF4162E3), width: 3.5)
              : BorderSide.none,
          left: !isArabic
              ? const BorderSide(color: Color(0xFF4162E3), width: 3.5)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.reply_rounded,
            size: 18,
            color: Color(0xFF4162E3),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isArabic ? 'الرد على' : 'Replying to'} $senderName',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4162E3),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contentPreview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: isArabic ? 'إلغاء الرد' : 'Cancel reply',
            onPressed: onCancelReply,
          ),
        ],
      ),
    );
  }
}
