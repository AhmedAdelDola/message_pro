import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/conversation.dart';
import '../../../widgets/avatar_widget.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    this.onLongPress,
  });

  String _formatTime(DateTime dt, bool isArabic) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inDays == 0 && now.day == dt.day) {
      return DateFormat('h:mm a').format(dt);
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.day == dt.day && yesterday.month == dt.month && yesterday.year == dt.year) {
      return isArabic ? 'أمس' : 'Yesterday';
    }

    if (difference.inDays < 7) {
      return DateFormat('EEE').format(dt);
    }

    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final contact = conversation.contact;
    String cname = contact.name.trim();
    final isGenericName = cname.isEmpty ||
        cname.toLowerCase() == 'contact #null' ||
        cname.toLowerCase() == 'null' ||
        cname.toLowerCase() == 'customer' ||
        cname.toLowerCase() == 'عميل' ||
        cname.toLowerCase() == 'عميل جديد';

    if (isGenericName) {
      if (contact.phoneNumber != null && contact.phoneNumber!.isNotEmpty) {
        cname = contact.phoneNumber!;
      } else if (contact.email != null && contact.email!.isNotEmpty) {
        cname = contact.email!;
      } else if (conversation.id > 0) {
        cname = isArabic ? 'عميل #${conversation.id}' : 'Contact #${conversation.id}';
      } else {
        cname = isArabic ? 'عميل جديد' : 'New Visitor';
      }
    }

    
    final lastMsg = conversation.lastMessage;
    
    String clastMsg;
    bool isOutgoing = false;
    bool isPrivate = false;

    if (lastMsg != null) {
      isPrivate = lastMsg.isPrivateNote;
      isOutgoing = lastMsg.isOutgoing;

      if (lastMsg.content != null && lastMsg.content!.trim().isNotEmpty) {
        clastMsg = lastMsg.content!.trim();
      } else if (lastMsg.attachments.isNotEmpty) {
        final firstType = lastMsg.attachments.first.fileType;
        if (firstType == 'image') {
          clastMsg = isArabic ? '📷 صورة' : '📷 Image';
        } else if (firstType == 'audio') {
          clastMsg = isArabic ? '🎵 تسجيل صوتي' : '🎵 Audio';
        } else if (firstType == 'video') {
          clastMsg = isArabic ? '🎥 فيديو' : '🎥 Video';
        } else {
          clastMsg = isArabic ? '📎 ملف مرفق' : '📎 Attachment';
        }
      } else if (lastMsg.isActivity) {
        clastMsg = lastMsg.content ?? (isArabic ? 'نشاط في المحادثة' : 'Activity');
      } else {
        clastMsg = isArabic ? 'لا توجد رسائل' : 'No messages yet';
      }
    } else {
      clastMsg = isArabic ? 'لا توجد رسائل' : 'No messages yet';
    }
    final ctime = _formatTime(conversation.updatedAt, isArabic);
    final isSnoozed = conversation.status == 'snoozed' || conversation.snoozedUntil != null;

    // Lifecycle stage info
    final stageName = conversation.lifecycleStage?.name ?? 'New Lead';
    final stageEmoji = conversation.lifecycleStage?.icon ?? '🆕';

    // Assignee
    final assignee = conversation.assignee;
    final aName = assignee?.name.trim() ?? '';
    final assigneeInitial = aName.isNotEmpty ? aName[0].toUpperCase() : 'A';

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(color: borderColor, width: 0.8),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar (38x38) with colorful channel badge
            AvatarWidget(
              avatarUrl: contact.avatarUrl,
              name: cname,
              size: 38,
              channel: conversation.channelType,
            ),
            const SizedBox(width: 12),

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Contact Name, Snooze Badge & Timestamp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                cname,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Gontserrat',
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            if (isSnoozed) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFA8900).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFFFA8900).withValues(alpha: 0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.snooze_rounded,
                                      size: 11,
                                      color: Color(0xFFFA8900),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      isArabic ? 'مؤجلة' : 'Snoozed',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFFA8900),
                                        fontFamily: 'Gontserrat',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ctime,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Gontserrat',
                          color: const Color(0xFF80838D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Row 2: Direction Icon + Snippet + Unread Count Badge
                  Row(
                    children: [
                      if (isPrivate) ...[
                        const Icon(Icons.lock_rounded, size: 13, color: Color(0xFFFA8900)),
                        const SizedBox(width: 4),
                      ] else if (isOutgoing) ...[
                        const Icon(Icons.keyboard_arrow_up_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 2),
                      ],
                      Expanded(
                        child: Text(
                          clastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'Gontserrat',
                            color: textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (conversation.unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${conversation.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Gontserrat',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Row 3: Tag / Lifecycle Stage Badge, Inbox Channel Badge & Assignee Avatar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            // Tag Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.lightSolid3,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2E3E7),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(stageEmoji, style: const TextStyle(fontSize: 11)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      stageName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Gontserrat',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (conversation.inboxName != null && conversation.inboxName!.trim().isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E2024) : const Color(0xFFF1F2F4),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildChannelSmallIcon(conversation.channelType),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        conversation.inboxName!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w500,
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
                      const SizedBox(width: 6),

                      // Assignee Avatar (Small 20px)
                      if (assignee != null)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEC4899),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : Colors.white,
                              width: 1,
                            ),
                          ),
                          child: ClipOval(
                            child: (assignee.avatarUrl != null && assignee.avatarUrl!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: assignee.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Center(
                                      child: Text(
                                        assigneeInitial,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                          fontFamily: 'Gontserrat',
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      assigneeInitial,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                        fontFamily: 'Gontserrat',
                                      ),
                                    ),
                                  ),
                          ),
                        )
                      else
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.danger.withValues(alpha: 0.15),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.person,
                            color: AppColors.danger,
                            size: 13,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelSmallIcon(String channelType) {
    final lower = channelType.toLowerCase();
    if (lower.contains('whatsapp')) {
      return Image.asset(
        'assets/images/channels/whatsapp.png',
        width: 12,
        height: 12,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.chat_bubble_rounded, size: 11, color: Color(0xFF25D366)),
      );
    }
    if (lower.contains('instagram')) {
      return const Icon(Icons.camera_alt_rounded, size: 11, color: Color(0xFFDD2A7B));
    }
    if (lower.contains('facebook') || lower.contains('messenger')) {
      return Image.asset(
        'assets/images/channels/messenger.png',
        width: 12,
        height: 12,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.bolt_rounded, size: 11, color: Color(0xFF0084FF)),
      );
    }
    if (lower.contains('telegram')) {
      return const Icon(Icons.send_rounded, size: 11, color: Color(0xFF229ED9));
    }
    if (lower.contains('email')) {
      return const Icon(Icons.mail_rounded, size: 11, color: Color(0xFFEA4335));
    }
    if (lower.contains('sms')) {
      return const Icon(Icons.sms_rounded, size: 11, color: Color(0xFF10B981));
    }
    if (lower.contains('api') || lower.contains('webhook')) {
      return const Icon(Icons.code_rounded, size: 11, color: Color(0xFF6366F1));
    }
    return const Icon(Icons.language_rounded, size: 11, color: Color(0xFF0284C7));
  }
}
