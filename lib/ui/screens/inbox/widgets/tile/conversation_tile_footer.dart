import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/contact.dart';
import '../../../../../data/models/conversation.dart';
import 'channel_small_icon.dart';

class ConversationTileFooter extends StatelessWidget {
  final Conversation conversation;
  final bool isDark;

  const ConversationTileFooter({
    super.key,
    required this.conversation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final stage = conversation.effectiveLifecycleStage ?? conversation.contact.lifecycleStage;
    final stageName = stage?.name ?? 'New Lead';
    final stageEmoji = stage?.icon ?? LifecycleStage.getEmojiForStage(stageName);

    final assignee = conversation.assignee;
    final aName = assignee?.name.trim() ?? '';
    final assigneeInitial = aName.isNotEmpty ? aName[0].toUpperCase() : 'A';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              // Lifecycle Stage Badge
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Labels / Tags Badges
              if (conversation.labels.isNotEmpty) ...[
                for (final tag in conversation.labels.take(2)) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.label_outline_rounded,
                          size: 10,
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 3),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 65),
                          child: Text(
                            tag,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (conversation.labels.length > 2) ...[
                  const SizedBox(width: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '+${conversation.labels.length - 2}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                ],
              ],

              // Inbox / Channel Badge
              if (conversation.inboxName != null && conversation.inboxName!.trim().isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2024) : const Color(0xFFF1F2F4),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChannelSmallIcon(channelType: conversation.channelType),
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
    );
  }
}
