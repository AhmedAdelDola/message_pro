import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/contact.dart';
import 'contact_field_tile.dart';

class ContactDetailsTab extends StatelessWidget {
  final Contact contact;
  final String lifecycleStage;
  final List<String> contactLabels;
  final bool isLoadingLabels;
  final VoidCallback onSelectLifecycleStage;
  final VoidCallback onAddLabel;
  final ValueChanged<String> onRemoveLabel;
  final void Function(String text, String label) onCopy;
  final ValueChanged<String> onSendEmail;

  const ContactDetailsTab({
    super.key,
    required this.contact,
    required this.lifecycleStage,
    required this.contactLabels,
    required this.isLoadingLabels,
    required this.onSelectLifecycleStage,
    required this.onAddLabel,
    required this.onRemoveLabel,
    required this.onCopy,
    required this.onSendEmail,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

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
                ),
              ),
              InkWell(
                onTap: onSelectLifecycleStage,
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
                        lifecycleStage,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
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
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: onAddLabel,
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
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (isLoadingLabels)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5)),
                )
              else if (contactLabels.isEmpty)
                Text(
                  isArabic ? 'لا توجد تصنيفات حالياً لهذا العميل' : 'No labels assigned to this contact',
                  style: TextStyle(fontSize: 12, color: textSecondary.withValues(alpha: 0.7)),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: contactLabels.map((tag) {
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
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => onRemoveLabel(tag),
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
        ContactFieldTile(
          label: isArabic ? 'رقم الهاتف' : 'Phone Number',
          value: phone != null && phone.isNotEmpty ? phone : (isArabic ? 'غير متوفر' : 'Not available'),
          isPlaceholder: phone == null || phone.isEmpty,
          onCopy: phone != null && phone.isNotEmpty ? () => onCopy(phone, isArabic ? 'رقم الهاتف' : 'Phone Number') : null,
        ),
        ContactFieldTile(
          label: isArabic ? 'البريد الإلكتروني' : 'Email Address',
          value: email != null && email.isNotEmpty ? email : (isArabic ? 'غير متوفر' : 'Not available'),
          isPlaceholder: email == null || email.isEmpty,
          onCopy: email != null && email.isNotEmpty ? () => onCopy(email, 'Email') : null,
          actionIcon: email != null && email.isNotEmpty ? Icons.email_rounded : null,
          onAction: email != null && email.isNotEmpty ? () => onSendEmail(email) : null,
        ),
        ContactFieldTile(
          label: isArabic ? 'المعرف الفريد' : 'Identifier',
          value: identifier != null && identifier.isNotEmpty ? identifier : (isArabic ? 'غير محدد' : 'Not specified'),
          isPlaceholder: identifier == null || identifier.isEmpty,
          onCopy: identifier != null && identifier.isNotEmpty ? () => onCopy(identifier, 'Identifier') : null,
        ),
        ContactFieldTile(
          label: isArabic ? 'رقم العميل' : 'Contact ID',
          value: '#${contact.id}',
          onCopy: () => onCopy('${contact.id}', 'Contact ID'),
        ),
      ],
    );
  }
}
