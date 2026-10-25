import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/models/conversation.dart';
import '../../../logic/chat/chat_cubit.dart';
import '../../../logic/chat/chat_state.dart';
import '../../../logic/conversation/conversation_cubit.dart';
import '../../widgets/avatar_widget.dart';
import '../contacts/contact_details_screen.dart';
import 'widgets/chat_composer.dart';
import 'widgets/message_bubble.dart';
import 'widgets/canned_responses_sheet.dart';
import 'widgets/assignee_sheet.dart';

class ChatScreen extends StatelessWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatCubit>(
      create: (_) => sl<ChatCubit>(param1: conversation.id),
      child: _ChatScreenContent(conversation: conversation),
    );
  }
}

class _ChatScreenContent extends StatefulWidget {
  final Conversation conversation;

  const _ChatScreenContent({required this.conversation});

  @override
  State<_ChatScreenContent> createState() => _ChatScreenContentState();
}

class _ChatScreenContentState extends State<_ChatScreenContent> {
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16.0.r),
                child: Text('تغيير حالة المحادثة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: AppColors.success),
                title: const Text('مفتوحة (Open)'),
                onTap: () {
                  context.read<ChatCubit>().toggleStatus('open');
                  context.read<ConversationCubit>().loadConversations();
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.done_all, color: Colors.grey),
                title: const Text('إغلاق المحادثة (Resolved)'),
                onTap: () {
                  context.read<ChatCubit>().toggleStatus('resolved');
                  context.read<ConversationCubit>().loadConversations();
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.alarm, color: AppColors.warning),
                title: const Text('تأجيل (Snoozed)'),
                onTap: () {
                  context.read<ChatCubit>().toggleStatus('snoozed');
                  context.read<ConversationCubit>().loadConversations();
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.pause_circle_outline, color: AppColors.info),
                title: const Text('معلقة (Pending)'),
                onTap: () {
                  context.read<ChatCubit>().toggleStatus('pending');
                  context.read<ConversationCubit>().loadConversations();
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAssigneeSheet() {
    final agents = context.read<ConversationCubit>().state.agents;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) {
        return AssigneeSheet(
          agents: agents,
          currentAssignee: widget.conversation.assignee,
          onSelect: (agentId) {
            context.read<ChatCubit>().assignAgent(agentId);
            context.read<ConversationCubit>().loadConversations();
          },
        );
      },
    );
  }

  void _showCannedResponses() {
    final canned = context.read<ChatCubit>().state.cannedResponses;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) {
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
    final contact = widget.conversation.contact;

    return BlocConsumer<ChatCubit, ChatState>(
      listener: (context, state) {
        _scrollToBottom();
      },
      builder: (context, chatState) {
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
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          contact.phoneNumber ?? contact.email ?? 'المحادثة #${widget.conversation.id}',
                          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
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
                icon: Icon(Icons.person_add_alt_1_outlined, size: 22.r),
                tooltip: 'تعيين مسؤول',
                onPressed: _showAssigneeSheet,
              ),
              IconButton(
                icon: Icon(Icons.more_vert_rounded, size: 22.r),
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
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  color: Colors.blue.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12.r,
                        height: 12.r,
                        child: const CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${chatState.typingUsers.join(', ')} يكتب الآن...',
                        style: TextStyle(fontSize: 12.sp, color: Colors.blue, fontStyle: FontStyle.italic),
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
                        padding: EdgeInsets.symmetric(vertical: 12.h),
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
                  context.read<ChatCubit>().sendMessage(
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
      },
    );
  }
}
