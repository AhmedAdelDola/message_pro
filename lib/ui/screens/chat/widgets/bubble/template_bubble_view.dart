import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../data/models/message.dart';
import '../../../../../data/models/message_template_registry.dart';
import '../clickable_text_with_links.dart';
import 'bubble_ad_referral_card.dart';
import 'bubble_delivery_status.dart';
import 'bubble_helpers.dart';
import 'bubble_platform_badge.dart';
import 'interactive_action_buttons.dart';
import 'bubble_quoted_preview.dart';

class TemplateBubbleView extends StatelessWidget {
  final Message message;
  final Message? repliedMessage;
  final bool isDark;
  final bool isArabic;
  final String? channel;
  final VoidCallback? onRetry;
  final ValueChanged<int>? onScrollToMessage;

  const TemplateBubbleView({
    super.key,
    required this.message,
    this.repliedMessage,
    required this.isDark,
    required this.isArabic,
    this.channel,
    this.onRetry,
    this.onScrollToMessage,
  });

  Widget _buildCopyButton(BuildContext context) {
    final textToCopy = message.content ?? '';
    if (textToCopy.isEmpty) return const SizedBox.shrink();

    return Tooltip(
      message: 'نسخ الرسالة',
      child: InkWell(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: textToCopy));
          if (context.mounted) {
            final isAr = Localizations.localeOf(context).languageCode == 'ar';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isAr ? 'تم نسخ الرسالة إلى الحافظة' : 'Message copied to clipboard',
                  style: const TextStyle(fontSize: 12),
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          margin: const EdgeInsets.only(right: 6, bottom: 4),
          padding: const EdgeInsets.all(4.5),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF26262B)
                : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF3F3F46)
                  : const Color(0xFFD1D5DB),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            Icons.copy_rounded,
            size: 13,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFailed = message.isFailed;

    final Color bubbleBg;
    final Color borderColor;
    final Color buttonBg;
    final Color buttonBorder;
    final Color titleColor;

    if (isFailed) {
      bubbleBg = isDark ? const Color(0xFF2B161B) : const Color(0xFFFEF2F2);
      borderColor = isDark ? const Color(0xFF4A1D24) : const Color(0xFFFCA5A5);
      buttonBg = isDark ? const Color(0xFF22171B) : const Color(0xFFFFF5F5);
      buttonBorder = isDark ? const Color(0xFF4A1F26) : const Color(0xFFF3C5C5);
      titleColor = isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B);
    } else {
      bubbleBg = isDark ? const Color(0xFF131D2D) : const Color(0xFFEFF6FF);
      borderColor = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBFDBFE);
      buttonBg = isDark ? const Color(0xFF182235) : const Color(0xFFF8FAFC);
      buttonBorder = isDark ? const Color(0xFF283E66) : const Color(0xFFDBEAFE);
      titleColor = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF1E293B);
    }

    final headerBadgeColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final textColor = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF1C1917);
    final footerColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    final tName = message.templateName ?? (isArabic ? 'رسالة قالب' : 'Template message');
    final template = MessageTemplateRegistry.find(message.templateName);
    final actionButtons = message.templateActionButtons;

    String? headerText = template?.header;
    String? footerText = template?.footer;
    String bodyText = message.cleanContent;

    if (headerText != null && headerText.isNotEmpty && bodyText.startsWith(headerText)) {
      bodyText = bodyText.substring(headerText.length).trim();
    } else if (headerText == null && bodyText.contains('\n\n')) {
      final firstLine = bodyText.split('\n\n').first.trim();
      if (firstLine.length < 50 && !firstLine.contains('👋') && !firstLine.contains('*')) {
        headerText = firstLine;
        bodyText = bodyText.substring(firstLine.length).trim();
      }
    }

    if (footerText != null && footerText.isNotEmpty && bodyText.endsWith(footerText)) {
      bodyText = bodyText.substring(0, bodyText.length - footerText.length).trim();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildCopyButton(context),
              const SizedBox(height: 8),
              ExternalStatusIndicator(message: message, onRetry: onRetry),
              const SizedBox(height: 4),
            ],
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.74,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: bubbleBg,
                border: Border.all(color: borderColor, width: 1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (repliedMessage != null || message.inReplyToId != null)
                    BubbleQuotedPreview(
                      repliedMessage: repliedMessage,
                      inReplyToId: message.inReplyToId,
                      isDark: isDark,
                      isArabic: isArabic,
                      isOutgoing: true,
                      onScrollToMessage: onScrollToMessage,
                    ),
                  if (message.referral != null) ...[
                    BubbleAdReferralCard(
                      referral: message.referral!,
                      messageContent: message.content,
                      isDark: isDark,
                      isArabic: isArabic,
                    ),
                    const SizedBox(height: 6),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: headerBadgeColor, width: 1.1),
                          ),
                          child: Text(
                            'B',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: headerBadgeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Template message | $tName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: headerBadgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderColor.withValues(alpha: 0.7)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (headerText != null && headerText.isNotEmpty) ...[
                          Builder(
                            builder: (context) {
                              final isAr = BubbleHelpers.isArabicText(headerText!);
                              return Align(
                                alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                                child: Text(
                                  headerText,
                                  textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                                  textAlign: isAr ? TextAlign.right : TextAlign.left,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: titleColor,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (bodyText.isNotEmpty)
                          ClickableTextWithLinks(
                            text: bodyText,
                            textDirection: BubbleHelpers.isArabicText(bodyText) ? TextDirection.rtl : TextDirection.ltr,
                            textAlign: BubbleHelpers.isArabicText(bodyText) ? TextAlign.right : TextAlign.left,
                            textStyle: TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: textColor,
                            ),
                          ),
                        if (footerText != null && footerText.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Divider(height: 1, color: borderColor.withValues(alpha: 0.6)),
                          const SizedBox(height: 6),
                          Text(
                            footerText,
                            style: TextStyle(
                              fontSize: 11,
                              color: footerColor,
                            ),
                          ),
                        ],
                        if (actionButtons.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          InteractiveActionButtons(
                            buttons: actionButtons,
                            backgroundColor: buttonBg,
                            borderColor: buttonBorder,
                          ),
                        ],
                        if (message.isFailed) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFFCA5A5),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    message.failureReason ?? 'فشل في إرسال الرسالة',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          OutgoingSenderBadge(message: message, channel: channel),
        ],
      ),
    );
  }
}
