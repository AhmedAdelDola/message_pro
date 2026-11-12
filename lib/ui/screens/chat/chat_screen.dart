import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../data/models/conversation.dart';
import '../../../data/models/message.dart';
import '../../../data/models/user.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/chat/chat_cubit.dart';
import '../../../logic/chat/chat_state.dart';
import '../../../logic/conversation/conversation_cubit.dart';
import '../../widgets/avatar_widget.dart';
import '../contacts/contact_details_screen.dart';
import 'widgets/chat_composer.dart';
import 'widgets/message_bubble.dart';
import 'widgets/canned_responses_sheet.dart';
import 'widgets/assignee_sheet.dart';
import 'widgets/collaborators_sheet.dart';
import 'widgets/send_template_modal.dart';
import 'widgets/workflow_steps_group.dart';
import 'widgets/ai_agent_takeover_banner.dart';
import '../../widgets/app_bar_progress_bar.dart';

abstract class _ChatListItem {
  DateTime get createdAt;
}

class _ChatSingleMessageItem extends _ChatListItem {
  final Message message;
  _ChatSingleMessageItem(this.message);

  @override
  DateTime get createdAt => message.createdAt;
}

class _ChatActivityGroupItem extends _ChatListItem {
  final List<Message> messages;
  _ChatActivityGroupItem(this.messages);

  @override
  DateTime get createdAt => messages.first.createdAt;
}

class ChatScreen extends StatelessWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatCubit>(
      create: (_) => sl<ChatCubit>(
        param1: conversation.id,
        param2: conversation.contactLastSeenAt,
      ),
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
  late String _status;
  late bool _isMuted;
  User? _currentAssignee;
  bool _isTakenOver = false;
  bool _isTakingOver = false;
  int? _lastMessageId;
  bool _initialScrolled = false;
  double? _maxScrollBeforeLoad;

  @override
  void initState() {
    super.initState();
    _status = widget.conversation.status;
    _isMuted = widget.conversation.muted;
    _currentAssignee = widget.conversation.assignee;
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <= 120) {
      _maxScrollBeforeLoad ??= _scrollController.position.maxScrollExtent;
      context.read<ChatCubit>().loadPreviousMessages();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (immediate) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
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
      final nameLower = _currentAssignee!.name.toLowerCase();
      if (nameLower.contains('agent') ||
          nameLower.contains('bot') ||
          nameLower.contains('sales agent') ||
          nameLower.contains('ai') ||
          _currentAssignee!.name.contains('🤖')) {
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
      await chatCubit.assignAgent(currentUserId);
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                child: Text(
                  isArabic ? 'خيارات تأجيل المحادثة' : 'Snooze Conversation',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Gontserrat',
                  ),
                ),
              ),
              const Divider(height: 1),
              if (_status == 'snoozed')
                ListTile(
                  leading: const Icon(Icons.alarm_off_rounded, color: Color(0xFFFA8900)),
                  title: Text(isArabic ? 'إلغاء التأجيل (Unsnooze)' : 'Unsnooze'),
                  subtitle: Text(isArabic ? 'إعادة المحادثة للوضع المفتوح' : 'Revert conversation to open'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final success = await context.read<ChatCubit>().toggleStatus('open');
                    if (mounted && success) {
                      context.read<ConversationCubit>().loadConversations();
                      setState(() => _status = 'open');
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.reply_rounded, color: AppColors.primary),
                title: Text(isArabic ? 'حتى الرد القادم' : 'Until next reply'),
                subtitle: Text(isArabic ? 'تظل مؤجلة حتى يرد العميل' : 'Snooze until customer replies'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final success = await context.read<ChatCubit>().toggleStatus('snoozed');
                  if (mounted && success) {
                    context.read<ConversationCubit>().loadConversations();
                    setState(() => _status = 'snoozed');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.today_rounded, color: Color(0xFF10B981)),
                title: Text(isArabic ? 'حتى الغد 9:00 ص' : 'Tomorrow at 9:00 AM'),
                subtitle: Text(
                  DateFormat('EEEE, d MMM - 9:00 AM').format(
                    DateTime.now().add(const Duration(days: 1)).copyWith(hour: 9, minute: 0, second: 0),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final now = DateTime.now();
                  final tomorrow9am = DateTime(now.year, now.month, now.day + 1, 9, 0, 0);
                  final success = await context.read<ChatCubit>().toggleStatus('snoozed', snoozedUntil: tomorrow9am.toUtc().toIso8601String());
                  if (mounted && success) {
                    context.read<ConversationCubit>().loadConversations();
                    setState(() => _status = 'snoozed');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month_rounded, color: Color(0xFF8B5CF6)),
                title: Text(isArabic ? 'الأسبوع القادم' : 'Next week'),
                subtitle: Text(
                  DateFormat('EEEE, d MMM - 9:00 AM').format(
                    DateTime.now().add(Duration(days: ((8 - DateTime.now().weekday) <= 0 ? 7 : (8 - DateTime.now().weekday)))).copyWith(hour: 9, minute: 0, second: 0),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final now = DateTime.now();
                  final daysUntilNextMonday = (DateTime.monday - now.weekday + 7) % 7;
                  final addDays = daysUntilNextMonday == 0 ? 7 : daysUntilNextMonday;
                  final nextWeekMonday9am = DateTime(now.year, now.month, now.day + addDays, 9, 0, 0);
                  final success = await context.read<ChatCubit>().toggleStatus('snoozed', snoozedUntil: nextWeekMonday9am.toUtc().toIso8601String());
                  if (mounted && success) {
                    context.read<ConversationCubit>().loadConversations();
                    setState(() => _status = 'snoozed');
                  }
                },
              ),
            ],
          ),
        );
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

  void _showAssigneeSheet() {
    final agents = context.read<ConversationCubit>().state.agents;
    final activeAssignee = _currentAssignee ?? widget.conversation.assignee;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) {
        return AssigneeSheet(
          agents: agents,
          currentAssignee: activeAssignee,
          onSelect: (agentId) {
            context.read<ChatCubit>().assignAgent(agentId);
            context.read<ConversationCubit>().loadConversations();
            if (mounted) {
              setState(() {
                if (agentId == null) {
                  _currentAssignee = null;
                } else {
                  _currentAssignee = agents.where((a) => a.id == agentId).firstOrNull ??
                      User(id: agentId, name: 'Agent', email: '', accountId: 0);
                }
              });
            }
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

  @override
  Widget build(BuildContext context) {
    final contact = widget.conversation.contact;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<ChatCubit, ChatState>(
      listener: (context, state) {
        if (state.messages.isEmpty) return;

        final newLastId = state.messages.last.id;
        final hasNewMessage = _lastMessageId != null && newLastId != _lastMessageId;

        if (!_initialScrolled && !state.isLoading && state.messages.isNotEmpty) {
          _initialScrolled = true;
          _lastMessageId = newLastId;
          _scrollToBottom(immediate: true);
        } else if (hasNewMessage) {
          _lastMessageId = newLastId;
          _scrollToBottom();
        }

        if (state.isLoadingOlder && _maxScrollBeforeLoad == null && _scrollController.hasClients) {
          _maxScrollBeforeLoad = _scrollController.position.maxScrollExtent;
        }

        if (_maxScrollBeforeLoad != null && !state.isLoadingOlder) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients && _maxScrollBeforeLoad != null) {
              final diff = _scrollController.position.maxScrollExtent - _maxScrollBeforeLoad!;
              if (diff > 0) {
                _scrollController.jumpTo(_scrollController.position.pixels + diff);
              }
              _maxScrollBeforeLoad = null;
            }
          });
        }
      },
      builder: (context, chatState) {
        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6),
          appBar: AppBar(
            bottom: AppBarProgressBar(
              isLoading: chatState.isLoading,
            ),
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
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                contact.name,
                                style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        if (_status == 'snoozed')
                          Row(
                            children: [
                              Icon(Icons.alarm_rounded, size: 11.r, color: const Color(0xFFFA8900)),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Text(
                                  widget.conversation.snoozedUntil != null
                                      ? 'Snoozed until ${DateFormat('d MMM, h:mma').format(widget.conversation.snoozedUntil!)}'
                                      : 'Snoozed',
                                  style: TextStyle(fontSize: 10.5.sp, color: const Color(0xFFFA8900), fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        else
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
              if (_status == 'snoozed')
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 2.w),
                  child: InkWell(
                    onTap: () async {
                      final convCubit = context.read<ConversationCubit>();
                      final success = await context.read<ChatCubit>().toggleStatus('open');
                      if (mounted && success) {
                        convCubit.loadConversations();
                        setState(() => _status = 'open');
                      }
                    },
                    borderRadius: BorderRadius.circular(6.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFA8900).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(color: const Color(0xFFFA8900), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.alarm_off_rounded, size: 12.r, color: const Color(0xFFFA8900)),
                          SizedBox(width: 3.w),
                          Text(
                            'Unsnooze',
                            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFFFA8900)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Assignee avatar or button
              Builder(
                builder: (context) {
                  final activeAssignee = _currentAssignee ?? widget.conversation.assignee;
                  if (activeAssignee != null) {
                    return InkWell(
                      onTap: _showAssigneeSheet,
                      borderRadius: BorderRadius.circular(16.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 12.r,
                              backgroundColor: const Color(0xFF4162E3).withValues(alpha: 0.2),
                              backgroundImage: activeAssignee.avatarUrl != null &&
                                      activeAssignee.avatarUrl!.isNotEmpty
                                  ? NetworkImage(activeAssignee.avatarUrl!)
                                  : null,
                              child: activeAssignee.avatarUrl == null ||
                                      activeAssignee.avatarUrl!.isEmpty
                                  ? Text(
                                      activeAssignee.name.isNotEmpty
                                          ? activeAssignee.name[0].toUpperCase()
                                          : 'A',
                                      style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4162E3)),
                                    )
                                  : null,
                            ),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 14.r, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  }
                  return IconButton(
                    icon: Icon(Icons.person_add_alt_1_outlined, size: 20.r),
                    tooltip: 'تعيين مسؤول',
                    onPressed: _showAssigneeSheet,
                  );
                },
              ),
              // Collaborators button matching website/webview
              IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedUserGroup,
                  size: 20.r,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
                tooltip: 'المتعاونين (Collaborators)',
                onPressed: _showCollaboratorsSheet,
              ),
              // 3-dots popup menu matching web interface
              PopupMenuButton<String>(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedMoreVertical,
                  size: 20.r,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
                tooltip: 'خيارات المحادثة',
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                onSelected: (value) {
                  switch (value) {
                    case 'resolve_reopen':
                      _toggleResolveReopen();
                      break;
                    case 'snooze':
                      _showSnoozeOptions();
                      break;
                    case 'mute':
                      _toggleMute();
                      break;
                    case 'contact_details':
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ContactDetailsScreen(contact: widget.conversation.contact),
                        ),
                      );
                      break;
                    case 'assign_agent':
                      _showAssigneeSheet();
                      break;
                    case 'collaborators':
                      _showCollaboratorsSheet();
                      break;
                    case 'copy_link':
                      _copyConversationLink();
                      break;
                  }
                },
                itemBuilder: (ctx) {
                  final isResolved = _status == 'resolved';
                  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                  return [
                    PopupMenuItem(
                      value: 'resolve_reopen',
                      child: Row(
                        children: [
                          Icon(
                            isResolved ? Icons.replay_rounded : Icons.check_circle_outline_rounded,
                            color: isResolved ? const Color(0xFF4162E3) : AppColors.success,
                            size: 19.r,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            isResolved
                                ? (isArabic ? 'إعادة فتح المحادثة' : 'Reopen conversation')
                                : (isArabic ? 'إغلاق المحادثة (Resolve)' : 'Resolve conversation'),
                            style: TextStyle(fontSize: 13.sp, fontFamily: 'Gontserrat'),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'snooze',
                      child: Row(
                        children: [
                          Icon(
                            _status == 'snoozed' ? Icons.alarm_off_rounded : Icons.alarm_rounded,
                            color: const Color(0xFFFA8900),
                            size: 19.r,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            _status == 'snoozed'
                                ? (isArabic ? 'إلغاء التأجيل' : 'Unsnooze')
                                : (isArabic ? 'تأجيل المحادثة (Snooze)' : 'Snooze conversation'),
                            style: TextStyle(fontSize: 13.sp, fontFamily: 'Gontserrat'),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'mute',
                      child: Row(
                        children: [
                          Icon(
                            _isMuted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                            color: _isMuted ? AppColors.success : Colors.grey,
                            size: 19.r,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            _isMuted
                                ? (isArabic ? 'إلغاء كتم المحادثة' : 'Unmute conversation')
                                : (isArabic ? 'كتم المحادثة (Mute)' : 'Mute conversation'),
                            style: TextStyle(fontSize: 13.sp, fontFamily: 'Gontserrat'),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'contact_details',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 19.r),
                          SizedBox(width: 10.w),
                          Text(
                            isArabic ? 'عرض بيانات العميل' : 'View contact details',
                            style: TextStyle(fontSize: 13.sp, fontFamily: 'Gontserrat'),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'assign_agent',
                      child: Row(
                        children: [
                          Icon(Icons.assignment_ind_outlined, color: const Color(0xFF10B981), size: 19.r),
                          SizedBox(width: 10.w),
                          Text(
                            isArabic ? 'تعيين مسؤول (Assign)' : 'Assign agent',
                            style: TextStyle(fontSize: 13.sp, fontFamily: 'Gontserrat'),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'collaborators',
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedUserGroup,
                            size: 19.r,
                            color: const Color(0xFF4162E3),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            isArabic ? 'المتعاونين (Collaborators)' : 'Collaborators',
                            style: TextStyle(fontSize: 13.sp, fontFamily: 'Gontserrat'),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'copy_link',
                      child: Row(
                        children: [
                          Icon(Icons.link_rounded, color: const Color(0xFF6366F1), size: 19.r),
                          SizedBox(width: 10.w),
                          Text(
                            isArabic ? 'نسخ رابط المحادثة' : 'Copy conversation link',
                            style: TextStyle(fontSize: 13.sp, fontFamily: 'Gontserrat'),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Muted Conversation Banner
              if (_isMuted)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF232529)
                        : const Color(0xFFF3F4F6),
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_off_rounded, size: 16.r, color: const Color(0xFF80838D)),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          isArabic ? 'إشعارات هذه المحادثة مكتومة' : 'This conversation is muted',
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            color: const Color(0xFF80838D),
                            fontFamily: 'Gontserrat',
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _toggleMute,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: AppColors.primary,
                        ),
                        child: Text(
                          isArabic ? 'إلغاء الكتم' : 'Unmute',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                            fontFamily: 'Gontserrat',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                    ? const SizedBox.shrink()
                    : Builder(
                        builder: (context) {
                          final rawMessages = chatState.messages;

                          final listItems = <_ChatListItem>[];
                          int idx = 0;
                          while (idx < rawMessages.length) {
                            final msg = rawMessages[idx];
                            if (msg.isActivity) {
                              final group = <Message>[msg];
                              int j = idx + 1;
                              while (j < rawMessages.length &&
                                  rawMessages[j].isActivity &&
                                  rawMessages[j].createdAt.day == msg.createdAt.day &&
                                  rawMessages[j].createdAt.month == msg.createdAt.month) {
                                group.add(rawMessages[j]);
                                j++;
                              }
                              if (group.length >= 2) {
                                listItems.add(_ChatActivityGroupItem(group));
                                idx = j;
                                continue;
                              }
                            }
                            listItems.add(_ChatSingleMessageItem(msg));
                            idx++;
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            itemCount: listItems.length,
                            itemBuilder: (context, index) {
                              final item = listItems[index];
                              final prevItem = index > 0 ? listItems[index - 1] : null;
                              final showDateHeader = index == 0 ||
                                  prevItem?.createdAt.day != item.createdAt.day ||
                                  prevItem?.createdAt.month != item.createdAt.month;

                              if (item is _ChatActivityGroupItem) {
                                return WorkflowStepsGroupWidget(
                                  key: ValueKey('activity_group_${item.messages.first.id}_${item.messages.length}'),
                                  messages: item.messages,
                                  showDateHeader: showDateHeader,
                                );
                              } else if (item is _ChatSingleMessageItem) {
                                final msg = item.message;
                                return MessageBubble(
                                  message: msg,
                                  contactName: msg.senderName ?? widget.conversation.contact.name,
                                  contactThumbnail: msg.senderAvatar ?? widget.conversation.contact.avatarUrl,
                                  showDateHeader: showDateHeader,
                                  onRetry: () => context.read<ChatCubit>().retryMessage(msg),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          );
                        },
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

                    return SafeArea(
                      top: false,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                              width: 0.8,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 6.h),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/images/channels/whatsapp.png',
                                    width: 15.r,
                                    height: 15.r,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 15.r,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    channelName,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : const Color(0xFF1F2937),
                                      fontFamily: 'Gontserrat',
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16.r,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 10.h),
                              child: AiAgentTakeoverBanner(
                                agentName: aiAgentName,
                                isLoading: _isTakingOver,
                                onTakeover: _handleTakeover,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ChatComposer(
                    key: _composerKey,
                    isSending: chatState.isSending,
                    channelName: widget.conversation.inboxName ??
                        (widget.conversation.channelType.toLowerCase().contains('whatsapp')
                            ? 'Message-pro'
                            : widget.conversation.channelType),
                    channelType: widget.conversation.channelType,
                    canReply: widget.conversation.canReply,
                    onOpenCannedResponses: _showCannedResponses,
                    onOpenTemplates: _showTemplatesDialog,
                    onSend: (text, isPrivate, attachments) {
                      context.read<ChatCubit>().sendMessage(
                        content: text,
                        isPrivate: isPrivate,
                        attachmentPaths: attachments,
                      );
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
