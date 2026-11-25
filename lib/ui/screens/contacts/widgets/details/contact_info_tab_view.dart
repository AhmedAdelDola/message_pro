import 'package:flutter/material.dart';
import 'package:message_pro/logic/contacts/contact_details_state.dart';
import 'package:message_pro/ui/widgets/avatar_widget.dart';
import 'package:message_pro/ui/widgets/channel_logo_widget.dart';

class ContactInfoTabView extends StatelessWidget {
  final ContactDetailsState state;
  final bool isDark;
  final bool isArabic;
  final VoidCallback onCopyId;
  final ValueChanged<String> onCopyPhone;
  final ValueChanged<String> onCopyEmail;
  final VoidCallback onEditContact;
  final VoidCallback onManageFields;
  final VoidCallback onPickLifecycleStage;
  final VoidCallback onAddTag;
  final ValueChanged<String> onRemoveTag;
  final VoidCallback? onStartConversation;

  const ContactInfoTabView({
    super.key,
    required this.state,
    required this.isDark,
    required this.isArabic,
    required this.onCopyId,
    required this.onCopyPhone,
    required this.onCopyEmail,
    required this.onEditContact,
    required this.onManageFields,
    required this.onPickLifecycleStage,
    required this.onAddTag,
    required this.onRemoveTag,
    this.onStartConversation,
  });

  @override
  Widget build(BuildContext context) {
    final contact = state.contact;
    final dividerColor = isDark
        ? const Color(0xFF2C2D32)
        : const Color(0xFF353C45).withValues(alpha: 0.16);
    final primaryText = isDark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF282E34);
    final secondaryText = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF626F7F);
    final mutedText = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF80838D);

    final excludedAttrKeys = <String>{
      'lifecycle_stage',
      'lead_status',
      'country',
      'country_name',
      'language',
    };
    final customEntries = contact.customAttributes.entries
        .where((e) => !excludedAttrKeys.contains(e.key.toLowerCase()))
        .toList();

    final countryVal =
        contact.customAttributes['country']?.toString() ??
        contact.customAttributes['country_name']?.toString() ??
        contact.customAttributes['country_code']?.toString();
    final languageVal = contact.customAttributes['language']?.toString();
    final resolvedChannel =
        (contact.phoneNumber?.isNotEmpty == true ||
            contact.identifier?.toLowerCase().contains('whatsapp') == true)
        ? 'whatsapp'
        : (contact.email?.isNotEmpty == true ? 'email' : 'web');

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // 1. Profile Summary Card
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Row(
            children: [
              AvatarWidget(
                avatarUrl: contact.avatarUrl,
                name: contact.name,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: onCopyId,
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ID: ${contact.id}',
                            style: TextStyle(fontSize: 12.5, color: mutedText),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.copy_rounded, size: 12, color: mutedText),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEditContact,
                icon: Icon(Icons.edit_outlined, size: 19, color: secondaryText),
                tooltip: isArabic ? 'تعديل' : 'Edit',
              ),
            ],
          ),
        ),

        // 2. Channels Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'القنوات' : 'Channels',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: primaryText,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final ch in (state.channels.isNotEmpty
                      ? state.channels
                      : [resolvedChannel]))
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChannelLogoWidget(channelType: ch, size: 22),
                    ),
                ],
              ),
            ],
          ),
        ),

        // 3. Lifecycle Stage Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'مرحلة العميل' : 'Lifecycle Stage',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: primaryText,
                ),
              ),
              InkWell(
                onTap: state.isUpdatingStage ? null : onPickLifecycleStage,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1D22) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: dividerColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.isUpdatingStage)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0EA5E9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'STAGE',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          state.activeLifecycleStage.isNotEmpty
                              ? state.activeLifecycleStage
                              : (isArabic ? 'تحديد المرحلة' : 'Select Stage'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: primaryText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: secondaryText,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (onStartConversation != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.isStartingConversation
                    ? null
                    : onStartConversation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4162E3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: state.isStartingConversation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                label: Text(
                  isArabic ? 'بدء محادثة جديدة' : 'Start Conversation',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

        const SizedBox(height: 6),
        Divider(height: 1, thickness: 1, color: dividerColor),

        // 4. Contact Fields Section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'حقول العميل' : 'Contact fields',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryText,
                ),
              ),
            ],
          ),
        ),

        _buildFieldRow(
          label: isArabic ? 'رقم الهاتف' : 'Phone Number',
          value: contact.phoneNumber,
          placeholder: isArabic ? 'إضافة رقم الهاتف' : 'Add Phone Number',
          primaryText: primaryText,
          mutedText: mutedText,
          onCopy: (contact.phoneNumber?.isNotEmpty == true)
              ? () => onCopyPhone(contact.phoneNumber!)
              : null,
          onTapEmpty: onEditContact,
        ),

        _buildFieldRow(
          label: isArabic ? 'البريد الإلكتروني' : 'Email Address',
          value: contact.email,
          placeholder: isArabic
              ? 'إضافة البريد الإلكتروني'
              : 'Add Email Address',
          primaryText: primaryText,
          mutedText: mutedText,
          onCopy: (contact.email?.isNotEmpty == true)
              ? () => onCopyEmail(contact.email!)
              : null,
          onTapEmpty: onEditContact,
        ),

        _buildFieldRow(
          label: isArabic ? 'الدولة' : 'Country',
          value: countryVal,
          placeholder: isArabic ? 'إضافة الدولة' : 'Add Country',
          primaryText: primaryText,
          mutedText: mutedText,
          onTapEmpty: onEditContact,
        ),

        _buildFieldRow(
          label: isArabic ? 'اللغة' : 'Language',
          value: languageVal,
          placeholder: isArabic ? 'إضافة اللغة' : 'Add Language',
          primaryText: primaryText,
          mutedText: mutedText,
          onTapEmpty: onEditContact,
        ),

        for (final entry in customEntries)
          _buildFieldRow(
            label: _formatAttrLabel(entry.key),
            value: entry.value?.toString(),
            placeholder: isArabic
                ? 'إضافة ${_formatAttrLabel(entry.key)}'
                : 'Add ${_formatAttrLabel(entry.key)}',
            primaryText: primaryText,
            mutedText: mutedText,
            onTapEmpty: onEditContact,
          ),

        const SizedBox(height: 10),
        Divider(height: 1, thickness: 1, color: dividerColor),

        // 5. Tags Section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'الوسوم' : 'Tags',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryText,
                ),
              ),
              InkWell(
                onTap: onAddTag,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: dividerColor, width: 1),
                  ),
                  child: Icon(Icons.add_rounded, size: 18, color: primaryText),
                ),
              ),
            ],
          ),
        ),
        if (state.labels.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.labels.map((tag) {
                return Chip(
                  label: Text(
                    tag,
                    style: TextStyle(fontSize: 12.5, color: primaryText),
                  ),
                  deleteIcon: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: secondaryText,
                  ),
                  onDeleted: () => onRemoveTag(tag),
                  backgroundColor: isDark
                      ? const Color(0xFF1C1D22)
                      : const Color(0xFFF1F5F9),
                  side: BorderSide(color: dividerColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }).toList(),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              isArabic ? 'لا توجد وسوم' : 'No tags added',
              style: TextStyle(fontSize: 13, color: mutedText),
            ),
          ),
      ],
    );
  }

  Widget _buildFieldRow({
    required String label,
    required String? value,
    required String placeholder,
    required Color primaryText,
    required Color mutedText,
    VoidCallback? onCopy,
    VoidCallback? onTapEmpty,
  }) {
    final hasVal =
        value != null && value.trim().isNotEmpty && value.trim() != 'null';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: primaryText,
                ),
              ),
              const SizedBox(width: 5),
              Icon(Icons.info_outline_rounded, size: 14, color: mutedText),
            ],
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: hasVal ? onCopy : onTapEmpty,
            borderRadius: BorderRadius.circular(4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    hasVal ? value : placeholder,
                    style: TextStyle(
                      fontSize: 14,
                      color: hasVal ? primaryText : mutedText,
                    ),
                  ),
                ),
                if (hasVal && onCopy != null)
                  Icon(Icons.copy_rounded, size: 16, color: mutedText),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAttrLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
