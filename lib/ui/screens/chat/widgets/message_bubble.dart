import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:message_pro/core/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/models/message.dart';
import '../../../../data/models/message_template_registry.dart';
import '../../../widgets/avatar_widget.dart';
import '../../../widgets/media_viewers/audio_player_bubble.dart';
import '../../../widgets/media_viewers/document_attachment_tile.dart';
import '../../../widgets/media_viewers/image_viewer_screen.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final String contactName;
  final String? contactThumbnail;
  final bool showDateHeader;
  final VoidCallback? onRetry;

  const MessageBubble({
    super.key,
    required this.message,
    this.contactName = '',
    this.contactThumbnail,
    this.showDateHeader = false,
    this.onRetry,
  });

  String _formatTime(DateTime dt, [bool isArabic = false]) {
    final hourMin = DateFormat('h:mm').format(dt);
    final amPm = dt.hour >= 12 ? (isArabic ? 'م' : 'PM') : (isArabic ? 'ص' : 'AM');
    return '$hourMin $amPm';
  }

  String _formatDate(DateTime dt, bool isArabic) {
    final now = DateTime.now();
    if (now.day == dt.day && now.month == dt.month && now.year == dt.year) {
      return isArabic ? 'اليوم' : 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.day == dt.day && yesterday.month == dt.month && yesterday.year == dt.year) {
      return isArabic ? 'أمس' : 'Yesterday';
    }
    return DateFormat('MMM d, yyyy').format(dt);
  }

  static bool _isArabicText(String text) {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return false;
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
    for (int i = 0; i < cleanText.length; i++) {
      final char = cleanText[i];
      if (RegExp(r'[a-zA-Z]').hasMatch(char)) {
        return false;
      }
      if (arabicRegex.hasMatch(char)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final isActivity = message.isActivity;
    final isPrivate = message.isPrivateNote;
    final isOutgoing = message.isOutgoing;

    return Column(
      children: [
        // Date Header
        if (showDateHeader)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F0F3),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _formatDate(message.createdAt, isArabic),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF626F7F),
                fontFamily: 'Gontserrat',
              ),
            ),
          ),

        // Message Content
        if (isActivity)
          _buildActivityBubble(isDark)
        else if (isPrivate)
          _buildPrivateNoteBubble(isDark, isArabic)
        else if (message.isTemplate)
          _buildTemplateBubble(isDark, isArabic, context)
        else if (isOutgoing)
          _buildOutgoingBubble(isDark, isArabic, context)
        else
          _buildIncomingBubble(isDark, isArabic, context),
      ],
    );
  }

  Widget _buildActivityBubble(bool isDark) {
    final text = message.content ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 20),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            height: 1.35,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontFamily: 'Gontserrat',
          ),
        ),
      ),
    );
  }

  Widget _buildRichFormattedText(String text, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*([^*]+)\*');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.bold),
      ));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    final isAr = _isArabicText(text);
    return RichText(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      textAlign: isAr ? TextAlign.right : TextAlign.left,
      text: TextSpan(children: spans),
    );
  }

  Widget _buildOutgoingSenderBadge({double size = 26}) {
    final nameLower = (message.senderName ?? '').toLowerCase();
    final isBot = nameLower.contains('automation') ||
        nameLower.contains('bot') ||
        nameLower.contains('system') ||
        nameLower.contains('sales agent') ||
        nameLower.contains('ai agent') ||
        message.contentAttributes['automation'] != null ||
        (message.senderAvatar == null && (message.isTemplate || message.senderName == null));

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (message.senderAvatar != null && message.senderAvatar!.isNotEmpty)
            CircleAvatar(
              radius: size / 2,
              backgroundImage: CachedNetworkImageProvider(message.senderAvatar!),
            )
          else if (isBot)
            CircleAvatar(
              radius: size / 2,
              backgroundColor: const Color(0xFFEFF6FF),
              child: Icon(
                Icons.smart_toy_outlined,
                size: size * 0.58,
                color: const Color(0xFF3B82F6),
              ),
            )
          else
            CircleAvatar(
              radius: size / 2,
              backgroundColor: const Color(0xFF4162E3).withValues(alpha: 0.15),
              child: Text(
                (message.senderName != null && message.senderName!.isNotEmpty)
                    ? message.senderName![0].toUpperCase()
                    : 'A',
                style: TextStyle(
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4162E3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOutgoingBubble(bool isDark, bool isArabic, BuildContext context) {
    final isFailed = message.isFailed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _buildExternalStatusIndicator(),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.74,
            ),
            child: Container(
              padding: message.referral != null
                  ? const EdgeInsets.fromLTRB(6, 6, 6, 8)
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isFailed
                    ? (isDark ? const Color(0xFF3B181E) : const Color(0xFFDC2626))
                    : const Color(0xFF4162E3), // Reference C:\crm #4162E3
                border: isFailed ? Border.all(color: const Color(0xFFFCA5A5), width: 1.2) : null,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Ad Referral Card (if message is from a Meta / WhatsApp Click-to-Chat ad)
                  if (message.referral != null) ...[
                    _buildAdReferralCard(context, message.referral!, isDark, isArabic),
                    const SizedBox(height: 6),
                  ],

                  // Attachments
                  if (message.attachments.isNotEmpty) ...[
                    ...message.attachments.map((att) => _buildAttachment(context, att, isOutgoing: true)),
                    const SizedBox(height: 6),
                  ],

                  // Content
                  if (message.content != null && message.content!.isNotEmpty) ...[
                    Builder(
                      builder: (context) {
                        final isAr = _isArabicText(message.content!);
                        return Align(
                          alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                          child: Text(
                            message.content!,
                            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                            textAlign: isAr ? TextAlign.right : TextAlign.left,
                            style: const TextStyle(
                              fontSize: 14.5,
                              height: 1.35,
                              color: Colors.white,
                              fontFamily: 'Gontserrat',
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  if (isFailed) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            message.failureReason ?? 'فشل الإرسال',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Gontserrat',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt, isArabic),
                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xBFFFFFFF), // rgba(255,255,255,0.75)
                          fontFamily: 'Gontserrat',
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildDeliveryStatus(message.status, isTemplate: false, isDark: isDark),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          _buildOutgoingSenderBadge(),
        ],
      ),
    );
  }

  Widget _buildIncomingBubble(bool isDark, bool isArabic, BuildContext context) {
    final bubbleBg = isDark ? const Color(0xFF161616) : Colors.white;
    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0D0D0D);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar
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
              padding: message.referral != null
                  ? const EdgeInsets.fromLTRB(6, 6, 6, 8)
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bubbleBg,
                border: Border.all(
                  color: isDark ? const Color(0xFF2C2D32) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ad Referral Card (if message is from a Meta / WhatsApp Click-to-Chat ad)
                  if (message.referral != null) ...[
                    _buildAdReferralCard(context, message.referral!, isDark, isArabic),
                    const SizedBox(height: 6),
                  ],

                  // Attachments
                  if (message.attachments.isNotEmpty) ...[
                    ...message.attachments.map((att) => _buildAttachment(context, att, isOutgoing: false)),
                    const SizedBox(height: 6),
                  ],

                  // Content
                  if (message.content != null && message.content!.isNotEmpty) ...[
                    Builder(
                      builder: (context) {
                        final isAr = _isArabicText(message.content!);
                        return Align(
                          alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                          child: Text(
                            message.content!,
                            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                            textAlign: isAr ? TextAlign.right : TextAlign.left,
                            style: TextStyle(
                              fontSize: 14.5,
                              height: 1.35,
                              color: textColor,
                              fontFamily: 'Gontserrat',
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt, isArabic),
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF80838D),
                      fontFamily: 'Gontserrat',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateNoteBubble(bool isDark, bool isArabic) {
    // Reference C:\crm PrivateNote styling:
    // bgLight: #fffbeb, bgDark: #271904, borderLight: #fef08a, borderDark: #78350f, accent: #FA8900
    final bg = isDark ? const Color(0xFF271904) : const Color(0xFFFFFBEB);
    final border = isDark ? const Color(0xFF78350F) : const Color(0xFFFEF08A);
    const accent = Color(0xFFFA8900);
    final text = isDark ? const Color(0xFFFFE8CC) : const Color(0xFF78350F);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_rounded, size: 14, color: accent),
                const SizedBox(width: 6),
                Text(
                  isArabic ? 'ملاحظة خاصة • ${message.senderName ?? 'فريق العمل'}' : 'Private Note • ${message.senderName ?? 'Team'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: accent,
                    fontFamily: 'Gontserrat',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (message.content != null && message.content!.isNotEmpty) ...[
              Builder(
                builder: (context) {
                  final isAr = _isArabicText(message.content!);
                  return Align(
                    alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      message.content!,
                      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                      textAlign: isAr ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: text,
                        fontFamily: 'Gontserrat',
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _formatTime(message.createdAt, isArabic),
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                style: TextStyle(
                  fontSize: 10,
                  color: accent.withValues(alpha: 0.8),
                  fontFamily: 'Gontserrat',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context) {
    final textToCopy = message.content ?? '';
    if (textToCopy.isEmpty) return const SizedBox.shrink();

    return Tooltip(
      message: 'نسخ الرسالة',
      child: InkWell(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: textToCopy));
          if (context.mounted) {
            final isArabic = Localizations.localeOf(context).languageCode == 'ar';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isArabic ? 'تم نسخ الرسالة إلى الحافظة' : 'Message copied to clipboard',
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

  Widget _buildTemplateBubble(bool isDark, bool isArabic, BuildContext context) {
    final bool isFailed = message.isFailed;

    // Palette matching real Web CRM screenshots (Image 1 & Image 2):
    // Soft blue when sent/delivered/seen, rose/pink when failed/error
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
      titleColor = isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B); // Bold dark red in Image 1
    } else {
      bubbleBg = isDark ? const Color(0xFF131D2D) : const Color(0xFFEFF6FF);
      borderColor = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBFDBFE);
      buttonBg = isDark ? const Color(0xFF182235) : const Color(0xFFF8FAFC);
      buttonBorder = isDark ? const Color(0xFF283E66) : const Color(0xFFDBEAFE);
      titleColor = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF1E293B); // Bold dark slate in Image 2
    }

    final headerBadgeColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final textColor = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF1C1917);
    final footerColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    final tName = message.templateName ?? (isArabic ? 'رسالة قالب' : 'Template message');
    final template = MessageTemplateRegistry.find(message.templateName);
    final actionButtons = message.templateActionButtons;

    // Header and footer handling
    String? headerText = template?.header;
    String? footerText = template?.footer;
    String bodyText = message.content ?? '';

    // If message.content already starts with headerText, extract it for dedicated styling
    if (headerText != null && headerText.isNotEmpty && bodyText.startsWith(headerText)) {
      bodyText = bodyText.substring(headerText.length).trim();
    } else if (headerText == null && bodyText.contains('\n\n')) {
      final firstLine = bodyText.split('\n\n').first.trim();
      if (firstLine.length < 50 && !firstLine.contains('👋') && !firstLine.contains('*')) {
        headerText = firstLine;
        bodyText = bodyText.substring(firstLine.length).trim();
      }
    }

    // If message.content ends with footerText, extract it
    if (footerText != null && footerText.isNotEmpty && bodyText.endsWith(footerText)) {
      bodyText = bodyText.substring(0, bodyText.length - footerText.length).trim();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left status indicators matching web CRM (Copy on top, retry/checkmarks below)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildCopyButton(context),
              const SizedBox(height: 8),
              _buildExternalStatusIndicator(),
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
                  // Ad Referral Card (if attached to template message)
                  if (message.referral != null) ...[
                    _buildAdReferralCard(context, message.referral!, isDark, isArabic),
                    const SizedBox(height: 6),
                  ],

                  // Top Header Badge: (B) Template message | template_name
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
                              fontFamily: 'Gontserrat',
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
                              fontFamily: 'Gontserrat',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1, color: borderColor.withValues(alpha: 0.7)),

                  // Content Body
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header title (bold dark red in pink card, bold slate in blue card)
                        if (headerText != null && headerText.isNotEmpty) ...[
                          Builder(
                            builder: (context) {
                              final isAr = _isArabicText(headerText!);
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
                                    fontFamily: 'Gontserrat',
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                        ],

                        // Body text with markdown bold support
                        if (bodyText.isNotEmpty)
                          _buildRichFormattedText(
                            bodyText,
                            TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: textColor,
                              fontFamily: 'Gontserrat',
                            ),
                          ),

                        // Subtle divider and footer text (e.g. فريق مسج برو in Image 1)
                        if (footerText != null && footerText.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Divider(height: 1, color: borderColor.withValues(alpha: 0.6)),
                          const SizedBox(height: 6),
                          Text(
                            footerText,
                            style: TextStyle(
                              fontSize: 11,
                              color: footerColor,
                              fontFamily: 'Gontserrat',
                            ),
                          ),
                        ],

                        // Action Buttons inside template
                        if (actionButtons.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: buttonBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: buttonBorder,
                                width: 0.9,
                              ),
                            ),
                            child: Column(
                              children: List.generate(actionButtons.length, (idx) {
                                final btn = actionButtons[idx];
                                final isLast = idx == actionButtons.length - 1;

                                return InkWell(
                                  onTap: () async {
                                    if (btn.isUrl && btn.url != null) {
                                      final uri = Uri.tryParse(btn.url!);
                                      if (uri != null && await canLaunchUrl(uri)) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      }
                                    }
                                  },
                                  borderRadius: BorderRadius.vertical(
                                    top: idx == 0 ? const Radius.circular(8) : Radius.zero,
                                    bottom: isLast ? const Radius.circular(8) : Radius.zero,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: isLast
                                          ? null
                                          : Border(
                                              bottom: BorderSide(
                                                color: buttonBorder,
                                                width: 0.8,
                                              ),
                                            ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          btn.isUrl ? Icons.open_in_new_rounded : Icons.reply_rounded,
                                          size: 15,
                                          color: const Color(0xFF2563EB),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            btn.text,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2563EB),
                                              fontFamily: 'Gontserrat',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
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
                                      fontFamily: 'Gontserrat',
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
          _buildOutgoingSenderBadge(),
        ],
      ),
    );
  }

  Widget _buildAdReferralCard(BuildContext context, MessageReferral referral, bool isDark, bool isArabic) {
    final headline = (referral.headline != null && referral.headline!.trim().isNotEmpty)
        ? referral.headline!.trim()
        : (isArabic ? 'إعلان فيسبوك / واتساب' : 'Sponsored Meta Ad');
    final body = referral.body?.trim();
    final sourceUrl = referral.sourceUrl;
    final videoUrl = referral.videoUrl;
    final targetUrl = (sourceUrl != null && sourceUrl.isNotEmpty) ? sourceUrl : videoUrl;
    final isVideo = referral.mediaType == 'video' || (videoUrl != null && videoUrl.isNotEmpty);

    String? imageUrl = referral.imageUrl?.trim();
    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('/')) {
      imageUrl = '${AppConfig.defaultBaseUrl}$imageUrl';
    }

    final platformName = referral.platform?.toLowerCase() == 'facebook'
        ? (isArabic ? 'إعلان فيسبوك (واتساب)' : 'Facebook Ad (CTWA)')
        : (isArabic ? 'إعلان فيسبوك / واتساب' : 'Meta Ad');

    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (imageUrl != null && imageUrl.isNotEmpty)
          GestureDetector(
            onTap: () {
              if (targetUrl != null && targetUrl.isNotEmpty) {
                final uri = Uri.tryParse(targetUrl);
                if (uri != null) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 140,
                      color: isDark ? const Color(0xFF262C36) : const Color(0xFFE2E8F0),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  if (isVideo)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isVideo ? Icons.play_circle_outline_rounded : Icons.campaign_rounded,
                    size: 13,
                    color: const Color(0xFF1877F2),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    platformName,
                    style: const TextStyle(
                      color: Color(0xFF1877F2),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Gontserrat',
                    ),
                  ),
                  const Spacer(),
                  if (targetUrl != null && targetUrl.isNotEmpty)
                    InkWell(
                      onTap: () {
                        final uri = Uri.tryParse(targetUrl);
                        if (uri != null) {
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        children: [
                          Text(
                            isArabic ? 'عرض الإعلان' : 'View Ad',
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Gontserrat',
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.open_in_new_rounded, size: 11, color: Color(0xFF2563EB)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Builder(
                builder: (context) {
                  final isHeadAr = _isArabicText(headline);
                  return Align(
                    alignment: isHeadAr ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      headline,
                      textDirection: isHeadAr ? TextDirection.rtl : TextDirection.ltr,
                      textAlign: isHeadAr ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontFamily: 'Gontserrat',
                      ),
                    ),
                  );
                },
              ),
              if (body != null && body.isNotEmpty && body != message.content) ...[
                const SizedBox(height: 3),
                Builder(
                  builder: (context) {
                    final isBodyAr = _isArabicText(body);
                    return Align(
                      alignment: isBodyAr ? Alignment.centerRight : Alignment.centerLeft,
                      child: Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: isBodyAr ? TextDirection.rtl : TextDirection.ltr,
                        textAlign: isBodyAr ? TextAlign.right : TextAlign.left,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontFamily: 'Gontserrat',
                        )),
                      );
                    },
                  ),
                ],
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: Divider(
                  height: 1,
                  thickness: 0.8,
                  color: dividerColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttachment(BuildContext context, MessageAttachment att, {required bool isOutgoing}) {
    final lowerType = att.fileType.toLowerCase();
    final urlLower = att.dataUrl.toLowerCase();
    final isImage = lowerType == 'image' ||
        urlLower.endsWith('.png') ||
        urlLower.endsWith('.jpg') ||
        urlLower.endsWith('.jpeg') ||
        urlLower.endsWith('.gif') ||
        urlLower.endsWith('.webp');
    final isAudio = lowerType == 'audio' ||
        urlLower.endsWith('.mp3') ||
        urlLower.endsWith('.ogg') ||
        urlLower.endsWith('.wav') ||
        urlLower.endsWith('.m4a') ||
        urlLower.endsWith('.aac') ||
        urlLower.endsWith('.opus');

    if (isImage) {
      return InkWell(
        onTap: () => ImageViewerScreen.open(
          context,
          imageUrl: att.dataUrl,
          title: att.fileName,
        ),
        borderRadius: BorderRadius.circular(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: att.dataUrl,
                fit: BoxFit.cover,
                placeholder: (ctx, url) => Container(
                  height: 140,
                  color: Colors.black12,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (ctx, url, error) => const Icon(Icons.broken_image_rounded, size: 36),
              ),
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isAudio) {
      return AudioPlayerBubble(
        audioUrl: att.dataUrl,
        isOutgoing: isOutgoing,
        fileName: att.fileName,
      );
    }

    return DocumentAttachmentTile(
      fileUrl: att.dataUrl,
      fileName: att.fileName,
      fileSize: att.fileSize,
      fileType: att.fileType,
      isOutgoing: isOutgoing,
    );
  }

  Widget _buildExternalStatusIndicator() {
    if (message.isFailed) {
      return InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF87171), width: 1),
          ),
          child: const Icon(
            Icons.refresh_rounded, // Red retry icon as in Web CRM screenshots
            size: 15,
            color: Color(0xFFDC2626),
          ),
        ),
      );
    } else if (message.isRead) {
      return const Padding(
        padding: EdgeInsets.only(right: 6),
        child: Icon(
          Icons.done_all_rounded, // Vibrant blue double checkmark (seen status)
          size: 19,
          color: Color(0xFF2563EB),
        ),
      );
    } else if (message.isDelivered) {
      return const Padding(
        padding: EdgeInsets.only(right: 6),
        child: Icon(
          Icons.done_all_rounded, // Double gray checkmark (delivered to phone)
          size: 19,
          color: Color(0xFF9CA3AF),
        ),
      );
    } else if (message.isSent) {
      return const Padding(
        padding: EdgeInsets.only(right: 6),
        child: Icon(
          Icons.done_rounded, // Single gray checkmark (sent to server)
          size: 17,
          color: Color(0xFF9CA3AF),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDeliveryStatus(String status, {required bool isTemplate, required bool isDark}) {
    if (status == 'failed') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 12, color: Color(0xFFDC2626)),
          const SizedBox(width: 2),
          Text(
            'فشل الإرسال',
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626),
              fontFamily: 'Gontserrat',
            ),
          ),
        ],
      );
    } else if (status == 'read' || status == 'seen') {
      return const Icon(
        Icons.done_all_rounded,
        size: 14,
        color: Color(0xFF2563EB), // Vibrant blue for read/seen!
      );
    } else if (status == 'delivered') {
      return Icon(
        Icons.done_all_rounded,
        size: 14,
        color: isTemplate
            ? (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))
            : Colors.white70,
      );
    } else if (status == 'sent') {
      return Icon(
        Icons.check_rounded,
        size: 14,
        color: isTemplate
            ? (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))
            : Colors.white70,
      );
    }
    return const SizedBox.shrink();
  }
}
