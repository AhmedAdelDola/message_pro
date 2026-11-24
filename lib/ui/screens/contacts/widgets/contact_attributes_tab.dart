import 'package:flutter/material.dart';
import '../../../../data/models/contact.dart';
import 'contact_field_tile.dart';

class ContactAttributesTab extends StatelessWidget {
  final Contact contact;
  final void Function(String text, String label) onCopy;

  const ContactAttributesTab({
    super.key,
    required this.contact,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final attributes = contact.customAttributes;

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

        return ContactFieldTile(
          label: keyName,
          value: val.isNotEmpty ? val : '-',
          isPlaceholder: val.isEmpty,
          onCopy: val.isNotEmpty ? () => onCopy(val, keyName) : null,
        );
      }).toList(),
    );
  }
}
