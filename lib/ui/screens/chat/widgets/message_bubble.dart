import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:message_pro/core/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/models/message.dart';
import '../../../../data/models/message_template_registry.dart';
import '../../../../data/models/user.dart';
import '../../../widgets/avatar_widget.dart';
import '../../../widgets/media_viewers/audio_player_bubble.dart';
import '../../../widgets/media_viewers/document_attachment_tile.dart';
import '../../../widgets/media_viewers/image_viewer_screen.dart';
import '../../../../core/services/link_preview_service.dart';
import '../../../../core/services/haptic_service.dart';
import 'link_preview_card.dart';
import 'clickable_text_with_links.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final String contactName;
  final String? contactThumbnail;
  final bool showDateHeader;
  final VoidCallback? onRetry;
  final Message? repliedMessage;
  final ValueChanged<Message>? onReply;
  final ValueChanged<int>? onScrollToMessage;
  final String? channel;
  final User? currentUser;
  final ValueChanged<Message>? onEditMessage;
  final void Function(Message message, String emoji)? onReact;
  final ValueChanged<Message>? onViewReactions;
  final bool isHighlighted;

  const MessageBubble({
    super.key,
    required this.message,
    this.contactName = '',
    this.contactThumbnail,
    this.showDateHeader = false,
    this.onRetry,
    this.repliedMessage,
    this.onReply,
    this.onScrollToMessage,
    this.channel,
    this.currentUser,
    this.onEditMessage,
    this.onReact,
    this.onViewReactions,
    this.isHighlighted = false,
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
        else
          _SwipeToReplyWrapper(
            isOutgoing: isOutgoing,
            onReply: onReply != null ? () => onReply!(message) : null,
            onDoubleTap: onReply != null ? () => onReply!(message) : null,
            onLongPress: () => _showMessageActionMenu(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: isHighlighted
                    ? (isDark
                        ? const Color(0xFF4162E3).withValues(alpha: 0.28)
                        : const Color(0xFF4162E3).withValues(alpha: 0.16))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: isPrivate
                  ? _buildPrivateNoteBubble(isDark, isArabic)
                  : (message.isTemplate
                      ? _buildTemplateBubble(isDark, isArabic, context)
                      : (isOutgoing
                          ? _buildOutgoingBubble(isDark, isArabic, context)
                          : _buildIncomingBubble(isDark, isArabic, context))),
            ),
          ),
      ],
    );
  }

  Widget _buildActivityBubble(bool isDark) {
    final rawText = message.content ?? '';
    final text = rawText
        .replaceAll(RegExp(r'</?(b|strong|p|span)[^>]*>', caseSensitive: false), '')
        .replaceAll('*', '')
        .trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 16),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.normal,
            height: 1.25,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontFamily: 'Gontserrat',
          ),
        ),
      ),
    );
  }

  Widget _buildRichFormattedText(String text, TextStyle baseStyle) {
    final isAr = _isArabicText(text);
    return ClickableTextWithLinks(
      text: text,
      textStyle: baseStyle,
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      textAlign: isAr ? TextAlign.right : TextAlign.left,
    );
  }

  Widget _buildPlatformBadge(String channelName, double size) {
    final lower = channelName.toLowerCase();

    // 1. WhatsApp
    if (lower.contains('whatsapp')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF25D366),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF25D366).withValues(alpha: 0.35),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2.5),
        child: ClipOval(
          child: Image.asset(
            'assets/images/channels/whatsapp.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Center(
              child: Icon(Icons.chat_bubble_rounded, size: size * 0.55, color: Colors.white),
            ),
          ),
        ),
      );
    }

    // 2. Facebook / Messenger
    if (lower.contains('facebook') || lower.contains('messenger')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF00C6FF), Color(0xFF0078FF)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0078FF).withValues(alpha: 0.35),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/channels/messenger.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(
              child: Icon(Icons.bolt_rounded, size: size * 0.6, color: Colors.white),
            ),
          ),
        ),
      );
    }

    // 3. Instagram
    if (lower.contains('instagram')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xFFF58529),
              Color(0xFFDD2A7B),
              Color(0xFF8134AF),
              Color(0xFF515BD4),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDD2A7B).withValues(alpha: 0.35),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.camera_alt_rounded,
            size: size * 0.55,
            color: Colors.white,
          ),
        ),
      );
    }

    // 4. Telegram
    if (lower.contains('telegram')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF229ED9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF229ED9).withValues(alpha: 0.35),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Icon(Icons.send_rounded, size: size * 0.5, color: Colors.white),
        ),
      );
    }

    // Default / Web
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF4162E3),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4162E3).withValues(alpha: 0.35),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Icon(Icons.language_rounded, size: size * 0.55, color: Colors.white),
      ),
    );
  }

  Widget _buildOutgoingSenderBadge({double size = 26}) {
    final effectiveChannel = channel ??
        message.contentAttributes['channel']?.toString() ??
        'whatsapp';

    Widget badgeContent;
    String tooltipMsg;

    if (message.isBot) {
      tooltipMsg = 'رد آلي / بوت';
      badgeContent = CircleAvatar(
        radius: size / 2,
        backgroundColor: const Color(0xFFEFF6FF),
        child: Icon(
          Icons.smart_toy_outlined,
          size: size * 0.58,
          color: const Color(0xFF3B82F6),
        ),
      );
    } else if (message.isSentByAgent) {
      final name = message.senderName?.trim();
      tooltipMsg = (name != null && name.isNotEmpty) ? name : 'موظف';
      if (message.senderAvatar != null && message.senderAvatar!.isNotEmpty) {
        badgeContent = CircleAvatar(
          radius: size / 2,
          backgroundImage: CachedNetworkImageProvider(message.senderAvatar!),
        );
      } else {
        badgeContent = CircleAvatar(
          radius: size / 2,
          backgroundColor: const Color(0xFF4162E3).withValues(alpha: 0.15),
          child: Text(
            (name != null && name.isNotEmpty)
                ? name[0].toUpperCase()
                : 'A',
            style: TextStyle(
              fontSize: size * 0.42,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4162E3),
            ),
          ),
        );
      }
    } else {
      // Sent directly from platform (WhatsApp / Messenger / Instagram / Telegram)
      final chLower = effectiveChannel.toLowerCase();
      if (chLower.contains('whatsapp')) {
        tooltipMsg = 'مُرسل من واتساب';
      } else if (chLower.contains('messenger') || chLower.contains('facebook')) {
        tooltipMsg = 'مُرسل من ماسنجر';
      } else if (chLower.contains('instagram')) {
        tooltipMsg = 'مُرسل من إنستغرام';
      } else if (chLower.contains('telegram')) {
        tooltipMsg = 'مُرسل من تيليجرام';
      } else {
        tooltipMsg = 'مُرسل من المنصة';
      }
      badgeContent = _buildPlatformBadge(effectiveChannel, size);
    }

    return Tooltip(
      message: tooltipMsg,
      preferBelow: false,
      child: SizedBox(
        width: size,
        height: size,
        child: badgeContent,
      ),
    );
  }

  Widget _buildReactionsPill(BuildContext context, bool isDark) {
    if (message.reactions.isEmpty) return const SizedBox.shrink();
    final summary = message.reactionsSummary;
    if (summary.isEmpty) return const SizedBox.shrink();

    final bgColor = isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? const Color(0xFF383838) : const Color(0xFFCBD5E1);
    final count = message.reactions.length;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onViewReactions?.call(message),
      child: Container(
        margin: const EdgeInsets.only(top: 2, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...message.uniqueReactionEmojis.take(3).map((e) => Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Text(e, style: const TextStyle(fontSize: 13)),
            )),
            if (count > 1) ...[
              const SizedBox(width: 2),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOutgoingBubble(bool isDark, bool isArabic, BuildContext context) {
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
            child: _buildExternalStatusIndicator(),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.74,
            ),
            child: Container(
              padding: (message.referral != null && message.referral!.hasContent)
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
                  // Quoted Reply Preview
                  if (repliedMessage != null || message.inReplyToId != null)
                    _buildQuotedMessagePreview(context, isDark, isArabic, true),

                  // Ad Referral Card (if message is from a Meta / WhatsApp Click-to-Chat ad)
                  if (message.referral != null && message.referral!.hasContent) ...[
                    _buildAdReferralCard(context, message.referral!, isDark, isArabic),
                    const SizedBox(height: 6),
                  ],

                  // Attachments
                  if (message.attachments.isNotEmpty) ...[
                    _buildAttachments(context, isOutgoing: true),
                    const SizedBox(height: 6),
                  ],

                  // Content & Link Preview
                  if (message.content != null && message.content!.isNotEmpty) ...[
                    Builder(
                      builder: (context) {
                        final firstUrl = LinkPreviewService.extractFirstUrl(message.content);
                        if (firstUrl == null) return const SizedBox.shrink();
                        return LinkPreviewCard(
                          url: firstUrl,
                          isOutgoing: true,
                          isDark: isDark,
                        );
                      },
                    ),
                    Builder(
                      builder: (context) {
                        final isAr = _isArabicText(message.content!);
                        return Align(
                          alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                          child: ClickableTextWithLinks(
                            text: message.content!,
                            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                            textAlign: isAr ? TextAlign.right : TextAlign.left,
                            textStyle: const TextStyle(
                              fontSize: 14.5,
                              height: 1.35,
                              color: Colors.white,
                              fontFamily: 'Gontserrat',
                            ),
                            linkStyle: const TextStyle(
                              fontSize: 14.5,
                              height: 1.35,
                              color: Color(0xFFBAE6FD),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFFBAE6FD),
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
                      if (message.isEdited) ...[
                        Text(
                          isArabic ? 'مُعدلة ' : 'Edited ',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontStyle: FontStyle.italic,
                            color: Color(0x99FFFFFF),
                            fontFamily: 'Gontserrat',
                          ),
                        ),
                        const SizedBox(width: 2),
                      ],
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
      if (message.reactions.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(right: 32),
          child: _buildReactionsPill(context, isDark),
        ),
    ],
  ),
);
  }

  Widget _buildIncomingBubble(bool isDark, bool isArabic, BuildContext context) {
    final bubbleBg = isDark ? const Color(0xFF161616) : Colors.white;
    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0D0D0D);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              padding: (message.referral != null && message.referral!.hasContent)
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
                  // Quoted Reply Preview
                  if (repliedMessage != null || message.inReplyToId != null)
                    _buildQuotedMessagePreview(context, isDark, isArabic, false),

                  // Ad Referral Card (if message is from a Meta / WhatsApp Click-to-Chat ad)
                  if (message.referral != null && message.referral!.hasContent) ...[
                    _buildAdReferralCard(context, message.referral!, isDark, isArabic),
                    const SizedBox(height: 6),
                  ],

                  // Attachments
                  if (message.attachments.isNotEmpty) ...[
                    _buildAttachments(context, isOutgoing: false),
                    const SizedBox(height: 6),
                  ],

                  // Content & Link Preview
                  if (message.content != null && message.content!.isNotEmpty) ...[
                    Builder(
                      builder: (context) {
                        final firstUrl = LinkPreviewService.extractFirstUrl(message.content);
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
                        final isAr = _isArabicText(message.content!);
                        return Align(
                          alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                          child: ClickableTextWithLinks(
                            text: message.content!,
                            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                            textAlign: isAr ? TextAlign.right : TextAlign.left,
                            textStyle: TextStyle(
                              fontSize: 14.5,
                              height: 1.35,
                              color: textColor,
                              fontFamily: 'Gontserrat',
                            ),
                            linkStyle: TextStyle(
                              fontSize: 14.5,
                              height: 1.35,
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                              fontFamily: 'Gontserrat',
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.isEdited) ...[
                        Text(
                          isArabic ? 'مُعدلة ' : 'Edited ',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF80838D),
                            fontFamily: 'Gontserrat',
                          ),
                        ),
                        const SizedBox(width: 2),
                      ],
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
                ],
              ),
            ),
          ),
        ],
      ),
      if (message.reactions.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: _buildReactionsPill(context, isDark),
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
                  final firstUrl = LinkPreviewService.extractFirstUrl(message.content);
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
                  final isAr = _isArabicText(message.content!);
                  return Align(
                    alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                    child: ClickableTextWithLinks(
                      text: message.content!,
                      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                      textAlign: isAr ? TextAlign.right : TextAlign.left,
                      textStyle: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: text,
                        fontFamily: 'Gontserrat',
                      ),
                      linkStyle: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
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
                  // Quoted Reply Preview
                  if (repliedMessage != null || message.inReplyToId != null)
                    _buildQuotedMessagePreview(context, isDark, isArabic, true),

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

  bool _isImageAttachment(MessageAttachment att) {
    final lowerType = att.fileType.toLowerCase();
    final urlLower = att.dataUrl.toLowerCase();
    return lowerType == 'image' ||
        urlLower.endsWith('.png') ||
        urlLower.endsWith('.jpg') ||
        urlLower.endsWith('.jpeg') ||
        urlLower.endsWith('.gif') ||
        urlLower.endsWith('.webp');
  }

  bool _isVideoAttachment(MessageAttachment att) {
    final lowerType = att.fileType.toLowerCase();
    final urlLower = att.dataUrl.toLowerCase();
    return lowerType == 'video' ||
        urlLower.endsWith('.mp4') ||
        urlLower.endsWith('.mov') ||
        urlLower.endsWith('.avi') ||
        urlLower.endsWith('.mkv') ||
        urlLower.endsWith('.webm') ||
        urlLower.endsWith('.3gp');
  }

  bool _isAudioAttachment(MessageAttachment att) {
    final lowerType = att.fileType.toLowerCase();
    final urlLower = att.dataUrl.toLowerCase();
    return lowerType == 'audio' ||
        urlLower.endsWith('.mp3') ||
        urlLower.endsWith('.ogg') ||
        urlLower.endsWith('.wav') ||
        urlLower.endsWith('.m4a') ||
        urlLower.endsWith('.aac') ||
        urlLower.endsWith('.opus');
  }

  Widget _buildAttachments(BuildContext context, {required bool isOutgoing}) {
    final images = message.attachments.where(_isImageAttachment).toList();
    final others = message.attachments.where((a) => !_isImageAttachment(a)).toList();

    return Column(
      crossAxisAlignment: isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (images.length == 1)
          _buildSingleImage(context, images.first, [images.first.dataUrl], 0)
        else if (images.length > 1)
          _buildImageGrid(context, images),
        if (images.isNotEmpty && others.isNotEmpty)
          const SizedBox(height: 6),
        ...others.map((att) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _buildAttachment(context, att, isOutgoing: isOutgoing),
            )),
      ],
    );
  }

  Widget _buildSingleImage(BuildContext context, MessageAttachment att, List<String> allUrls, int index) {
    return InkWell(
      onTap: () => ImageViewerScreen.openGallery(
        context,
        imageUrls: allUrls,
        initialIndex: index,
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

  Widget _buildImageGrid(BuildContext context, List<MessageAttachment> images) {
    final urls = images.map((a) => a.dataUrl).toList();
    final count = images.length;

    Widget buildTile(int idx, {required double height}) {
      return _buildGridImageTile(context, images[idx], urls, idx, height: height);
    }

    if (count == 2) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Expanded(child: buildTile(0, height: 130)),
            const SizedBox(width: 4),
            Expanded(child: buildTile(1, height: 130)),
          ],
        ),
      );
    }

    if (count == 3) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildTile(0, height: 120),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: buildTile(1, height: 85)),
                const SizedBox(width: 4),
                Expanded(child: buildTile(2, height: 85)),
              ],
            ),
          ],
        ),
      );
    }

    if (count == 4) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: buildTile(0, height: 100)),
                const SizedBox(width: 4),
                Expanded(child: buildTile(1, height: 100)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: buildTile(2, height: 100)),
                const SizedBox(width: 4),
                Expanded(child: buildTile(3, height: 100)),
              ],
            ),
          ],
        ),
      );
    }

    // 5 images (or more)
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: buildTile(0, height: 105)),
              const SizedBox(width: 4),
              Expanded(child: buildTile(1, height: 105)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: buildTile(2, height: 80)),
              const SizedBox(width: 4),
              Expanded(child: buildTile(3, height: 80)),
              const SizedBox(width: 4),
              Expanded(child: buildTile(4, height: 80)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridImageTile(
    BuildContext context,
    MessageAttachment att,
    List<String> allUrls,
    int index, {
    required double height,
  }) {
    return InkWell(
      onTap: () => ImageViewerScreen.openGallery(
        context,
        imageUrls: allUrls,
        initialIndex: index,
        title: att.fileName,
      ),
      child: SizedBox(
        height: height,
        child: CachedNetworkImage(
          imageUrl: att.dataUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (ctx, url) => Container(
            color: Colors.black12,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
          ),
          errorWidget: (ctx, url, error) => Container(
            color: Colors.black12,
            child: const Icon(Icons.broken_image_rounded, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoAttachment(BuildContext context, MessageAttachment att, {required bool isOutgoing}) {
    String formatDuration(double? seconds) {
      if (seconds == null || seconds <= 0) return '';
      final d = Duration(seconds: seconds.toInt());
      final min = d.inMinutes;
      final sec = d.inSeconds % 60;
      return '$min:${sec.toString().padLeft(2, '0')}';
    }

    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(att.dataUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (att.thumbUrl != null && att.thumbUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: att.thumbUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(height: 120, color: const Color(0xFF1E293B)),
              )
            else
              Container(height: 120, width: double.infinity, color: const Color(0xFF1E293B)),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              right: 8,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      att.fileName ?? 'Video',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (att.duration != null && att.duration! > 0)
                    Text(
                      formatDuration(att.duration),
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachment(BuildContext context, MessageAttachment att, {required bool isOutgoing}) {
    if (_isImageAttachment(att)) {
      return _buildSingleImage(context, att, [att.dataUrl], 0);
    }

    if (_isVideoAttachment(att)) {
      return _buildVideoAttachment(context, att, isOutgoing: isOutgoing);
    }

    if (_isAudioAttachment(att)) {
      return AudioPlayerBubble(
        audioUrl: att.dataUrl,
        isOutgoing: isOutgoing,
        fileName: att.fileName,
        initialDurationSeconds: att.duration,
        transcribedText: att.transcribedText,
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

  Widget _buildQuotedMessagePreview(BuildContext context, bool isDark, bool isArabic, bool isOutgoing) {
    final replied = repliedMessage;
    final inReplyToId = message.inReplyToId;
    if (replied == null && inReplyToId == null) return const SizedBox.shrink();

    final isSenderMe = replied?.isOutgoing ?? false;
    final senderName = replied != null
        ? (isSenderMe ? (isArabic ? 'أنت' : 'You') : (replied.senderName ?? (isArabic ? 'العميل' : 'Customer')))
        : (isArabic ? 'رسالة سابقة' : 'Previous Message');

    String snippet = '';
    if (replied?.content != null && replied!.content!.trim().isNotEmpty) {
      snippet = replied.content!.trim();
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
      snippet = isArabic ? 'رسالة مقتبسة' : 'Quoted Message';
    }

    final barColor = isOutgoing ? Colors.white : const Color(0xFF4162E3);
    final bgColor = isOutgoing
        ? Colors.black.withValues(alpha: 0.16)
        : (isDark ? const Color(0xFF1E2128) : const Color(0xFFE2E8F0).withValues(alpha: 0.65));
    final titleColor = isOutgoing ? Colors.white : const Color(0xFF4162E3);
    final textColor = isOutgoing
        ? Colors.white.withValues(alpha: 0.88)
        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569));

    return InkWell(
      onTap: () {
        if (inReplyToId != null) {
          onScrollToMessage?.call(inReplyToId);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            right: isArabic ? BorderSide(color: barColor, width: 3.5) : BorderSide.none,
            left: !isArabic ? BorderSide(color: barColor, width: 3.5) : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              senderName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: titleColor,
                fontFamily: 'Gontserrat',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              snippet,
              style: TextStyle(
                fontSize: 10.5,
                color: textColor,
                fontFamily: 'Gontserrat',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageActionMenu(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textToCopy = message.content ?? '';

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
                  style: const TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w600),
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
                  onEditMessage?.call(message);
                },
              ),
            if (onReply != null)
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
                  style: const TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onReply?.call(message);
                },
              ),
            if (textToCopy.isNotEmpty)
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
                  style: const TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w600),
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
                  style: const TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w600),
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
                  style: const TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onRetry?.call();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SwipeToReplyWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onReply;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final bool isOutgoing;

  const _SwipeToReplyWrapper({
    required this.child,
    this.onReply,
    this.onDoubleTap,
    this.onLongPress,
    required this.isOutgoing,
  });

  @override
  State<_SwipeToReplyWrapper> createState() => _SwipeToReplyWrapperState();
}

class _SwipeToReplyWrapperState extends State<_SwipeToReplyWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  double _dragOffset = 0.0;
  bool _hasTriggeredHaptic = false;
  static const double _replyThreshold = 38.0;
  static const double _maxDrag = 65.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    )..addListener(() {
        setState(() {
          _dragOffset = _animation.value;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.onReply == null) return;

    final delta = details.primaryDelta ?? 0;
    final newOffset = _dragOffset + delta;

    if (newOffset.abs() <= _maxDrag) {
      setState(() => _dragOffset = newOffset);
    }

    if (_dragOffset.abs() >= _replyThreshold && !_hasTriggeredHaptic) {
      _hasTriggeredHaptic = true;
      HapticService.lightImpact();
    } else if (_dragOffset.abs() < _replyThreshold) {
      _hasTriggeredHaptic = false;
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.onReply == null) return;

    if (_dragOffset.abs() >= _replyThreshold) {
      widget.onReply!();
    }

    _animation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward(from: 0);
    _hasTriggeredHaptic = false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onReply == null && widget.onDoubleTap == null && widget.onLongPress == null) {
      return widget.child;
    }

    final showIcon = _dragOffset.abs() > 8;
    final progress = (_dragOffset.abs() / _replyThreshold).clamp(0.0, 1.0);
    final isDraggingRight = _dragOffset > 0;

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onDoubleTap: () {
        HapticService.lightImpact();
        (widget.onDoubleTap ?? widget.onReply)?.call();
      },
      onLongPress: () {
        HapticService.mediumImpact();
        widget.onLongPress?.call();
      },
      behavior: HitTestBehavior.translucent,
      child: Stack(
        alignment: isDraggingRight ? Alignment.centerLeft : Alignment.centerRight,
        children: [
          if (showIcon)
            Positioned(
              left: isDraggingRight ? 12 : null,
              right: !isDraggingRight ? 12 : null,
              child: Opacity(
                opacity: progress,
                child: Transform.scale(
                  scale: 0.6 + (0.4 * progress),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4162E3).withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.reply_rounded,
                      size: 20,
                      color: Color(0xFF4162E3),
                    ),
                  ),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
