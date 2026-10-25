import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/conversation.dart';
import '../../../widgets/avatar_widget.dart';
import '../../../widgets/status_badge.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0 && now.day == dt.day) {
      return DateFormat('hh:mm a').format(dt);
    } else if (now.difference(dt).inDays < 7) {
      return DateFormat('EEEE').format(dt);
    }
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lastMsg = conversation.lastMessage;
    final contact = conversation.contact;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: conversation.unreadCount > 0
              ? (isDark ? const Color(0xFF1F2430) : const Color(0xFFF0F4FF))
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.8,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarWidget(
              avatarUrl: contact.avatarUrl,
              name: contact.name,
              size: 48,
              channel: conversation.channel,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          contact.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textDarkPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(conversation.updatedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: conversation.unreadCount > 0
                              ? AppColors.primaryLight
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          fontWeight: conversation.unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: lastMsg?.isPrivateNote == true
                            ? Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'ملاحظة',
                                      style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      lastMsg?.content ?? 'ملاحظة داخلية جديدة',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                lastMsg?.content ?? 'بدء محادثة جديدة',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: conversation.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                  color: conversation.unreadCount > 0
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                ),
                              ),
                      ),
                      if (conversation.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      StatusBadge(status: conversation.status),
                      if (conversation.lifecycleStage != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(int.parse(conversation.lifecycleStage!.color.replaceAll('#', '0xFF'))).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (conversation.lifecycleStage!.icon != null) ...[
                                Text(conversation.lifecycleStage!.icon!, style: const TextStyle(fontSize: 10)),
                                const SizedBox(width: 3),
                              ],
                              Text(
                                conversation.lifecycleStage!.name,
                                style: TextStyle(
                                  color: Color(int.parse(conversation.lifecycleStage!.color.replaceAll('#', '0xFF'))),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (conversation.assignee != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AvatarWidget(
                              avatarUrl: conversation.assignee!.avatarUrl,
                              name: conversation.assignee!.name,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              conversation.assignee!.name,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'غير معين',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
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
}
