import 'package:flutter/material.dart';
import '../../../../../data/models/message.dart';

class BubbleQuotedPreview extends StatelessWidget {
  final Message? repliedMessage;
  final int? inReplyToId;
  final bool isDark;
  final bool isArabic;
  final bool isOutgoing;
  final ValueChanged<int>? onScrollToMessage;

  const BubbleQuotedPreview({
    super.key,
    this.repliedMessage,
    this.inReplyToId,
    required this.isDark,
    required this.isArabic,
    required this.isOutgoing,
    this.onScrollToMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (repliedMessage == null && inReplyToId == null) return const SizedBox.shrink();

    final replied = repliedMessage;
    final isSenderMe = replied?.isOutgoing ?? false;
    final senderName = replied != null
        ? (isSenderMe ? (isArabic ? 'أنت' : 'You') : (replied.senderName ?? (isArabic ? 'العميل' : 'Customer')))
        : (isArabic ? 'رسالة سابقة' : 'Previous Message');

    String snippet = '';
    if (replied != null && replied.isDeleted) {
      snippet = isArabic ? 'تم حذف هذه الرسالة' : 'This message was deleted';
    } else if (replied != null && replied.cleanContent.isNotEmpty) {
      snippet = replied.cleanContent;
    } else if (replied != null && replied.attachments.isNotEmpty) {
      final type = replied.attachments.first.fileType.toLowerCase();
      if (type == 'image') {
        snippet = isArabic ? '📷 صورة' : '📷 Photo';
      } else if (type == 'video') {
        snippet = isArabic ? '🎥 فيديو' : '🎥 Video';
      } else if (type == 'audio') {
        snippet = isArabic ? '🎵 تسجيل صوتي' : '🎵 Audio';
      } else {
        snippet = isArabic ? '📎 ملف مرفق' : '📎 Attachment';
      }
    } else {
      snippet = isArabic ? 'رسالة سابقة' : 'Previous message';
    }

    final barColor = isOutgoing
        ? Colors.white.withValues(alpha: 0.85)
        : const Color(0xFF4162E3);
    final bgColor = isOutgoing
        ? Colors.black.withValues(alpha: 0.15)
        : (isDark ? const Color(0xFF26262B) : const Color(0xFFF1F5F9));
    final titleColor = isOutgoing
        ? Colors.white
        : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB));
    final bodyColor = isOutgoing
        ? Colors.white.withValues(alpha: 0.8)
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

    final targetId = replied?.id ?? inReplyToId;

    return GestureDetector(
      onTap: () {
        if (targetId != null && onScrollToMessage != null) {
          onScrollToMessage!(targetId);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border(
            right: isArabic ? BorderSide(color: barColor, width: 3.5) : BorderSide.none,
            left: !isArabic ? BorderSide(color: barColor, width: 3.5) : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              senderName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              snippet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              style: TextStyle(
                fontSize: 12,
                color: bodyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
