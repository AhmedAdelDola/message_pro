import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/core/di/injection_container.dart';
import 'package:message_pro/data/models/contact.dart';
import 'package:message_pro/logic/contacts/contact_details_cubit.dart';
import 'package:message_pro/logic/contacts/contact_details_state.dart';
import 'package:message_pro/logic/conversation/conversation_cubit.dart';
import '../chat/chat_screen.dart';
import 'edit_contact_screen.dart';
import 'widgets/contact_inbox_picker.dart';
import 'widgets/contact_lifecycle_picker.dart';
import 'widgets/details/contact_activities_tab_view.dart';
import 'widgets/details/contact_ai_activity_tab_view.dart';
import 'widgets/details/contact_attachments_tab_view.dart';
import 'widgets/details/contact_calendar_tab_view.dart';
import 'widgets/details/contact_calls_tab_view.dart';
import 'widgets/details/contact_commerce_tab_view.dart';
import 'widgets/details/contact_details_icon_bar.dart';
import 'widgets/details/contact_info_tab_view.dart';
import 'widgets/details/contact_notes_tab_view.dart';

/// Website-matched 8-tab Contact Details screen powered by the aggregate endpoint.
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
      )..loadDetails(conversationId: conversationId),
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

class _ContactDetailsContentState extends State<_ContactDetailsContent> {
  int _activeTabIndex = 0;

  String _tabTitle(int index, bool isArabic) {
    switch (index) {
      case 0:
        return isArabic ? 'تفاصيل العميل' : 'Contact details';
      case 1:
        return isArabic ? 'المكالمات' : 'Calls';
      case 2:
        return isArabic ? 'نشاط الذكاء الاصطناعي' : 'AI activity';
      case 3:
        return isArabic ? 'المرفقات' : 'Attachments';
      case 4:
        return isArabic ? 'الأنشطة' : 'Activities';
      case 5:
        return isArabic ? 'الملاحظات' : 'Notes';
      case 6:
        return isArabic ? 'التقويم' : 'Calendar';
      case 7:
        return isArabic ? 'المتجر' : 'Commerce';
      default:
        return isArabic ? 'تفاصيل العميل' : 'Contact details';
    }
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

  Future<void> _openEditContact(BuildContext context, Contact contact) async {
    final updatedContact = await Navigator.push<Contact>(
      context,
      MaterialPageRoute(
        builder: (_) => EditContactScreen(contact: contact),
      ),
    );
    if (updatedContact != null && context.mounted) {
      widget.onContactUpdated?.call(updatedContact);
      context.read<ContactDetailsCubit>().loadDetails(
            conversationId: widget.conversationId,
          );
    }
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
          content: Text(
            isArabic
                ? 'لا توجد قنوات متاحة لبدء محادثة'
                : 'No inboxes available to start chat',
          ),
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
                  isArabic ? 'إضافة تصنيف' : 'Add Tag',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              const Divider(height: 1),
              if (availableLabels.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      isArabic
                          ? 'لا توجد وسوم إضافية متاحة'
                          : 'No more tags available',
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
                        leading: const Icon(Icons.label_outline_rounded, size: 20),
                        title: Text(label, style: TextStyle(color: textPrimary)),
                        onTap: () {
                          Navigator.pop(ctx);
                          context
                              .read<ContactDetailsCubit>()
                              .updateLabels([...state.labels, label]);
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
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
    final bgColor = isDark ? const Color(0xFF141518) : const Color(0xFFFEFEFE);
    final borderColor = isDark
        ? const Color(0xFF2C2D32)
        : const Color(0xFF353C45).withValues(alpha: 0.16);
    final primaryText = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF282E34);

    return BlocConsumer<ContactDetailsCubit, ContactDetailsState>(
      listener: (context, state) {
        if (state.createdConversation != null) {
          final conv = state.createdConversation!;
          context.read<ContactDetailsCubit>().clearCreatedConversation();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)),
          );
        }
        if (state.feedbackMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.feedbackMessage!),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<ContactDetailsCubit>();

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: primaryText),
              onPressed: () => Navigator.pop(context),
            ),
            titleSpacing: 0,
            title: Text(
              _tabTitle(_activeTabIndex, isArabic),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryText,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: borderColor),
            ),
          ),
          body: Column(
            children: [
              ContactDetailsIconBar(
                activeIndex: _activeTabIndex,
                isDark: isDark,
                onTabSelected: (index) => setState(() => _activeTabIndex = index),
              ),
              if (state.isLoadingAggregate)
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: Color(0xFF4162E3),
                ),
              Expanded(
                child: IndexedStack(
                  index: _activeTabIndex,
                  children: [
                    // 0: Contact details
                    ContactInfoTabView(
                      state: state,
                      isDark: isDark,
                      isArabic: isArabic,
                      onCopyId: () => _copyToClipboard(state.contact.id.toString(), 'ID'),
                      onCopyPhone: (p) => _copyToClipboard(p, isArabic ? 'رقم الهاتف' : 'Phone'),
                      onCopyEmail: (e) => _copyToClipboard(e, isArabic ? 'البريد' : 'Email'),
                      onEditContact: () => _openEditContact(context, state.contact),
                      onManageFields: () => _openEditContact(context, state.contact),
                      onPickLifecycleStage: () => _showLifecyclePicker(context, state),
                      onAddTag: () => _showLabelsPickerModal(context, state),
                      onRemoveTag: (tag) {
                        final updated = state.labels.where((l) => l != tag).toList();
                        cubit.updateLabels(updated);
                      },
                      onStartConversation: widget.conversationId == null
                          ? () => _handleStartConversation(context, state.contact)
                          : null,
                    ),

                    // 1: Calls
                    ContactCallsTabView(isDark: isDark, isArabic: isArabic),

                    // 2: AI Activity
                    ContactAiActivityTabView(
                      items: state.aiActivity,
                      pagination: state.pagination['ai_activity'],
                      isLoading: state.loadingSections.contains('ai_activity'),
                      isDark: isDark,
                      isArabic: isArabic,
                      onRefresh: () => cubit.refreshSection('ai_activity'),
                      onLoadMore: () => cubit.loadMoreSection('ai_activity'),
                    ),

                    // 3: Attachments
                    ContactAttachmentsTabView(
                      items: state.attachments,
                      pagination: state.pagination['attachments'],
                      isLoading: state.loadingSections.contains('attachments'),
                      isDark: isDark,
                      isArabic: isArabic,
                      onLoadMore: () => cubit.loadMoreSection('attachments'),
                    ),

                    // 4: Activities
                    ContactActivitiesTabView(
                      items: state.activities,
                      pagination: state.pagination['activities'],
                      isLoading: state.loadingSections.contains('activities'),
                      isDark: isDark,
                      isArabic: isArabic,
                      onLoadMore: () => cubit.loadMoreSection('activities'),
                    ),

                    // 5: Notes
                    ContactNotesTabView(
                      notes: state.notes,
                      pagination: state.pagination['notes'],
                      isLoading: state.loadingSections.contains('notes'),
                      isSavingNote: state.isSavingNote,
                      canAddNote: widget.conversationId != null && widget.conversationId! > 0,
                      isDark: isDark,
                      isArabic: isArabic,
                      onLoadMore: () => cubit.loadMoreSection('notes'),
                      onAddNote: (content) => cubit.addPrivateNote(content),
                    ),

                    // 6: Calendar
                    ContactCalendarTabView(
                      events: state.calendarEvents,
                      activeBucket: state.calendarBucket,
                      pagination: state.pagination['calendar'],
                      isLoading: state.loadingSections.contains('calendar'),
                      isDark: isDark,
                      isArabic: isArabic,
                      onSwitchBucket: (bucket) => cubit.switchCalendarBucket(bucket),
                      onLoadMore: () => cubit.loadMoreSection('calendar'),
                    ),

                    // 7: Commerce (Shopify)
                    ContactCommerceTabView(
                      ecommerce: state.ecommerce,
                      selectedStoreId: state.selectedStoreId,
                      isLoading: state.loadingSections.contains('ecommerce'),
                      isDark: isDark,
                      isArabic: isArabic,
                      onSelectStore: (storeId) => cubit.setSelectedStore(storeId),
                      onRefresh: () => cubit.refreshSection('ecommerce'),
                      onLoadMoreOrders: (store) => cubit.loadMoreEcommerceOrders(store),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
