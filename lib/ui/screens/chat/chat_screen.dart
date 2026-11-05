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
import '../../../logic/chat/chat_cubit.dart';
import '../../../logic/chat/chat_state.dart';
import '../../../logic/conversation/conversation_cubit.dart';
import '../../widgets/avatar_widget.dart';
import '../contacts/contact_details_screen.dart';
import 'widgets/chat_composer.dart';
import 'widgets/message_bubble.dart';
import 'widgets/canned_responses_sheet.dart';
import 'widgets/assignee_sheet.dart';
import 'widgets/send_template_modal.dart';

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

  @override
  void initState() {
    super.initState();
    _status = widget.conversation.status;
    _isMuted = widget.conversation.muted;
  }

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

  void _toggleResolveReopen() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final newStatus = _status == 'resolved' ? 'open' : 'resolved';
    context.read<ChatCubit>().toggleStatus(newStatus);
    context.read<ConversationCubit>().loadConversations();
    setState(() => _status = newStatus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus == 'resolved'
              ? (isArabic ? 'تم حل وإغلاق المحادثة' : 'Conversation marked as resolved')
              : (isArabic ? 'تمت إعادة فتح المحادثة' : 'Conversation reopened'),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<ChatCubit>().toggleStatus('open');
                    context.read<ConversationCubit>().loadConversations();
                    setState(() => _status = 'open');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.reply_rounded, color: AppColors.primary),
                title: Text(isArabic ? 'حتى الرد القادم' : 'Until next reply'),
                subtitle: Text(isArabic ? 'تظل مؤجلة حتى يرد العميل' : 'Snooze until customer replies'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<ChatCubit>().toggleStatus('snoozed');
                  context.read<ConversationCubit>().loadConversations();
                  setState(() => _status = 'snoozed');
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
                onTap: () {
                  Navigator.pop(ctx);
                  final now = DateTime.now();
                  final tomorrow9am = DateTime(now.year, now.month, now.day + 1, 9, 0, 0);
                  context.read<ChatCubit>().toggleStatus('snoozed', snoozedUntil: tomorrow9am.toUtc().toIso8601String());
                  context.read<ConversationCubit>().loadConversations();
                  setState(() => _status = 'snoozed');
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
                onTap: () {
                  Navigator.pop(ctx);
                  final now = DateTime.now();
                  final daysUntilNextMonday = (DateTime.monday - now.weekday + 7) % 7;
                  final addDays = daysUntilNextMonday == 0 ? 7 : daysUntilNextMonday;
                  final nextWeekMonday9am = DateTime(now.year, now.month, now.day + addDays, 9, 0, 0);
                  context.read<ChatCubit>().toggleStatus('snoozed', snoozedUntil: nextWeekMonday9am.toUtc().toIso8601String());
                  context.read<ConversationCubit>().loadConversations();
                  setState(() => _status = 'snoozed');
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
                    onTap: () {
                      context.read<ChatCubit>().toggleStatus('open');
                      context.read<ConversationCubit>().loadConversations();
                      setState(() => _status = 'open');
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
              if (widget.conversation.assignee != null)
                InkWell(
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
                          backgroundImage: widget.conversation.assignee!.avatarUrl != null &&
                                  widget.conversation.assignee!.avatarUrl!.isNotEmpty
                              ? NetworkImage(widget.conversation.assignee!.avatarUrl!)
                              : null,
                          child: widget.conversation.assignee!.avatarUrl == null ||
                                  widget.conversation.assignee!.avatarUrl!.isEmpty
                              ? Text(
                                  widget.conversation.assignee!.name.isNotEmpty
                                      ? widget.conversation.assignee!.name[0].toUpperCase()
                                      : 'A',
                                  style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4162E3)),
                                )
                              : null,
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 14.r, color: Colors.grey),
                      ],
                    ),
                  ),
                )
              else
                IconButton(
                  icon: Icon(Icons.person_add_alt_1_outlined, size: 20.r),
                  tooltip: 'تعيين مسؤول',
                  onPressed: _showAssigneeSheet,
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
                          final showDateHeader = index == 0 ||
                              chatState.messages[index - 1].createdAt.day != msg.createdAt.day ||
                              chatState.messages[index - 1].createdAt.month != msg.createdAt.month;
                          return MessageBubble(
                            message: msg,
                            contactName: msg.senderName ?? widget.conversation.contact.name,
                            contactThumbnail: msg.senderAvatar ?? widget.conversation.contact.avatarUrl,
                            showDateHeader: showDateHeader,
                            onRetry: () => context.read<ChatCubit>().retryMessage(msg),
                          );
                        },
                      ),
              ),

              // Chat Composer
              ChatComposer(
                key: _composerKey,
                isSending: chatState.isSending,
                channelName: widget.conversation.inboxName ?? (widget.conversation.channelType.toLowerCase().contains('whatsapp') ? 'Message-pro' : widget.conversation.channelType),
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
              ),
            ],
          ),
        );
      },
    );
  }
}
