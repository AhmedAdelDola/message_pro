import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../data/models/conversation.dart';
import '../../../data/models/contact.dart';
import '../../../data/models/message.dart';
import '../../../data/models/user.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/chat/chat_cubit.dart';
import '../../../logic/chat/chat_state.dart';
import '../../../logic/conversation/conversation_cubit.dart';
import '../contacts/contact_details_screen.dart';
import 'widgets/chat_composer.dart';
import 'widgets/canned_responses_sheet.dart';
import 'widgets/assignee_sheet.dart';
import 'widgets/collaborators_sheet.dart';
import 'widgets/send_template_modal.dart';
import 'widgets/chat_app_bar.dart';
import 'widgets/chat_message_list.dart';
import 'widgets/chat_muted_banner.dart';
import 'widgets/chat_typing_banner.dart';
import 'widgets/chat_ai_takeover_area.dart';
import 'widgets/dialogs/snooze_options_sheet.dart';
import 'widgets/dialogs/edit_message_dialog.dart';
import 'widgets/dialogs/message_reactions_sheet.dart';

class ChatScreen extends StatelessWidget {
  final Conversation conversation;
  final int? initialMessageId;

  const ChatScreen({
    super.key,
    required this.conversation,
    this.initialMessageId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatCubit>(
      create: (_) => sl<ChatCubit>(
        param1: conversation,
        param2: conversation.contactLastSeenAt,
      ),
      child: _ChatScreenContent(
        conversation: conversation,
        initialMessageId: initialMessageId,
      ),
    );
  }
}

class _ChatScreenContent extends StatefulWidget {
  final Conversation conversation;
  final int? initialMessageId;

  const _ChatScreenContent({
    required this.conversation,
    this.initialMessageId,
  });

  @override
  State<_ChatScreenContent> createState() => _ChatScreenContentState();
}

class _ChatScreenContentState extends State<_ChatScreenContent> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ChatComposerState> _composerKey = GlobalKey<ChatComposerState>();
  late String _status;
  late bool _isMuted;
  User? _currentAssignee;
  bool _isTakenOver = false;
  bool _isTakingOver = false;
  int? _lastMessageId;
  bool _initialScrolled = false;
  late Contact _contact;
  Message? _replyingToMessage;
  int? _highlightedMessageId;
  Timer? _highlightTimer;
  bool _hasAttemptedTargetFetch = false;
  bool _hasInitialMessageScrolled = false;
  List<ChatListItem> _lastListItems = [];

  void _onReplyToMessage(Message msg) {
    setState(() => _replyingToMessage = msg);
    _composerKey.currentState?.focusInput();
  }

  void _scrollToMessageById(int messageId, [List<dynamic>? items]) {
    final listItems = items ?? _lastListItems;
    if (!_scrollController.hasClients || listItems.isEmpty) return;
    final reversed = listItems.reversed.toList();
    for (int i = 0; i < reversed.length; i++) {
      final item = reversed[i];
      if (item is ChatSingleMessageItem && item.message.id == messageId) {
        final targetOffset = (i / reversed.length) * _scrollController.position.maxScrollExtent;
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        if (mounted) {
          setState(() => _highlightedMessageId = messageId);
          _highlightTimer?.cancel();
          _highlightTimer = Timer(const Duration(milliseconds: 2500), () {
            if (mounted) setState(() => _highlightedMessageId = null);
          });
        }
        break;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _status = widget.conversation.status;
    _isMuted = widget.conversation.muted;
    _currentAssignee = widget.conversation.assignee;
    _contact = widget.conversation.contact;
    _highlightedMessageId = widget.initialMessageId;
    _scrollController.addListener(_onScroll);

    if (widget.initialMessageId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndLoadTargetMessage();
      });
    }
  }

  void _checkAndLoadTargetMessage() {
    if (widget.initialMessageId == null || _hasAttemptedTargetFetch) return;
    _hasAttemptedTargetFetch = true;
    final cubit = context.read<ChatCubit>();
    if (!cubit.state.messages.any((m) => m.id == widget.initialMessageId)) {
      cubit.loadTargetMessage(widget.initialMessageId!);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // In reverse: true ListView, maxScrollExtent is the top of the chat (oldest messages)
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final chatState = context.read<ChatCubit>().state;
      if (!chatState.isLoadingOlder && chatState.hasMoreMessages) {
        context.read<ChatCubit>().loadPreviousMessages();
      }
    }
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // In reverse: true ListView, 0.0 is the bottom (latest messages)
        if (immediate) {
          _scrollController.jumpTo(0.0);
        } else {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  bool _isAiAgentHandling(Conversation conv, List<Message> messages) {
    if (_isTakenOver) return false;

    final currentUser = context.read<AuthCubit>().currentUser;
    final currentUserId = currentUser?.id;

    if (_currentAssignee != null && currentUserId != null && _currentAssignee?.id == currentUserId) {
      return false;
    }

    if (_status.toLowerCase() == 'bot') return true;

    if (_currentAssignee != null) {
      if (_currentAssignee!.isBot) return true;
      final nameLower = _currentAssignee!.name.trim().toLowerCase();
      if (nameLower == 'sales agent' ||
          nameLower == 'ai agent' ||
          nameLower == 'bot' ||
          nameLower.startsWith('🤖') ||
          nameLower.startsWith('🤠 sales agent')) {
        return true;
      }
    }

    if (conv.isAiAgentHandling) return true;

    for (int i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      final c = (msg.content ?? '').toLowerCase();
      if (c.contains('assigning ai agent') ||
          c.contains('assigned this contact to') ||
          c.contains('assigned to')) {
        if (c.contains('agent') || c.contains('bot') || c.contains('🤖')) {
          return true;
        }
        break;
      }
    }

    return false;
  }

  String _getAiAgentName(Conversation conv, List<Message> messages) {
    if (_currentAssignee != null && _currentAssignee!.name.isNotEmpty) {
      return _currentAssignee!.name;
    }
    for (int i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      final c = msg.content ?? '';
      final regex = RegExp(r'\(([^)]*(?:agent|bot|🤖)[^)]*)\)', caseSensitive: false);
      final match = regex.firstMatch(c);
      if (match != null) {
        return match.group(1) ?? 'Sales agent';
      }
      final regex2 = RegExp(r'to (.*? agent)', caseSensitive: false);
      final match2 = regex2.firstMatch(c);
      if (match2 != null) {
        return match2.group(1) ?? 'Sales agent';
      }
    }
    return 'Sales agent';
  }

  Future<void> _handleTakeover() async {
    final currentUser = context.read<AuthCubit>().currentUser;
    final currentUserId = currentUser?.id;
    if (currentUserId == null) return;

    final chatCubit = context.read<ChatCubit>();
    final convCubit = context.read<ConversationCubit>();

    setState(() {
      _isTakingOver = true;
    });

    try {
      await chatCubit.assignAgent(currentUserId, assigneeType: 'User');
      if (_status.toLowerCase() == 'bot') {
        await chatCubit.toggleStatus('open');
        _status = 'open';
      }
      if (mounted) {
        setState(() {
          _isTakingOver = false;
          _isTakenOver = true;
          _currentAssignee = currentUser;
        });
        convCubit.loadConversations();
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'تم استلام المحادثة وتعيينها لك بنجاح، وتوقف الذكاء الاصطناعي عن الرد.'
                  : 'Conversation assigned to you. AI Agent stopped.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF5850EC),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isTakingOver = false;
        });
      }
    }
  }

  void _toggleResolveReopen() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final targetStatus = _status == 'resolved' ? 'open' : 'resolved';
    final success = await context.read<ChatCubit>().toggleStatus(targetStatus);
    if (!mounted) return;
    if (success) {
      context.read<ConversationCubit>().loadConversations();
      setState(() => _status = targetStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            targetStatus == 'resolved'
                ? (isArabic ? 'تم حل وإغلاق المحادثة' : 'Conversation marked as resolved')
                : (isArabic ? 'تمت إعادة فتح المحادثة' : 'Conversation reopened'),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'تعذر تحديث حالة المحادثة' : 'Failed to update conversation status'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSnoozeOptions() {
    SnoozeOptionsSheet.show(
      context: context,
      status: _status,
      onSnoozeSelected: (snoozedUntil) async {
        final chatCubit = context.read<ChatCubit>();
        final convCubit = context.read<ConversationCubit>();
        final newStatus = snoozedUntil == 'unsnooze' ? 'open' : 'snoozed';
        final success = await chatCubit.toggleStatus(
          newStatus,
          snoozedUntil: snoozedUntil == 'unsnooze' ? null : snoozedUntil,
        );
        if (mounted && success) {
          convCubit.loadConversations();
          setState(() => _status = newStatus);
        }
      },
    );
  }

  Future<void> _toggleMute() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final chatCubit = context.read<ChatCubit>();
    if (_isMuted) {
      await chatCubit.unmuteConversation();
      setState(() => _isMuted = false);
      if (mounted) {
        context.read<ConversationCubit>().loadConversations();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'تم إلغاء كتم المحادثة' : 'Conversation unmuted'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      await chatCubit.muteConversation();
      setState(() => _isMuted = true);
      if (mounted) {
        context.read<ConversationCubit>().loadConversations();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'تم كتم إشعارات المحادثة' : 'Conversation muted'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _copyConversationLink() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final storage = SecureStorageService();
    final baseUrl = await storage.getBaseUrl();
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final link = '$cleanBase/app/accounts/${widget.conversation.accountId}/conversations/${widget.conversation.id}';
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isArabic ? 'تم نسخ رابط المحادثة إلى الحافظة' : 'Conversation link copied to clipboard',
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showEditMessageDialog(BuildContext context, Message message) {
    EditMessageDialog.show(
      context: context,
      message: message,
      onSave: (messageId, newText) {
        return context.read<ChatCubit>().editMessage(messageId, newText);
      },
    );
  }

  void _confirmAndDeleteMessage(BuildContext context, Message message) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isArabic ? 'حذف الرسالة' : 'Delete Message',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من حذف هذه الرسالة لدى الجميع؟ لن يمكن التراجع عن هذا الإجراء.'
              : 'Are you sure you want to delete this message for everyone? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final chatCubit = context.read<ChatCubit>();
              final error = await chatCubit.deleteMessage(message.id, everyone: true);
              if (mounted && error != null) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(isArabic ? 'حذف لدى الجميع' : 'Delete for everyone'),
          ),
        ],
      ),
    );
  }

  Future<void> _onReactToMessage(Message message, String emoji) async {
    final chatCubit = context.read<ChatCubit>();
    final error = await chatCubit.sendReaction(message.id, emoji);
    if (mounted && error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showReactionsBottomSheet(BuildContext context, Message message) {
    MessageReactionsSheet.show(
      context: context,
      message: message,
    );
  }

  void _showAssigneeSheet() {
    final convCubit = context.read<ConversationCubit>();
    var agents = List<User>.from(convCubit.state.agents);

    final activeAssignee = _currentAssignee ?? widget.conversation.assignee;
    final isStatusBot = _status.toLowerCase() == 'bot' || (activeAssignee?.isBot ?? false);
    bool hasFetchedFresh = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Background revalidate ONCE for fresh agents
            if (!hasFetchedFresh) {
              hasFetchedFresh = true;
              convCubit.repo.fetchAssignableAgents(inboxId: widget.conversation.inboxId).then((freshRes) {
                freshRes.fold((_) {}, (freshList) {
                  if (freshList.isNotEmpty && mounted) {
                    setSheetState(() {
                      agents = freshList;
                    });
                  }
                });
              });
            }

            return AssigneeSheet(
              agents: agents,
              teams: convCubit.state.teams,
              currentAssignee: activeAssignee,
              isStatusBot: isStatusBot,
              onSelect: (agentId, {bool isAi = false, String? assigneeType}) async {
                final chatCubit = context.read<ChatCubit>();

                if (isAi) {
                  await chatCubit.assignAgent(agentId, assigneeType: 'AgentBot');
                  convCubit.loadConversations();

                  if (mounted) {
                    final selectedBot = agents.where((a) => a.isBot && a.id == agentId).firstOrNull;
                    setState(() {
                      _isTakenOver = false;
                      _status = 'bot';
                      _currentAssignee = selectedBot ??
                          User(
                            id: agentId ?? -1,
                            name: 'AI Agent',
                            email: '',
                            accountId: widget.conversation.accountId,
                            assigneeType: 'AgentBot',
                            type: 'ai_agent',
                            emoji: '🤖',
                          );
                    });
                  }
                } else {
                  // Human agent or Unassigned
                  await chatCubit.assignAgent(agentId, assigneeType: agentId != null ? 'User' : null);

                  convCubit.loadConversations();

                  if (mounted) {
                    setState(() {
                      _isTakenOver = true;
                      if (agentId == null) {
                        _currentAssignee = null;
                      } else {
                        _currentAssignee = agents.where((a) => !a.isBot && a.id == agentId).firstOrNull ??
                            User(id: agentId, name: 'Agent', email: '', accountId: 0, assigneeType: 'User');
                      }
                    });
                  }
                }
              },
            );
          },
        );
      },
    );
  }

  void _showCollaboratorsSheet() {
    final agents = context.read<ConversationCubit>().state.agents;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return CollaboratorsSheet(
          conversationId: widget.conversation.id,
          workspaceAgents: agents,
          assignee: widget.conversation.assignee,
          chatCubit: context.read<ChatCubit>(),
          onCollaboratorsChanged: () {
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
          onSelectResponse: (content, fileUrls) {
            _composerKey.currentState?.insertSnippet(text: content, fileUrls: fileUrls);
          },
        );
      },
    );
  }

  Future<void> _showTemplatesDialog() async {
    final chatCubit = context.read<ChatCubit>();
    final templates = await chatCubit.fetchTemplates(widget.conversation.inboxId);
    if (!mounted) return;

    SendTemplateModal.show(
      context: context,
      templates: templates,
      onSend: (template) {
        chatCubit.sendTemplate(
          templateName: template.name,
          category: template.category,
          language: template.language,
          content: template.fullText,
        );
        _scrollToBottom();
      },
    );
  }

  Future<void> _navigateToContactDetails() async {
    final updated = await Navigator.of(context).push<Contact>(
      MaterialPageRoute(
        builder: (_) => ContactDetailsScreen(
          contact: _contact,
          conversationId: widget.conversation.id,
          onContactUpdated: (newContact) {
            if (mounted) setState(() => _contact = newContact);
          },
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _contact = updated);
    }
  }

  Future<void> _handleUnsnooze() async {
    final convCubit = context.read<ConversationCubit>();
    final success = await context.read<ChatCubit>().toggleStatus('open');
    if (mounted && success) {
      convCubit.loadConversations();
      setState(() => _status = 'open');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<ChatCubit, ChatState>(
      listener: (context, state) {
        if (state.messages.isEmpty) return;

        final newLastId = state.messages.last.id;
        final hasNewMessage = _lastMessageId != null && newLastId != _lastMessageId;

        if (widget.initialMessageId != null && !_hasInitialMessageScrolled) {
          final hasTarget = state.messages.any((m) => m.id == widget.initialMessageId);
          if (hasTarget) {
            _hasInitialMessageScrolled = true;
            _initialScrolled = true;
            _lastMessageId = newLastId;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToMessageById(widget.initialMessageId!);
            });
          }
        }

        if (!_initialScrolled && !state.isLoading && state.messages.isNotEmpty) {
          _initialScrolled = true;
          _lastMessageId = newLastId;
          if (widget.initialMessageId == null) {
            _scrollToBottom(immediate: true);
          }
        } else if (hasNewMessage) {
          _lastMessageId = newLastId;
          // Only auto-scroll to bottom if user is already near the bottom (latest messages)
          final isNearBottom = !_scrollController.hasClients || _scrollController.position.pixels <= 150;
          if (isNearBottom) {
            _scrollToBottom();
          }
        }
      },
      builder: (context, chatState) {
        final chatCubit = context.read<ChatCubit>();
        if (chatCubit.renderStopwatch.isRunning) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (chatCubit.renderStopwatch.isRunning) {
              chatCubit.renderStopwatch.stop();
              final ms = chatCubit.renderStopwatch.elapsedMilliseconds;
              final micro = chatCubit.renderStopwatch.elapsedMicroseconds;
              debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
              debugPrint('💬 [الشات Chat] الوقت الفعلي لظهور الرسائل على الشاشة:');
              debugPrint('👉 $ms مللي ثانية ($micro ميكروثانية)');
              debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            }
          });
        }

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6),
          appBar: ChatAppBar(
            conversation: widget.conversation,
            contact: _contact,
            status: _status,
            isMuted: _isMuted,
            isLoading: chatState.isLoading || chatState.isLoadingOlder,
            currentAssignee: _currentAssignee,
            onContactTap: _navigateToContactDetails,
            onUnsnoozeTap: _handleUnsnooze,
            onAssigneeTap: _showAssigneeSheet,
            onCollaboratorsTap: _showCollaboratorsSheet,
            onToggleResolveReopen: _toggleResolveReopen,
            onSnoozeOptionsTap: _showSnoozeOptions,
            onToggleMute: _toggleMute,
            onCopyLink: _copyConversationLink,
            onCannedResponsesTap: _showCannedResponses,
          ),
          body: Column(
            children: [
              // Muted Conversation Banner
              if (_isMuted)
                ChatMutedBanner(onUnmute: _toggleMute),
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
              ChatTypingBanner(typingUsers: chatState.typingUsers),

              // Messages List
              Expanded(
                child: chatState.isLoading && chatState.messages.isEmpty
                    ? const SizedBox.shrink()
                    : ChatMessageList(
                        messages: chatState.messages,
                        scrollController: _scrollController,
                        highlightedMessageId: _highlightedMessageId,
                        conversation: widget.conversation,
                        currentUser: context.read<AuthCubit>().currentUser,
                        onReply: _onReplyToMessage,
                        onScrollToMessage: _scrollToMessageById,
                        onEditMessage: (m) => _showEditMessageDialog(context, m),
                        onDeleteMessage: (m) => _confirmAndDeleteMessage(context, m),
                        onReact: (m, emoji) => _onReactToMessage(m, emoji),
                        onViewReactions: (m) => _showReactionsBottomSheet(context, m),
                        onRetry: (m) => context.read<ChatCubit>().retryMessage(m),
                        onRefresh: () => context.read<ChatCubit>().loadPreviousMessages(),
                        onItemsCalculated: (items) => _lastListItems = items,
                      ),
              ),

              // Bottom Area: AI Agent Takeover Banner IN PLACE OF Chat Composer when bot is handling
              Builder(
                builder: (context) {
                  final isAiHandling = _isAiAgentHandling(widget.conversation, chatState.messages);
                  if (isAiHandling) {
                    final aiAgentName = _getAiAgentName(widget.conversation, chatState.messages);
                    final channelName = widget.conversation.inboxName ??
                        (widget.conversation.channelType.toLowerCase().contains('whatsapp')
                            ? 'Message-pro'
                            : widget.conversation.channelType);

                    return ChatAiTakeoverArea(
                      channelName: channelName,
                      aiAgentName: aiAgentName,
                      isTakingOver: _isTakingOver,
                      onTakeover: _handleTakeover,
                    );
                  }

                  final convCubit = context.read<ConversationCubit>();
                  final workspaceAgents = convCubit.state.agents;

                  return ChatComposer(
                    key: _composerKey,
                    isSending: chatState.isSending,
                    channelName: widget.conversation.inboxName ??
                        (widget.conversation.channelType.toLowerCase().contains('whatsapp')
                            ? 'Message-pro'
                            : widget.conversation.channelType),
                    channelType: widget.conversation.channelType,
                    canReply: widget.conversation.canReply,
                    cannedResponses: chatState.cannedResponses,
                    agents: workspaceAgents,
                    replyingToMessage: _replyingToMessage,
                    onCancelReply: () => setState(() => _replyingToMessage = null),
                    onOpenCannedResponses: _showCannedResponses,
                    onOpenTemplates: _showTemplatesDialog,
                    onSend: (text, isPrivate, attachments, [inReplyToId]) {
                      context.read<ChatCubit>().sendMessage(
                        content: text,
                        isPrivate: isPrivate,
                        attachmentPaths: attachments,
                        inReplyToId: inReplyToId,
                      );
                      setState(() => _replyingToMessage = null);
                      _scrollToBottom();
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
