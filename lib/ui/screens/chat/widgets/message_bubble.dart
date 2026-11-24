import 'package:flutter/material.dart';
import '../../../../data/models/message.dart';
import '../../../../data/models/user.dart';
import 'bubble/activity_bubble_view.dart';
import 'bubble/bubble_action_menu.dart';
import 'bubble/bubble_helpers.dart';
import 'bubble/incoming_bubble_view.dart';
import 'bubble/outgoing_bubble_view.dart';
import 'bubble/private_note_bubble_view.dart';
import 'bubble/swipe_to_reply_wrapper.dart';
import 'bubble/template_bubble_view.dart';

export 'bubble/bubble_helpers.dart';
export 'bubble/swipe_to_reply_wrapper.dart';

/// Single-responsibility MessageBubble coordinator.
/// Delegates rendering to dedicated views based on message type.
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
  final ValueChanged<Message>? onDeleteMessage;
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
    this.onDeleteMessage,
    this.onReact,
    this.onViewReactions,
    this.isHighlighted = false,
  });

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
              BubbleHelpers.formatDate(message.createdAt, isArabic),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF626F7F),
              ),
            ),
          ),

        // Message Body
        if (isActivity)
          ActivityBubbleView(message: message, isDark: isDark)
        else
          SwipeToReplyWrapper(
            isOutgoing: isOutgoing,
            onReply: onReply != null ? () => onReply!(message) : null,
            onDoubleTap: onReply != null ? () => onReply!(message) : null,
            onLongPress: () => showBubbleActionMenu(
              context: context,
              message: message,
              currentUser: currentUser,
              onReply: onReply,
              onEditMessage: onEditMessage,
              onDeleteMessage: onDeleteMessage,
              onReact: onReact,
              onRetry: onRetry,
            ),
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
              child: _buildBubbleContent(context, isDark, isArabic, isPrivate, isOutgoing),
            ),
          ),
      ],
    );
  }

  Widget _buildBubbleContent(
    BuildContext context,
    bool isDark,
    bool isArabic,
    bool isPrivate,
    bool isOutgoing,
  ) {
    if (isPrivate) {
      return PrivateNoteBubbleView(
        message: message,
        isDark: isDark,
        isArabic: isArabic,
      );
    }

    if (message.isTemplate) {
      return TemplateBubbleView(
        message: message,
        repliedMessage: repliedMessage,
        isDark: isDark,
        isArabic: isArabic,
        channel: channel,
        onRetry: onRetry,
        onScrollToMessage: onScrollToMessage,
      );
    }

    if (isOutgoing) {
      return OutgoingBubbleView(
        message: message,
        repliedMessage: repliedMessage,
        isDark: isDark,
        isArabic: isArabic,
        channel: channel,
        onRetry: onRetry,
        onScrollToMessage: onScrollToMessage,
        onViewReactions: onViewReactions,
      );
    }

    return IncomingBubbleView(
      message: message,
      repliedMessage: repliedMessage,
      contactName: contactName,
      contactThumbnail: contactThumbnail,
      isDark: isDark,
      isArabic: isArabic,
      onScrollToMessage: onScrollToMessage,
      onViewReactions: onViewReactions,
    );
  }
}
