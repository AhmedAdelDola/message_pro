import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/data/models/contact.dart';
import 'package:message_pro/data/models/conversation.dart';
import 'package:message_pro/logic/conversation/conversation_cubit.dart';
import 'package:message_pro/ui/widgets/avatar_widget.dart';
import 'tile/conversation_tile_helper.dart';
import 'tile/conversation_tile_header.dart';
import 'tile/conversation_tile_preview.dart';
import 'tile/conversation_tile_footer.dart';

/// Clean, decomposed conversation list item widget.
/// Follows Single Responsibility Principle by orchestrating atomic row components.
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final displayName = ConversationTileHelper.resolveDisplayName(
      conversation,
      isArabic,
    );
    final lastMessageText = ConversationTileHelper.resolveLastMessagePreview(
      conversation,
      isArabic,
    );
    final formattedTime = ConversationTileHelper.formatTime(
      conversation.updatedAt,
      isArabic,
    );

    List<Inbox> inboxes = const [];
    try {
      inboxes = context.read<ConversationCubit>().state.inboxes;
    } catch (_) {}
    final resolvedChannel = ConversationTileHelper.resolveChannel(
      conversation,
      inboxes,
      displayName,
    );

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarWidget(
              avatarUrl: conversation.contact.avatarUrl,
              name: displayName,
              size: 38,
              channel: resolvedChannel,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConversationTileHeader(
                    conversation: conversation,
                    displayName: displayName,
                    formattedTime: formattedTime,
                    isArabic: isArabic,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 3),
                  ConversationTilePreview(
                    conversation: conversation,
                    lastMessageText: lastMessageText,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  ConversationTileFooter(
                    conversation: conversation,
                    isDark: isDark,
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
