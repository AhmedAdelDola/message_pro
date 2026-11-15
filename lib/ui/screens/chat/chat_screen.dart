import 'dart:async';
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
import '../../../data/models/contact.dart';
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
        param1: conversation.id,
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
  double? _maxScrollBeforeLoad;
  double? _pixelsBeforeLoad;
  late Contact _contact;
  Message? _replyingToMessage;
  int? _highlightedMessageId;
  Timer? _highlightTimer;
  bool _hasAttemptedTargetFetch = false;
  bool _hasInitialMessageScrolled = false;
  List<_ChatListItem> _lastListItems = [];

  void _onReplyToMessage(Message msg) {
    setState(() => _replyingToMessage = msg);
    _composerKey.currentState?.focusInput();
  }

  void _scrollToMessageById(int messageId, [List<dynamic>? items]) {
    final listItems = items ?? _lastListItems;
    if (!_scrollController.hasClients || listItems.isEmpty) return;
    for (int i = 0; i < listItems.length; i++) {
      final item = listItems[i];
      if (item is _ChatSingleMessageItem && item.message.id == messageId) {
        final targetOffset = (i / listItems.length) * _scrollController.position.maxScrollExtent;
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
    if (_scrollController.position.pixels <= 120) {
      final chatState = context.read<ChatCubit>().state;
      if (!chatState.isLoadingOlder && chatState.hasMoreMessages) {
        _maxScrollBeforeLoad = _scrollController.position.maxScrollExtent;
        _pixelsBeforeLoad = _scrollController.position.pixels;
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

  void _showEditMessageDialog(BuildContext context, Message message) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textController = TextEditingController(text: message.content ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dlgContext) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final remaining = message.messageActions.remainingEditTime;
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF161616) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.edit_rounded, color: Color(0xFF4162E3), size: 22),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'تعديل الرسالة' : 'Edit Message',
                  style: const TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (remaining != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isArabic
                                ? 'متاح للتعديل خلال ${remaining.inMinutes} دقيقة'
                                : 'Editable for ${remaining.inMinutes} minutes',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                TextField(
                  controller: textController,
                  maxLines: 4,
                  minLines: 2,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: isArabic ? 'اكتب النص الجديد هنا...' : 'Enter new message text...',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF383838) : const Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF4162E3), width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dlgContext),
                child: Text(isArabic ? 'إلغاء' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final newText = textController.text.trim();
                        if (newText.isEmpty) return;
                        setDlgState(() => isSaving = true);

                        final chatCubit = context.read<ChatCubit>();
                        final error = await chatCubit.editMessage(message.id, newText);

                        if (context.mounted) {
                          if (error != null) {
                            setDlgState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            Navigator.pop(dlgContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isArabic ? 'تم تعديل الرسالة بنجاح' : 'Message edited successfully'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4162E3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isArabic ? 'حفظ التعديل' : 'Save'),
              ),
            ],
          );
        },
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatCubit = context.read<ChatCubit>();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161616) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF31343A) : const Color(0xFFEAEAEA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    isArabic ? 'التفاعلات على الرسالة' : 'Message Reactions',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Gontserrat'),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4162E3).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${message.reactions.length}',
                      style: const TextStyle(color: Color(0xFF4162E3), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: FutureBuilder(
                future: chatCubit.getReactions(message.id, contentAttributes: message.contentAttributes),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final result = snapshot.data;
                  if (result == null || result.isLeft()) {
                    if (message.reactions.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            isArabic ? 'لا توجد تفاعلات' : 'No reactions',
                            style: const TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: message.reactions.length,
                      itemBuilder: (_, i) {
                        final r = message.reactions[i];
                        return ListTile(
                          title: Text(r.userName ?? (isArabic ? 'مشارك' : 'Participant')),
                          trailing: Text(r.emoji, style: const TextStyle(fontSize: 22)),
                        );
                      },
                    );
                  }

                  final participants = result.getOrElse(() => []);
                  if (participants.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          isArabic ? 'لا توجد تفاعلات' : 'No reactions',
                          style: const TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: participants.length,
                    itemBuilder: (_, i) {
                      final p = participants[i];
                      return ListTile(
                        leading: AvatarWidget(
                          avatarUrl: p.avatarUrl,
                          name: p.name,
                          size: 36,
                        ),
                        title: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Gontserrat'),
                        ),
                        trailing: Text(
                          p.emoji ?? '👍',
                          style: const TextStyle(fontSize: 24),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssigneeSheet() async {
    final convCubit = context.read<ConversationCubit>();
    var agents = List<User>.from(convCubit.state.agents);

    // Fetch fresh assignable agents specifically for this conversation's inbox
    try {
      final repo = convCubit.repo;
      final freshRes = await repo.fetchAssignableAgents(inboxId: widget.conversation.inboxId);
      freshRes.fold((_) {}, (freshList) {
        if (freshList.isNotEmpty) {
          agents = freshList;
        }
      });
    } catch (_) {}

    if (!mounted) return;
    final activeAssignee = _currentAssignee ?? widget.conversation.assignee;
    final isStatusBot = _status.toLowerCase() == 'bot' || (activeAssignee?.isBot ?? false);

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
    final contact = _contact;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
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
          _scrollToBottom();
        }

        if (state.isLoadingOlder && _maxScrollBeforeLoad == null && _scrollController.hasClients) {
          _maxScrollBeforeLoad = _scrollController.position.maxScrollExtent;
          _pixelsBeforeLoad = _scrollController.position.pixels;
        }

        if (_maxScrollBeforeLoad != null && !state.isLoadingOlder) {
          final oldMax = _maxScrollBeforeLoad!;
          final oldPixels = _pixelsBeforeLoad ?? _scrollController.position.pixels;
          _maxScrollBeforeLoad = null;
          _pixelsBeforeLoad = null;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              final newMax = _scrollController.position.maxScrollExtent;
              final diff = newMax - oldMax;
              if (diff > 0) {
                _scrollController.jumpTo(oldPixels + diff);
              }
            }
          });
        }
      },
      builder: (context, chatState) {
        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6),
          appBar: AppBar(
            bottom: AppBarProgressBar(
              isLoading: chatState.isLoading || chatState.isLoadingOlder,
            ),
            titleSpacing: 0,
            title: InkWell(
              onTap: () async {
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
                        Text(
                          contact.name,
                          style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                    final isBot = activeAssignee.isBot || activeAssignee.assigneeType == 'AgentBot';
                    final botEmoji = activeAssignee.emoji ??
                        (activeAssignee.name.isNotEmpty && activeAssignee.name.trim().characters.first.runes.first > 255
                            ? activeAssignee.name.trim().characters.first
                            : '🤖');
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
                              backgroundColor: isBot
                                  ? const Color(0xFF5850EC).withValues(alpha: 0.2)
                                  : const Color(0xFF4162E3).withValues(alpha: 0.2),
                              backgroundImage: (!isBot && activeAssignee.avatarUrl != null && activeAssignee.avatarUrl!.isNotEmpty)
                                  ? NetworkImage(activeAssignee.avatarUrl!)
                                  : null,
                              child: isBot
                                  ? Text(botEmoji, style: TextStyle(fontSize: 12.sp))
                                  : (activeAssignee.avatarUrl == null || activeAssignee.avatarUrl!.isEmpty
                                      ? Text(
                                          activeAssignee.name.isNotEmpty
                                              ? activeAssignee.name[0].toUpperCase()
                                              : 'A',
                                          style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4162E3)),
                                        )
                                      : null),
                            ),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 14.r, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  }
                  return InkWell(
                    onTap: _showAssigneeSheet,
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF282C35) : const Color(0xFFEFF2F6),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isDark ? const Color(0xFF3E4451) : const Color(0xFFD1D5DB),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 13.r,
                            color: isDark ? Colors.grey[300] : const Color(0xFF4B5563),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            Localizations.localeOf(context).languageCode == 'ar' ? 'غير معيّن' : 'Unassigned',
                            style: TextStyle(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[300] : const Color(0xFF4B5563),
                              fontFamily: 'Gontserrat',
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 13.r,
                            color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                          ),
                        ],
                      ),
                    ),
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
                          builder: (_) => ContactDetailsScreen(
                            contact: _contact,
                            conversationId: widget.conversation.id,
                            onContactUpdated: (newContact) {
                              if (mounted) setState(() => _contact = newContact);
                            },
                          ),
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

                          final totalCount = listItems.length;
                          _lastListItems = listItems;

                          return RefreshIndicator(
                            onRefresh: () async {
                              await context.read<ChatCubit>().loadPreviousMessages();
                            },
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              itemCount: totalCount,
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
                                  Message? quotedMsg;
                                  if (msg.inReplyToId != null) {
                                    for (final other in chatState.messages) {
                                      if (other.id == msg.inReplyToId) {
                                        quotedMsg = other;
                                        break;
                                      }
                                    }
                                  }
                                  final currentUser = context.read<AuthCubit>().currentUser;
                                  return MessageBubble(
                                    message: msg,
                                    isHighlighted: msg.id == _highlightedMessageId,
                                    channel: widget.conversation.channelType,
                                    currentUser: currentUser,
                                    contactName: msg.senderName ?? widget.conversation.contact.name,
                                    contactThumbnail: msg.senderAvatar ?? widget.conversation.contact.avatarUrl,
                                    showDateHeader: showDateHeader,
                                    onRetry: () => context.read<ChatCubit>().retryMessage(msg),
                                    repliedMessage: quotedMsg,
                                    onReply: _onReplyToMessage,
                                    onScrollToMessage: (id) => _scrollToMessageById(id, listItems),
                                    onEditMessage: (m) => _showEditMessageDialog(context, m),
                                    onReact: (m, emoji) => _onReactToMessage(m, emoji),
                                    onViewReactions: (m) => _showReactionsBottomSheet(context, m),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
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
