import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/core/di/injection_container.dart';
import 'package:message_pro/data/models/contact.dart';
import 'package:message_pro/logic/contacts/contact_details_cubit.dart';
import 'package:message_pro/logic/contacts/contact_details_state.dart';
import 'package:message_pro/logic/conversation/conversation_cubit.dart';
import '../chat/chat_screen.dart';
import 'edit_contact_screen.dart';
import 'widgets/contact_attributes_tab.dart';
import 'widgets/contact_conversations_tab.dart';
import 'widgets/contact_details_tab.dart';
import 'widgets/contact_inbox_picker.dart';
import 'widgets/contact_lifecycle_picker.dart';
import 'widgets/contact_notes_tab.dart';
import 'widgets/details/contact_profile_header.dart';
import 'widgets/details/contact_quick_actions_bar.dart';

/// Clean screen displaying contact details, lifecycle stages, conversations, and custom attributes.
class ContactDetailsScreen extends StatelessWidget {
  final Contact contact;
  final int? conversationId;
  final ValueChanged<Contact>? onContactUpdated;

  const ContactDetailsScreen({
    super.key,
    required this.contact,
    this.conversationId,
    this.onContactUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final stages = context.read<ConversationCubit>().state.lifecycleStages;
    return BlocProvider<ContactDetailsCubit>(
      create: (_) => sl<ContactDetailsCubit>(
        param1: contact,
        param2: stages,
      )..loadDetails(),
      child: _ContactDetailsContent(
        conversationId: conversationId,
        onContactUpdated: onContactUpdated,
      ),
    );
  }
}

class _ContactDetailsContent extends StatefulWidget {
  final int? conversationId;
  final ValueChanged<Contact>? onContactUpdated;

  const _ContactDetailsContent({
    this.conversationId,
    this.onContactUpdated,
  });

  @override
  State<_ContactDetailsContent> createState() => _ContactDetailsContentState();
}

class _ContactDetailsContentState extends State<_ContactDetailsContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _noteController = TextEditingController();
  final List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isArabic ? 'تم نسخ $label بنجاح' : '$label copied to clipboard'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _copyToClipboard(phone, 'Phone number');
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _copyToClipboard(email, 'Email address');
    }
  }

  void _addNote() {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _notes.insert(0, {
        'content': text,
        'author': 'أنت',
        'createdAt': DateTime.now(),
      });
      _noteController.clear();
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _handleStartConversation(BuildContext context, Contact contact) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cubit = context.read<ContactDetailsCubit>();
    final inboxes = await cubit.resolveAvailableInboxes(
      workspaceInboxes: context.read<ConversationCubit>().state.inboxes,
    );

    if (!context.mounted) return;

    if (inboxes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'لا توجد قنوات متاحة لبدء محادثة' : 'No inboxes available to start chat'),
          backgroundColor: const Color(0xFFFF382E),
        ),
      );
      return;
    }

    if (inboxes.length == 1) {
      final inb = inboxes.first;
      final inboxId = inb['id'] as int? ?? int.tryParse(inb['id'].toString()) ?? 1;
      final sourceId = inb['source_id']?.toString() ??
          contact.phoneNumber ??
          contact.email ??
          'contact_${contact.id}';
      cubit.startConversation(inboxId: inboxId, sourceId: sourceId);
    } else {
      ContactInboxPicker.show(
        context: context,
        inboxes: inboxes,
        onSelectInbox: (inb) {
          final inboxId = inb['id'] as int? ?? int.tryParse(inb['id'].toString()) ?? 1;
          final sourceId = inb['source_id']?.toString() ??
              contact.phoneNumber ??
              contact.email ??
              'contact_${contact.id}';
          cubit.startConversation(inboxId: inboxId, sourceId: sourceId);
        },
      );
    }
  }

  void _showLifecyclePicker(BuildContext context, ContactDetailsState state) {
    ContactLifecyclePicker.show(
      context: context,
      lifecycleStages: state.lifecycleStages,
      currentLifecycleStage: state.activeLifecycleStage,
      onSelectStage: (stage) {
        final emoji = stage.icon ?? LifecycleStage.getEmojiForStage(stage.name);
        final cleanName = stage.name.startsWith(emoji)
            ? stage.name.substring(emoji.length).trim()
            : stage.name;
        final fullStage = '$emoji $cleanName';

        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final cubit = context.read<ContactDetailsCubit>();
        cubit.updateLifecycleStage(
          fullStage,
          stageId: stage.id,
          conversationId: widget.conversationId,
          isArabic: isArabic,
        );

        try {
          context.read<ConversationCubit>().updateContactLifecycleStage(
            state.contact.id,
            fullStage,
            conversationId: widget.conversationId,
          );
        } catch (_) {}
      },
    );
  }

  void _showLabelsPickerModal(BuildContext context, ContactDetailsState state) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;

    final convCubit = context.read<ConversationCubit>();
    final availableLabels = convCubit.state.labels
        .map((l) => l.title)
        .where((title) => !state.labels.contains(title))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  isArabic ? 'إضافة تصنيف' : 'Add Label',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                ),
              ),
              const Divider(height: 1),
              if (availableLabels.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      isArabic ? 'لا توجد تصنيفات إضافية متاحة' : 'No more labels available',
                      style: TextStyle(color: textSecondary),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableLabels.length,
                    itemBuilder: (_, index) {
                      final label = availableLabels[index];
                      return ListTile(
                        leading: const Icon(Icons.label_outline_rounded, color: AppColors.primary),
                        title: Text(label, style: TextStyle(color: textPrimary)),
                        onTap: () {
                          Navigator.pop(ctx);
                          final updated = List<String>.from(state.labels)..add(label);
                          context.read<ContactDetailsCubit>().updateLabels(updated);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return BlocConsumer<ContactDetailsCubit, ContactDetailsState>(
      listener: (context, state) {
        if (state.feedbackMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.feedbackMessage!),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
          widget.onContactUpdated?.call(state.contact);
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!), backgroundColor: const Color(0xFFFF382E)),
          );
        }
        if (state.createdConversation != null) {
          final conv = state.createdConversation!;
          context.read<ContactDetailsCubit>().clearCreatedConversation();
          context.read<ConversationCubit>().loadConversations(refresh: true);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)),
          );
        }
      },
      builder: (context, state) {
        final contact = state.contact;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close_rounded, color: textPrimary, size: 22),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              isArabic ? 'تفاصيل جهة الاتصال' : 'Contact details',
              style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 21),
                color: AppColors.primary,
                tooltip: isArabic ? 'تعديل جهة الاتصال' : 'Edit Contact',
                onPressed: () async {
                  final updated = await Navigator.of(context).push<Contact>(
                    MaterialPageRoute(builder: (_) => EditContactScreen(contact: contact)),
                  );
                  if (updated != null && context.mounted) {
                    context.read<ContactDetailsCubit>().loadDetails();
                    widget.onContactUpdated?.call(updated);
                  }
                },
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: borderColor, height: 1),
            ),
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ContactProfileHeader(
                        state: state,
                        onLifecycleTap: () => _showLifecyclePicker(context, state),
                        onAddLabelTap: () => _showLabelsPickerModal(context, state),
                        onRemoveLabel: (lbl) {
                          final updated = List<String>.from(state.labels)..remove(lbl);
                          context.read<ContactDetailsCubit>().updateLabels(updated);
                        },
                      ),
                      ContactQuickActionsBar(
                        contact: contact,
                        onStartChatTap: () => _handleStartConversation(context, contact),
                        onCallTap: _makeCall,
                        onEmailTap: _sendEmail,
                      ),
                      const SizedBox(height: 8),
                      TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary,
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 2.5,
                        tabs: [
                          Tab(text: isArabic ? 'البيانات' : 'Details'),
                          Tab(text: isArabic ? 'الخصائص' : 'Attributes'),
                          Tab(text: isArabic ? 'المحادثات' : 'Chats'),
                          Tab(text: isArabic ? 'الملاحظات' : 'Notes'),
                        ],
                      ),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                ContactDetailsTab(
                  contact: contact,
                  lifecycleStage: state.activeLifecycleStage,
                  contactLabels: state.labels,
                  isLoadingLabels: state.isLoadingLabels,
                  onSelectLifecycleStage: () => _showLifecyclePicker(context, state),
                  onAddLabel: () => _showLabelsPickerModal(context, state),
                  onRemoveLabel: (lbl) {
                    final updated = List<String>.from(state.labels)..remove(lbl);
                    context.read<ContactDetailsCubit>().updateLabels(updated);
                  },
                  onCopy: _copyToClipboard,
                  onSendEmail: _sendEmail,
                ),
                ContactAttributesTab(
                  contact: contact,
                  onCopy: _copyToClipboard,
                ),
                ContactConversationsTab(
                  contact: contact,
                  isStartingConversation: state.isStartingConversation,
                  onStartNewConversation: () => _handleStartConversation(context, contact),
                ),
                ContactNotesTab(
                  noteController: _noteController,
                  notes: _notes,
                  onAddNote: _addNote,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
