import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../data/models/conversation.dart';
import '../../../../data/models/message.dart';
import '../../../../data/models/user.dart';
import 'message_bubble.dart';
import 'workflow_steps_group.dart';

abstract class ChatListItem {
  DateTime get createdAt;
}

class ChatSingleMessageItem extends ChatListItem {
  final Message message;
  ChatSingleMessageItem(this.message);

  @override
  DateTime get createdAt => message.createdAt;
}

class ChatActivityGroupItem extends ChatListItem {
  final List<Message> messages;
  ChatActivityGroupItem(this.messages);

  @override
  DateTime get createdAt => messages.first.createdAt;
}

class ChatMessageList extends StatelessWidget {
  final List<Message> messages;
  final ScrollController scrollController;
  final int? highlightedMessageId;
  final Conversation conversation;
  final User? currentUser;
  final ValueChanged<Message> onReply;
  final void Function(int messageId, [List<dynamic>? items]) onScrollToMessage;
  final ValueChanged<Message> onEditMessage;
  final ValueChanged<Message>? onDeleteMessage;
  final void Function(Message message, String emoji) onReact;
  final ValueChanged<Message> onViewReactions;
  final ValueChanged<Message> onRetry;
  final Future<void> Function() onRefresh;
  final void Function(List<ChatListItem> items)? onItemsCalculated;

  const ChatMessageList({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.highlightedMessageId,
    required this.conversation,
    required this.currentUser,
    required this.onReply,
    required this.onScrollToMessage,
    required this.onEditMessage,
    this.onDeleteMessage,
    required this.onReact,
    required this.onViewReactions,
    required this.onRetry,
    required this.onRefresh,
    this.onItemsCalculated,
  });

  @override
  Widget build(BuildContext context) {
    final listItems = <ChatListItem>[];
    int idx = 0;
    while (idx < messages.length) {
      final msg = messages[idx];
      if (msg.isActivity) {
        final group = <Message>[msg];
        int j = idx + 1;
        while (j < messages.length &&
            rawActivityMatches(messages[j], msg)) {
          group.add(messages[j]);
          j++;
        }
        if (group.length >= 2) {
          listItems.add(ChatActivityGroupItem(group));
          idx = j;
          continue;
        }
      }
      listItems.add(ChatSingleMessageItem(msg));
      idx++;
    }

    onItemsCalculated?.call(listItems);

    // Reversed list items: index 0 is the newest message (bottom),
    // and the last index is the oldest message (top).
    final reversedItems = listItems.reversed.toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: scrollController,
        reverse: true,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        itemCount: reversedItems.length,
        itemBuilder: (context, index) {
          final item = reversedItems[index];
          final nextItem = index < reversedItems.length - 1 ? reversedItems[index + 1] : null;
          // In reverse list, the chronologically previous item is nextItem (higher index = older)
          final showDateHeader = nextItem == null ||
              nextItem.createdAt.day != item.createdAt.day ||
              nextItem.createdAt.month != item.createdAt.month;

          if (item is ChatActivityGroupItem) {
            return WorkflowStepsGroupWidget(
              key: ValueKey('activity_group_${item.messages.first.id}_${item.messages.length}'),
              messages: item.messages,
              showDateHeader: showDateHeader,
            );
          } else if (item is ChatSingleMessageItem) {
            final msg = item.message;
            Message? quotedMsg;
            if (msg.inReplyToId != null) {
              for (final other in messages) {
                if (other.id == msg.inReplyToId) {
                  quotedMsg = other;
                  break;
                }
              }
            }
            return MessageBubble(
              message: msg,
              isHighlighted: msg.id == highlightedMessageId,
              channel: conversation.channelType,
              currentUser: currentUser,
              contactName: msg.senderName ?? conversation.contact.name,
              contactThumbnail: msg.senderAvatar ?? conversation.contact.avatarUrl,
              showDateHeader: showDateHeader,
              onRetry: () => onRetry(msg),
              repliedMessage: quotedMsg,
              onReply: onReply,
              onScrollToMessage: (id) => onScrollToMessage(id, listItems),
              onEditMessage: onEditMessage,
              onDeleteMessage: onDeleteMessage,
              onReact: onReact,
              onViewReactions: onViewReactions,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  static bool rawActivityMatches(Message current, Message first) {
    return current.isActivity &&
        current.createdAt.day == first.createdAt.day &&
        current.createdAt.month == first.createdAt.month;
  }
}
