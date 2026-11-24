import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/conversation.dart';

class ConversationTilePreview extends StatelessWidget {
  final Conversation conversation;
  final String lastMessageText;
  final bool isDark;

  const ConversationTilePreview({
    super.key,
    required this.conversation,
    required this.lastMessageText,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final lastMsg = conversation.lastMessage;
    final isPrivate = lastMsg?.isPrivateNote ?? false;
    final isOutgoing = lastMsg?.isOutgoing ?? false;

    return Row(
      children: [
        if (isPrivate) ...[
          const Icon(
            Icons.lock_rounded,
            size: 13,
            color: Color(0xFFFA8900),
          ),
          const SizedBox(width: 4),
        ] else if (isOutgoing) ...[
          const Icon(
            Icons.keyboard_arrow_up_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 2),
        ],
        Expanded(
          child: Text(
            lastMessageText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
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
              ),
            ),
          ),
        ],
      ],
    );
  }
}
