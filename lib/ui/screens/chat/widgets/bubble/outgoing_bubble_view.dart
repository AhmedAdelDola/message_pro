import 'package:flutter/material.dart';
import '../../../../../core/services/link_preview_service.dart';
import '../../../../../data/models/message.dart';
import '../clickable_text_with_links.dart';
import '../link_preview_card.dart';
import 'bubble_ad_referral_card.dart';
import 'bubble_attachments_view.dart';
import 'bubble_delivery_status.dart';
import 'bubble_helpers.dart';
import 'bubble_platform_badge.dart';
import 'bubble_quoted_preview.dart';
import 'bubble_reactions_pill.dart';
import 'interactive_action_buttons.dart';

class OutgoingBubbleView extends StatelessWidget {
  final Message message;
  final Message? repliedMessage;
  final bool isDark;
  final bool isArabic;
  final String? channel;
  final VoidCallback? onRetry;
  final ValueChanged<int>? onScrollToMessage;
  final ValueChanged<Message>? onViewReactions;

  const OutgoingBubbleView({
    super.key,
    required this.message,
    this.repliedMessage,
    required this.isDark,
    required this.isArabic,
    this.channel,
    this.onRetry,
    this.onScrollToMessage,
    this.onViewReactions,
  });

  @override
  Widget build(BuildContext context) {
    final isFailed = message.isFailed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: ExternalStatusIndicator(
                  message: message,
                  onRetry: onRetry,
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.74,
                ),
                child: Container(
                  padding:
                      (message.referral != null && message.referral!.hasContent)
                      ? const EdgeInsets.fromLTRB(6, 6, 6, 8)
                      : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isFailed
                        ? (isDark
                              ? const Color(0xFF3B181E)
                              : const Color(0xFFDC2626))
                        : const Color(0xFF4162E3),
                    border: isFailed
                        ? Border.all(color: const Color(0xFFFCA5A5), width: 1.2)
                        : null,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(4),
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
                              const Icon(
                                Icons.block_rounded,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isArabic
                                    ? 'تم حذف هذه الرسالة'
                                    : 'This message was deleted',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white70,
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
                              isOutgoing: true,
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
                              isOutgoing: true,
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
                                  isOutgoing: true,
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
                                  textStyle: const TextStyle(
                                    fontSize: 14.5,
                                    height: 1.35,
                                    color: Colors.white,
                                  ),
                                  linkStyle: const TextStyle(
                                    fontSize: 14.5,
                                    height: 1.35,
                                    color: Color(0xFFBAE6FD),
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFFBAE6FD),
                                  ),
                                );
                              },
                            ),
                          ],

                          if (message.hasInteractiveButtons) ...[
                            const SizedBox(height: 8),
                            InteractiveActionButtons(
                              buttons: message.templateActionButtons,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.white.withValues(alpha: 0.92),
                              borderColor: isDark
                                  ? Colors.white.withValues(alpha: 0.18)
                                  : Colors.white.withValues(alpha: 0.65),
                              foregroundColor: isDark
                                  ? const Color(0xFFBAE6FD)
                                  : const Color(0xFF2563EB),
                            ),
                          ],

                          if (isFailed) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    message.failureReason ?? 'فشل الإرسال',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
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
                                    color: Color(0x99FFFFFF),
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
                                  color: Color(0xBFFFFFFF),
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
              const SizedBox(width: 6),
              OutgoingSenderBadge(message: message, channel: channel),
            ],
          ),
          if (message.reactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 32),
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
