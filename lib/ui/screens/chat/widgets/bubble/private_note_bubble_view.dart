import 'package:flutter/material.dart';
import '../../../../../core/services/link_preview_service.dart';
import '../../../../../data/models/message.dart';
import '../clickable_text_with_links.dart';
import '../link_preview_card.dart';
import 'bubble_helpers.dart';

class PrivateNoteBubbleView extends StatelessWidget {
  final Message message;
  final bool isDark;
  final bool isArabic;

  const PrivateNoteBubbleView({
    super.key,
    required this.message,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    // Reference C:\crm PrivateNote styling:
    // bgLight: #fffbeb, bgDark: #271904, borderLight: #fef08a, borderDark: #78350f, accent: #FA8900
    final bg = isDark ? const Color(0xFF271904) : const Color(0xFFFFFBEB);
    final border = isDark ? const Color(0xFF78350F) : const Color(0xFFFEF08A);
    const accent = Color(0xFFFA8900);
    final text = isDark ? const Color(0xFFFFE8CC) : const Color(0xFF78350F);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
            minWidth: 120,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: border, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded, size: 14, color: accent),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isArabic
                              ? 'ملاحظة خاصة • ${message.senderName ?? 'فريق العمل'}'
                              : 'Private Note • ${message.senderName ?? 'Team'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (message.isDeleted) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.block_rounded, size: 14, color: accent),
                        const SizedBox(width: 6),
                        Text(
                          isArabic ? 'تم حذف هذه الملاحظة' : 'This note was deleted',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: text.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ] else if (message.cleanContent.isNotEmpty) ...[
                    Builder(
                      builder: (context) {
                        final firstUrl = LinkPreviewService.extractFirstUrl(message.cleanContent);
                        if (firstUrl == null) return const SizedBox.shrink();
                        return LinkPreviewCard(
                          url: firstUrl,
                          isOutgoing: false,
                          isDark: isDark,
                        );
                      },
                    ),
                    Builder(
                      builder: (context) {
                        final isAr = BubbleHelpers.isArabicText(message.cleanContent);
                        return Align(
                          alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                          child: ClickableTextWithLinks(
                            text: message.cleanContent,
                            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                            textAlign: isAr ? TextAlign.right : TextAlign.left,
                            textStyle: TextStyle(
                              fontSize: 14,
                              height: 1.35,
                              color: text,
                            ),
                            linkStyle: const TextStyle(
                              fontSize: 14,
                              height: 1.35,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        BubbleHelpers.formatTime(message.createdAt, isArabic),
                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 10,
                          color: accent.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
