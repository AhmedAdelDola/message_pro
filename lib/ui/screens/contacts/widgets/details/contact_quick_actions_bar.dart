import 'package:flutter/material.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/data/models/contact.dart';

class ContactQuickActionsBar extends StatelessWidget {
  final Contact contact;
  final VoidCallback onStartChatTap;
  final ValueChanged<String> onCallTap;
  final ValueChanged<String> onEmailTap;

  const ContactQuickActionsBar({
    super.key,
    required this.contact,
    required this.onStartChatTap,
    required this.onCallTap,
    required this.onEmailTap,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final hasPhone = contact.phoneNumber != null && contact.phoneNumber!.trim().isNotEmpty;
    final hasEmail = contact.email != null && contact.email!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: onStartChatTap,
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: Text(isArabic ? 'بدء محادثة' : 'Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          if (hasPhone) ...[
            const SizedBox(width: 8),
            _buildActionButton(
              icon: Icons.call_outlined,
              tooltip: isArabic ? 'اتصال' : 'Call',
              onTap: () => onCallTap(contact.phoneNumber!),
            ),
          ],
          if (hasEmail) ...[
            const SizedBox(width: 8),
            _buildActionButton(
              icon: Icons.mail_outline_rounded,
              tooltip: isArabic ? 'بريد' : 'Email',
              onTap: () => onEmailTap(contact.email!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.primary, size: 20),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }
}
