import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/conversation.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/conversation_provider.dart';
import '../../widgets/avatar_widget.dart';
import '../contacts/contact_details_screen.dart';
import 'widgets/chat_composer.dart';
import 'widgets/message_bubble.dart';
import 'widgets/canned_responses_sheet.dart';
import 'widgets/assignee_sheet.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ChatComposerState> _composerKey = GlobalKey<ChatComposerState>();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showStatusDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('تغيير حالة المحادثة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: AppColors.success),
                title: const Text('مفتوحة (Open)'),
                onTap: () {
                  ref.read(chatProvider(widget.conversation.id).notifier).toggleStatus('open');
                  ref.read(conversationProvider.notifier).loadConversations();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.done_all, color: Colors.grey),
                title: const Text('إغلاق المحادثة (Resolved)'),
                onTap: () {
                  ref.read(chatProvider(widget.conversation.id).notifier).toggleStatus('resolved');
                  ref.read(conversationProvider.notifier).loadConversations();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.alarm, color: AppColors.warning),
                title: const Text('تأجيل (Snoozed)'),
                onTap: () {
                  ref.read(chatProvider(widget.conversation.id).notifier).toggleStatus('snoozed');
                  ref.read(conversationProvider.notifier).loadConversations();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.pause_circle_outline, color: AppColors.info),
                title: const Text('معلقة (Pending)'),
                onTap: () {
                  ref.read(chatProvider(widget.conversation.id).notifier).toggleStatus('pending');
                  ref.read(conversationProvider.notifier).loadConversations();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAssigneeSheet() {
    final agents = ref.read(conversationProvider).agents;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return AssigneeSheet(
          agents: agents,
          currentAssignee: widget.conversation.assignee,
          onSelect: (agentId) {
            ref.read(chatProvider(widget.conversation.id).notifier).assignAgent(agentId);
            ref.read(conversationProvider.notifier).loadConversations();
          },
        );
      },
    );
  }

  void _showCannedResponses() {
    final canned = ref.read(chatProvider(widget.conversation.id)).cannedResponses;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return CannedResponsesSheet(
          responses: canned,
          onSelect: (content) {
            _composerKey.currentState?.insertText(content);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.conversation.id));
    final contact = widget.conversation.contact;

    ref.listen(chatProvider(widget.conversation.id), (previous, next) {
      if ((previous?.messages.length ?? 0) < next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ContactDetailsScreen(contact: contact),
              ),
            );
          },
          child: Row(
            children: [
              AvatarWidget(
                avatarUrl: contact.avatarUrl,
                name: contact.name,
                size: 38,
                channel: widget.conversation.channel,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      contact.phoneNumber ?? contact.email ?? 'المحادثة #${widget.conversation.id}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: 'تعيين مسؤول',
            onPressed: _showAssigneeSheet,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'حالة المحادثة',
            onPressed: _showStatusDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Typing Indicator Banner
          if (chatState.typingUsers.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: Colors.blue.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${chatState.typingUsers.join(', ')} يكتب الآن...',
                    style: const TextStyle(fontSize: 12, color: Colors.blue, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

          // Messages List
          Expanded(
            child: chatState.isLoading && chatState.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatState.messages[index];
                      return MessageBubble(message: msg);
                    },
                  ),
          ),

          // Chat Composer
          ChatComposer(
            key: _composerKey,
            isSending: chatState.isSending,
            onOpenCannedResponses: _showCannedResponses,
            onSend: (text, isPrivate, attachments) {
              ref.read(chatProvider(widget.conversation.id).notifier).sendMessage(
                content: text,
                isPrivate: isPrivate,
                attachmentPaths: attachments,
              );
              _scrollToBottom();
            },
          ),
        ],
      ),
    );
  }
}
