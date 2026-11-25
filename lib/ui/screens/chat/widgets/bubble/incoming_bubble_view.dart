import 'package:flutter/material.dart';
import '../../../../../core/services/link_preview_service.dart';
import '../../../../../data/models/message.dart';
import '../../../../widgets/avatar_widget.dart';
import '../clickable_text_with_links.dart';
import '../link_preview_card.dart';
import 'bubble_ad_referral_card.dart';
import 'bubble_attachments_view.dart';
import 'bubble_helpers.dart';
import 'bubble_quoted_preview.dart';
import 'bubble_reactions_pill.dart';

class IncomingBubbleView extends StatelessWidget {
  final Message message;
  final Message? repliedMessage;
  final String contactName;
  final String? contactThumbnail;
  final bool isDark;
  final bool isArabic;
  final ValueChanged<int>? onScrollToMessage;
  final ValueChanged<Message>? onViewReactions;

  const IncomingBubbleView({
    super.key,
    required this.message,
    this.repliedMessage,
    this.contactName = '',
    this.contactThumbnail,
    required this.isDark,
    required this.isArabic,
    this.onScrollToMessage,
    this.onViewReactions,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleBg = isDark ? const Color(0xFF161616) : Colors.white;
    final textColor = isDark
        ? const Color(0xFFFAFAFA)
        : const Color(0xFF0D0D0D);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AvatarWidget(
                avatarUrl: contactThumbnail,
                name: contactName,
                size: 28,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                child: Container(
                  padding:
                      (message.referral != null && message.referral!.hasContent)
                      ? const EdgeInsets.fromLTRB(6, 6, 6, 8)
                      : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: bubbleBg,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2C2D32)
                          : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.25 : 0.06,
                        ),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.isDeleted) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.block_rounded,
                                size: 14,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isArabic
                                    ? 'تم حذف هذه الرسالة'
                                    : 'This message was deleted',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontStyle: FontStyle.italic,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // Quoted Reply Preview
                          if (repliedMessage != null ||
                              message.inReplyToId != null)
                            BubbleQuotedPreview(
                              repliedMessage: repliedMessage,
                              inReplyToId: message.inReplyToId,
                              isDark: isDark,
                              isArabic: isArabic,
                              isOutgoing: false,
                              onScrollToMessage: onScrollToMessage,
                            ),

                          // Ad Referral Card (if message is from a Meta / WhatsApp Click-to-Chat ad)
                          if (message.referral != null &&
                              message.referral!.hasContent) ...[
                            BubbleAdReferralCard(
                              referral: message.referral!,
                              messageContent: message.cleanContent,
                              isDark: isDark,
                              isArabic: isArabic,
                            ),
                            const SizedBox(height: 6),
                          ],

                          // Attachments
                          if (message.attachments.isNotEmpty) ...[
                            BubbleAttachmentsView(
                              message: message,
                              isOutgoing: false,
                            ),
                            const SizedBox(height: 6),
                          ],

                          // Content & Link Preview
                          if (message.cleanContent.isNotEmpty) ...[
                            Builder(
                              builder: (context) {
                                final firstUrl =
                                    LinkPreviewService.extractFirstUrl(
                                      message.cleanContent,
                                    );
                                if (firstUrl == null) {
                                  return const SizedBox.shrink();
                                }
                                return LinkPreviewCard(
                                  url: firstUrl,
                                  isOutgoing: false,
                                  isDark: isDark,
                                );
                              },
                            ),
                            Builder(
                              builder: (context) {
                                final isAr = BubbleHelpers.isArabicText(
                                  message.cleanContent,
                                );
                                return ClickableTextWithLinks(
                                  text: message.cleanContent,
                                  textDirection: isAr
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  textAlign: isAr
                                      ? TextAlign.right
                                      : TextAlign.left,
                                  textStyle: TextStyle(
                                    fontSize: 14.5,
                                    height: 1.35,
                                    color: textColor,
                                  ),
                                  linkStyle: TextStyle(
                                    fontSize: 14.5,
                                    height: 1.35,
                                    color: isDark
                                        ? const Color(0xFF38BDF8)
                                        : const Color(0xFF2563EB),
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: isDark
                                        ? const Color(0xFF38BDF8)
                                        : const Color(0xFF2563EB),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],

                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (message.isEdited) ...[
                                Text(
                                  isArabic ? 'مُعدلة ' : 'Edited ',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF80838D),
                                  ),
                                ),
                                const SizedBox(width: 2),
                              ],
                              Text(
                                BubbleHelpers.formatTime(
                                  message.createdAt,
                                  isArabic,
                                ),
                                textDirection: isArabic
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF80838D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (message.reactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: BubbleReactionsPill(
                message: message,
                isDark: isDark,
                onViewReactions: onViewReactions,
              ),
            ),
        ],
      ),
    );
  }
}
