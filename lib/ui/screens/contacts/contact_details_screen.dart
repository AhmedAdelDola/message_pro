import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/models/contact.dart';
import '../../../data/repositories/contact_repository.dart';
import '../../../data/repositories/conversation_repository.dart';
import '../../../logic/conversation/conversation_cubit.dart';
import '../../../logic/conversation/conversation_state.dart';
import '../../widgets/avatar_widget.dart';
import '../chat/chat_screen.dart';
import 'edit_contact_screen.dart';

class ContactDetailsScreen extends StatefulWidget {
  final Contact contact;
  final int? conversationId;
  final Function(Contact updatedContact)? onContactUpdated;

  const ContactDetailsScreen({
    super.key,
    required this.contact,
    this.conversationId,
    this.onContactUpdated,
  });

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Contact _contact;
  late String _lifecycleStage;
  List<String> _contactLabels = [];
  bool _isLoadingLabels = false;

  final TextEditingController _noteController = TextEditingController();
  final List<Map<String, dynamic>> _notes = [];
  List<LifecycleStage> _lifecycleStages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _contact = widget.contact;

    final stageFromAttrs = _contact.customAttributes['lifecycle_stage'] ??
        _contact.customAttributes['lead_status'] ??
        _contact.customAttributes['stage'];
    final rawStageStr = (stageFromAttrs != null && stageFromAttrs.toString().isNotEmpty)
        ? stageFromAttrs.toString()
        : (_contact.lifecycleStage?.name ?? '');

    if (rawStageStr.isNotEmpty) {
      final emoji = _contact.lifecycleStage?.icon ?? LifecycleStage.getEmojiForStage(rawStageStr);
      _lifecycleStage = rawStageStr.startsWith(emoji) ? rawStageStr : '$emoji $rawStageStr';
    } else {
      _lifecycleStage = '';
    }

    _loadContactLabels();
    _loadBackendLifecycleStages();
  }

  Future<void> _loadBackendLifecycleStages() async {
    try {
      final convCubit = context.read<ConversationCubit>();
      if (convCubit.state.lifecycleStages.isNotEmpty) {
        if (mounted) setState(() => _lifecycleStages = List.from(convCubit.state.lifecycleStages));
      } else {
        final res = await sl<IConversationRepository>().fetchLifecycleStages();
        if (!mounted) return;
        res.fold((_) {}, (stages) {
          setState(() => _lifecycleStages = stages);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadContactLabels() async {
    setState(() => _isLoadingLabels = true);
    final res = await sl<IContactRepository>().getContactLabels(_contact.id);
    if (!mounted) return;
    res.fold(
      (_) => setState(() => _isLoadingLabels = false),
      (labels) => setState(() {
        _contactLabels = labels;
        _isLoadingLabels = false;
      }),
    );
  }

  Future<void> _updateLifecycleStage(String stage, {int? stageId}) async {
    final old = _lifecycleStage;
    setState(() => _lifecycleStage = stage);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // If stageId is not explicitly provided, try to find it in _lifecycleStages
    int? resolvedId = stageId;
    if (resolvedId == null && _lifecycleStages.isNotEmpty) {
      for (final s in _lifecycleStages) {
        if (stage.contains(s.name) || s.name.contains(stage)) {
          resolvedId = s.id;
          break;
        }
      }
    }

    final res = await sl<IContactRepository>().updateContactLifecycle(
      _contact.id,
      stage,
      stageId: resolvedId,
    );
    if (!mounted) return;
    res.fold(
      (failure) {
        setState(() => _lifecycleStage = old);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.redAccent),
        );
      },
      (updated) {
        setState(() => _contact = updated);
        widget.onContactUpdated?.call(updated);

        // Update conversation cubit immediately so conversation tile outside reflects it
        try {
          context.read<ConversationCubit>().updateContactLifecycleStage(
            _contact.id,
            stage,
            conversationId: widget.conversationId,
          );
        } catch (_) {}

        // Also update conversation custom attributes on backend if conversationId is given
        if (widget.conversationId != null) {
          try {
            sl<IConversationRepository>().updateConversationCustomAttributes(
              widget.conversationId!,
              {'lifecycle_stage': stage, 'lead_status': stage},
            );
          } catch (_) {}
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'تم تحديث مرحلة العميل إلى: $stage' : 'Lifecycle stage updated to: $stage',
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _copyToClipboard(email, 'Email address');
    }
  }

  bool _isStartingConversation = false;

  Future<void> _startNewConversation() async {
    if (_isStartingConversation) return;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => _isStartingConversation = true);

    try {
      final workspaceInboxes = context.read<ConversationCubit>().state.inboxes;
      final repo = sl<IConversationRepository>();
      List<Map<String, dynamic>> inboxes = [];

      final phone = _contact.phoneNumber?.trim();
      if (phone != null && phone.isNotEmpty) {
        final phoneDestRes = await repo.getPhoneDestinations(phoneNumber: phone);
        phoneDestRes.fold((_) {}, (destList) {
          for (final d in destList) {
            final rawInbox = d['inbox'];
            int? parsedId;
            String? pName;
            String? chType;
            if (rawInbox is Map) {
              parsedId = rawInbox['id'] is int ? rawInbox['id'] : int.tryParse(rawInbox['id']?.toString() ?? '');
              pName = rawInbox['name']?.toString();
              chType = rawInbox['channel_type']?.toString();
            } else {
              parsedId = d['inbox_id'] is int ? d['inbox_id'] : int.tryParse(d['inbox_id']?.toString() ?? '');
              pName = d['inbox_name']?.toString();
              chType = d['channel_type']?.toString();
            }
            final srcId = d['source_id']?.toString() ?? phone;

            if (parsedId != null && parsedId > 0 && !inboxes.any((existing) => existing['id'] == parsedId)) {
              final matchingInbox = workspaceInboxes.where((wi) => wi.id == parsedId).firstOrNull;
              pName ??= matchingInbox?.name;
              chType ??= matchingInbox?.channelType ?? 'Channel::Whatsapp';
              inboxes.add({
                'id': parsedId,
                'name': (pName != null && pName.isNotEmpty) ? pName : 'WhatsApp',
                'channel_type': chType,
                'source_id': srcId,
              });
            }
          }
        });
      }

      // Also check contactable inboxes for existing non-phone channels (Facebook, Instagram, Email, WebWidget)
      if (inboxes.isEmpty) {
        final inboxesResult = await repo.getContactableInboxes(_contact.id);
        inboxesResult.fold((_) {}, (list) {
          for (final item in list) {
            final inbMap = item['inbox'] is Map ? Map<String, dynamic>.from(item['inbox'] as Map) : null;
            final rawInboxId = inbMap?['id'] ?? item['inbox_id'];
            final inboxId = rawInboxId is int ? rawInboxId : int.tryParse(rawInboxId?.toString() ?? '');

            if (inboxId == null || inboxId <= 0) continue;

            final matchingInbox = workspaceInboxes.where((wi) => wi.id == inboxId).firstOrNull;
            final name = inbMap?['name']?.toString() ?? matchingInbox?.name ?? 'قناة مراسلة';
            final channelType = inbMap?['channel_type']?.toString() ?? matchingInbox?.channelType ?? '';
            final sourceId = item['source_id']?.toString() ?? _contact.phoneNumber ?? _contact.email ?? 'contact_${_contact.id}';

            if (!inboxes.any((existing) => existing['id'] == inboxId)) {
              inboxes.add({
                'id': inboxId,
                'name': name,
                'channel_type': channelType,
                'source_id': sourceId,
              });
            }
          }
        });
      }

      // Fallback to workspace inboxes
      if (inboxes.isEmpty) {
        if (workspaceInboxes.isNotEmpty) {
          for (final inb in workspaceInboxes) {
            if (!inboxes.any((existing) => existing['id'] == inb.id)) {
              inboxes.add({
                'id': inb.id,
                'name': inb.name,
                'channel_type': inb.channelType,
                'source_id': _contact.phoneNumber ?? _contact.email ?? _contact.name,
              });
            }
          }
        } else {
          final allInboxesResult = await repo.fetchInboxes();
          allInboxesResult.fold((_) {}, (list) {
            for (final inb in list) {
              if (!inboxes.any((existing) => existing['id'] == inb.id)) {
                inboxes.add({
                  'id': inb.id,
                  'name': inb.name,
                  'channel_type': inb.channelType,
                  'source_id': _contact.phoneNumber ?? _contact.email ?? _contact.name,
                });
              }
            }
          });
        }
      }

      if (!mounted) return;

      if (inboxes.isEmpty) {
        setState(() => _isStartingConversation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'لا توجد قنوات متاحة لبدء محادثة' : 'No inboxes available to start chat'),
            backgroundColor: const Color(0xFFFF382E),
          ),
        );
        return;
      }

      if (inboxes.length == 1) {
        await _executeStartConversation(inboxes.first);
      } else {
        setState(() => _isStartingConversation = false);
        _showInboxPicker(inboxes);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isStartingConversation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFFF382E),
          ),
        );
      }
    }
  }

  Future<void> _executeStartConversation(Map<String, dynamic> inbox) async {
    setState(() => _isStartingConversation = true);
    final repo = sl<IConversationRepository>();
    final inboxId = inbox['id'] as int? ?? int.tryParse(inbox['id'].toString()) ?? 1;
    final channel = inbox['channel_type']?.toString().toLowerCase() ?? '';
    final isWhatsApp = channel.contains('whatsapp');

    final sourceId = (isWhatsApp && _contact.phoneNumber != null && _contact.phoneNumber!.isNotEmpty)
        ? _contact.phoneNumber!
        : (inbox['source_id']?.toString() ??
            _contact.phoneNumber ??
            _contact.email ??
            'contact_${_contact.id}');

    final result = await repo.startNewConversation(
      contactId: _contact.id,
      inboxId: inboxId,
      sourceId: sourceId,
    );

    if (!mounted) return;
    setState(() => _isStartingConversation = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: const Color(0xFFFF382E),
          ),
        );
      },
      (conversation) {
        context.read<ConversationCubit>().loadConversations(refresh: true);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(conversation: conversation),
          ),
        );
      },
    );
  }

  void _showInboxPicker(List<Map<String, dynamic>> inboxes) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;

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
                  isArabic ? 'اختر قناة المراسلة' : 'Select Channel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    fontFamily: 'Gontserrat',
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: inboxes.length,
                  itemBuilder: (_, index) {
                    final inb = inboxes[index];
                    final channel = inb['channel_type']?.toString().toLowerCase() ?? '';
                    final isWhatsApp = channel.contains('whatsapp');
                    final isMessenger = channel.contains('facebook') || channel.contains('messenger');
                    final isInstagram = channel.contains('instagram');
                    final isEmail = channel.contains('email');

                    String rawName = inb['name']?.toString() ?? '';
                    if (rawName.isEmpty || rawName == 'Inbox #null') {
                      rawName = isWhatsApp
                          ? 'WhatsApp'
                          : (isMessenger
                              ? 'Messenger'
                              : (isInstagram
                                  ? 'Instagram'
                                  : (isEmail ? 'Email' : 'Website Widget')));
                    }
                    final name = rawName;

                    Widget channelIcon;
                    Color iconBg;

                    if (isWhatsApp) {
                      iconBg = const Color(0xFF22C55E).withValues(alpha: 0.15);
                      channelIcon = Image.asset(
                        'assets/images/channels/whatsapp.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.chat_bubble, size: 18, color: Color(0xFF22C55E)),
                      );
                    } else if (isMessenger) {
                      iconBg = const Color(0xFF0084FF).withValues(alpha: 0.15);
                      channelIcon = Image.asset(
                        'assets/images/channels/messenger.png',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.facebook, size: 20, color: Color(0xFF0084FF)),
                      );
                    } else if (isInstagram) {
                      iconBg = const Color(0xFFDD2A7B).withValues(alpha: 0.15);
                      channelIcon = const Icon(Icons.camera_alt_rounded, size: 20, color: Color(0xFFDD2A7B));
                    } else if (isEmail) {
                      iconBg = const Color(0xFFEA4335).withValues(alpha: 0.15);
                      channelIcon = const Icon(Icons.email_rounded, size: 19, color: Color(0xFFEA4335));
                    } else {
                      iconBg = const Color(0xFF4162E3).withValues(alpha: 0.15);
                      channelIcon = const Icon(Icons.language_rounded, size: 20, color: Color(0xFF4162E3));
                    }

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconBg,
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: channelIcon),
                      ),
                      title: Text(
                        name,
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Gontserrat'),
                      ),
                      subtitle: Text(
                        inb['channel_type']?.toString() ?? '',
                        style: TextStyle(color: textSecondary, fontSize: 12, fontFamily: 'Gontserrat'),
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _executeStartConversation(inb);
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

  void _showLifecyclePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

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
                  isArabic ? 'تحديد مرحلة العميل' : 'Select Lifecycle Stage',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Gontserrat'),
                ),
              ),
              const Divider(),
              Expanded(
                child: _lifecycleStages.isEmpty
                    ? Center(
                        child: Text(
                          isArabic ? 'لا توجد مراحل محددة في النظام' : 'No lifecycle stages defined on backend',
                          style: TextStyle(color: textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _lifecycleStages.length,
                        itemBuilder: (context, index) {
                          final stage = _lifecycleStages[index];
                          final emoji = stage.icon ?? LifecycleStage.getEmojiForStage(stage.name);
                          final colorHex = stage.color;
                          final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                          final cleanName = stage.name.startsWith(emoji) ? stage.name.substring(emoji.length).trim() : stage.name;
                          final fullStage = '$emoji $cleanName';
                          final isSelected = _lifecycleStage.contains(cleanName);

                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Text(emoji, style: const TextStyle(fontSize: 16)),
                            ),
                            title: Text(
                              cleanName,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? AppColors.primary : null,
                                fontFamily: 'Gontserrat',
                              ),
                            ),
                            trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                            onTap: () {
                              Navigator.pop(ctx);
                              _updateLifecycleStage(fullStage, stageId: stage.id);
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

  Future<void> _showLabelsPickerModal() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final repo = sl<IConversationRepository>();
    final labelsResult = await repo.fetchLabels();
    final allLabels = labelsResult.fold((_) => <Label>[], (list) => list);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
            final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;

            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isArabic ? 'إدارة التصنيفات والوسوم' : 'Manage Labels & Tags',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary, fontFamily: 'Gontserrat'),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  if (allLabels.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        isArabic ? 'لا توجد تصنيفات مسجلة في النظام' : 'No labels found in workspace',
                        style: TextStyle(color: textSecondary, fontSize: 13),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: allLabels.length,
                        itemBuilder: (context, index) {
                          final lbl = allLabels[index];
                          final isSelected = _contactLabels.contains(lbl.title);
                          Color lblColor;
                          try {
                            lblColor = Color(int.parse(lbl.color.replaceAll('#', '0xFF')));
                          } catch (_) {
                            lblColor = AppColors.primary;
                          }

                          return ListTile(
                            leading: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(color: lblColor, shape: BoxShape.circle),
                            ),
                            title: Text(
                              lbl.title,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: textPrimary,
                                fontFamily: 'Gontserrat',
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                                : const Icon(Icons.circle_outlined, color: Colors.grey),
                            onTap: () async {
                              final updatedList = List<String>.from(_contactLabels);
                              if (isSelected) {
                                updatedList.remove(lbl.title);
                              } else {
                                updatedList.add(lbl.title);
                              }
                              setModalState(() => _contactLabels = updatedList);
                              setState(() => _contactLabels = updatedList);
                              await sl<IContactRepository>().updateContactLabels(_contact.id, updatedList);
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
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    final contact = _contact;

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
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Gontserrat',
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 21),
            color: AppColors.primary,
            tooltip: isArabic ? 'تعديل جهة الاتصال' : 'Edit Contact',
            onPressed: () async {
              final updated = await Navigator.of(context).push<Contact>(
                MaterialPageRoute(
                  builder: (_) => EditContactScreen(contact: _contact),
                ),
              );
              if (updated != null) {
                setState(() => _contact = updated);
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
                  // Profile Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        AvatarWidget(
                          avatarUrl: contact.avatarUrl,
                          name: contact.name,
                          size: 58,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                  fontFamily: 'Gontserrat',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'ID: #${contact.id > 0 ? contact.id : 10990}',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: textSecondary,
                                      fontFamily: 'Gontserrat',
                                    ),
                                  ),
                                  if (contact.identifier != null && contact.identifier!.isNotEmpty) ...[
                                    Text(' • ', style: TextStyle(color: textSecondary)),
                                    Flexible(
                                      child: Text(
                                        contact.identifier!,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: textSecondary,
                                          fontFamily: 'Gontserrat',
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  // Lifecycle stage badge with emoji & shape
                                  InkWell(
                                    onTap: _showLifecyclePicker,
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: Color(int.parse(LifecycleStage.getColorForStage(_lifecycleStage).replaceFirst('#', '0xFF'))).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Color(int.parse(LifecycleStage.getColorForStage(_lifecycleStage).replaceFirst('#', '0xFF'))).withValues(alpha: 0.35),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            LifecycleStage.getEmojiForStage(_lifecycleStage),
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _lifecycleStage.startsWith(LifecycleStage.getEmojiForStage(_lifecycleStage))
                                                ? _lifecycleStage.substring(LifecycleStage.getEmojiForStage(_lifecycleStage).length).trim()
                                                : _lifecycleStage,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: textPrimary,
                                              fontFamily: 'Gontserrat',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Contact Labels
                                  ..._contactLabels.map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.label_outline_rounded, size: 10, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB)),
                                        const SizedBox(width: 3),
                                        Text(
                                          tag,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                                            fontFamily: 'Gontserrat',
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons Row (Start conversation on system & optional email)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.chat_bubble_rounded,
                            label: isArabic ? 'بدء محادثة' : 'Start Chat',
                            color: const Color(0xFF4162E3),
                            onTap: _startNewConversation,
                          ),
                        ),
                        if (contact.email != null && contact.email!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.email_rounded,
                              label: isArabic ? 'بريد' : 'Email',
                              color: const Color(0xFF64748B),
                              onTap: () => _sendEmail(contact.email!),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  Divider(color: borderColor, height: 1),

                  // Functional Tabs Bar
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 2.5,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: textSecondary,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Gontserrat'),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13, fontFamily: 'Gontserrat'),
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.person_outline_rounded, size: 18),
                          text: isArabic ? 'المعلومات' : 'Details',
                        ),
                        Tab(
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          text: isArabic ? 'السمات الإضافية' : 'Attributes',
                        ),
                        Tab(
                          icon: const Icon(Icons.note_alt_outlined, size: 18),
                          text: isArabic ? 'الملاحظات' : 'Notes',
                        ),
                        Tab(
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          text: isArabic ? 'المحادثات' : 'Chats',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDetailsTab(isArabic, textPrimary, textSecondary, borderColor, cardBg),
            _buildAttributesTab(isArabic, textPrimary, textSecondary, borderColor, cardBg),
            _buildNotesTab(isArabic, textPrimary, textSecondary, borderColor, cardBg),
            _buildConversationsTab(isArabic, textPrimary, textSecondary, borderColor, cardBg),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'Gontserrat',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Details Tab
  Widget _buildDetailsTab(
    bool isArabic,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    Color cardBg,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contact = _contact;
    final phone = contact.phoneNumber;
    final email = contact.email;
    final identifier = contact.identifier;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        // Lifecycle Stage Selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'مرحلة العميل' : 'Lifecycle Stage',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                  fontFamily: 'Gontserrat',
                ),
              ),
              InkWell(
                onTap: _showLifecyclePicker,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _lifecycleStage,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          fontFamily: 'Gontserrat',
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 16, color: textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        Divider(color: borderColor, height: 1),

        // Labels & Tags Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.label_outline_rounded, size: 16, color: textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        isArabic ? 'التصنيفات والوسوم' : 'Labels & Tags',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          fontFamily: 'Gontserrat',
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _showLabelsPickerModal,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, size: 14, color: AppColors.primaryLight),
                          const SizedBox(width: 2),
                          Text(
                            isArabic ? 'إضافة تصنيف' : 'Add Label',
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Gontserrat',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isLoadingLabels)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5)),
                )
              else if (_contactLabels.isEmpty)
                Text(
                  isArabic ? 'لا توجد تصنيفات حالياً لهذا العميل' : 'No labels assigned to this contact',
                  style: TextStyle(fontSize: 12, color: textSecondary.withValues(alpha: 0.7)),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _contactLabels.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFC7D2FE),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF3730A3),
                              fontFamily: 'Gontserrat',
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () async {
                              final updated = List<String>.from(_contactLabels)..remove(tag);
                              setState(() => _contactLabels = updated);
                              await sl<IContactRepository>().updateContactLabels(_contact.id, updated);
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 13,
                              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF3730A3),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),

        Divider(color: borderColor, height: 1),

        // Contact Fields
        _buildFieldTile(
          label: isArabic ? 'رقم الهاتف' : 'Phone Number',
          value: phone != null && phone.isNotEmpty ? phone : (isArabic ? 'غير متوفر' : 'Not available'),
          isPlaceholder: phone == null || phone.isEmpty,
        ),
        _buildFieldTile(
          label: isArabic ? 'البريد الإلكتروني' : 'Email Address',
          value: email != null && email.isNotEmpty ? email : (isArabic ? 'غير متوفر' : 'Not available'),
          isPlaceholder: email == null || email.isEmpty,
          onCopy: email != null && email.isNotEmpty ? () => _copyToClipboard(email, 'Email') : null,
          actionIcon: email != null && email.isNotEmpty ? Icons.email_rounded : null,
          onAction: email != null && email.isNotEmpty ? () => _sendEmail(email) : null,
        ),
        _buildFieldTile(
          label: isArabic ? 'المعرف الفريد' : 'Identifier',
          value: identifier != null && identifier.isNotEmpty ? identifier : (isArabic ? 'غير محدد' : 'Not specified'),
          isPlaceholder: identifier == null || identifier.isEmpty,
          onCopy: identifier != null && identifier.isNotEmpty ? () => _copyToClipboard(identifier, 'Identifier') : null,
        ),
        _buildFieldTile(
          label: isArabic ? 'رقم العميل' : 'Contact ID',
          value: '#${contact.id}',
          onCopy: () => _copyToClipboard('${contact.id}', 'Contact ID'),
        ),
      ],
    );
  }

  // 2. Custom Attributes Tab
  Widget _buildAttributesTab(
    bool isArabic,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    Color cardBg,
  ) {
    final attributes = _contact.customAttributes;

    if (attributes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.tune_rounded, size: 48, color: textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                isArabic ? 'لا توجد سمات إضافية' : 'No Custom Attributes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  fontFamily: 'Gontserrat',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isArabic
                    ? 'الحقول المخصصة التي يتم إضافتها في النظام ستظهر هنا.'
                    : 'Custom fields configured for this contact in Chatwoot will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                  fontFamily: 'Gontserrat',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: attributes.entries.map((entry) {
        final keyName = entry.key.replaceAll('_', ' ').split(' ').map((w) {
          if (w.isEmpty) return '';
          return '${w[0].toUpperCase()}${w.substring(1)}';
        }).join(' ');

        final val = entry.value?.toString() ?? '';

        return _buildFieldTile(
          label: keyName,
          value: val.isNotEmpty ? val : '-',
          isPlaceholder: val.isEmpty,
          onCopy: val.isNotEmpty ? () => _copyToClipboard(val, keyName) : null,
        );
      }).toList(),
    );
  }

  // 3. Notes Tab
  Widget _buildNotesTab(
    bool isArabic,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    Color cardBg,
  ) {
    return Column(
      children: [
        // Note Input
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  maxLines: 3,
                  minLines: 1,
                  style: TextStyle(fontSize: 13.5, color: textPrimary, fontFamily: 'Gontserrat'),
                  decoration: InputDecoration(
                    hintText: isArabic ? 'أضف ملاحظة خاصة حول هذا العميل...' : 'Add a private note about this contact...',
                    hintStyle: TextStyle(fontSize: 13, color: textSecondary, fontFamily: 'Gontserrat'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                tooltip: isArabic ? 'إرسال' : 'Send',
                onPressed: _addNote,
              ),
            ],
          ),
        ),

        // Notes List
        Expanded(
          child: _notes.isEmpty
              ? Center(
                  child: Text(
                    isArabic ? 'لا توجد ملاحظات بعد' : 'No notes yet',
                    style: TextStyle(color: textSecondary, fontFamily: 'Gontserrat'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    final date = note['createdAt'] as DateTime;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                note['author'] ?? 'أنت',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontFamily: 'Gontserrat',
                                ),
                              ),
                              Text(
                                DateFormat('d MMM, h:mm a').format(date),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                  fontFamily: 'Gontserrat',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            note['content'] ?? '',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: textPrimary,
                              height: 1.35,
                              fontFamily: 'Gontserrat',
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 4. Conversations Tab
  Widget _buildConversationsTab(
    bool isArabic,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    Color cardBg,
  ) {
    return BlocBuilder<ConversationCubit, ConversationState>(
      builder: (context, state) {
        final contactConversations = state.conversations.where((c) {
          return c.contact.id == _contact.id ||
              (c.contact.phoneNumber != null &&
                  c.contact.phoneNumber == _contact.phoneNumber &&
                  c.contact.phoneNumber!.isNotEmpty);
        }).toList();

        if (contactConversations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 48, color: textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    isArabic ? 'لا توجد محادثات سابقة' : 'No prior conversations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      fontFamily: 'Gontserrat',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isArabic
                        ? 'محادثات هذا العميل ستظهر هنا عند التواصل معه.'
                        : 'Conversations with this contact will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      fontFamily: 'Gontserrat',
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _startNewConversation,
                    icon: _isStartingConversation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.chat_bubble_rounded, size: 18),
                    label: Text(
                      isArabic ? 'بدء محادثة على السيستم' : 'Start Conversation',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4162E3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: contactConversations.length,
          itemBuilder: (context, index) {
            final conv = contactConversations[index];
            final isOpen = conv.status == 'open';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(conversation: conv),
                    ),
                  );
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                title: Row(
                  children: [
                    Text(
                      '#${conv.id} - ${conv.inboxName ?? 'Chat'}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        fontFamily: 'Gontserrat',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOpen ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isOpen ? (isArabic ? 'مفتوحة' : 'Open') : (isArabic ? 'مغلقة' : 'Resolved'),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isOpen ? Colors.green : Colors.grey,
                          fontFamily: 'Gontserrat',
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: conv.lastMessage?.content != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          conv.lastMessage!.content!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: textSecondary, fontFamily: 'Gontserrat'),
                        ),
                      )
                    : null,
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFieldTile({
    required String label,
    required String value,
    bool isPlaceholder = false,
    VoidCallback? onCopy,
    IconData? actionIcon,
    VoidCallback? onAction,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textSecondary,
              fontFamily: 'Gontserrat',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isPlaceholder ? FontWeight.normal : FontWeight.w500,
                    color: isPlaceholder ? textSecondary.withValues(alpha: 0.7) : textPrimary,
                    fontFamily: 'Gontserrat',
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (actionIcon != null && onAction != null)
                    InkWell(
                      onTap: onAction,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(actionIcon, size: 16, color: AppColors.primary),
                      ),
                    ),
                  if (onCopy != null) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onCopy,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.copy_rounded, size: 15, color: textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
