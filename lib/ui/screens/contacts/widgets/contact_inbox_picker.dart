import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ContactInboxPicker extends StatelessWidget {
  final List<Map<String, dynamic>> inboxes;
  final ValueChanged<Map<String, dynamic>> onSelectInbox;

  const ContactInboxPicker({
    super.key,
    required this.inboxes,
    required this.onSelectInbox,
  });

  static Future<void> show({
    required BuildContext context,
    required List<Map<String, dynamic>> inboxes,
    required ValueChanged<Map<String, dynamic>> onSelectInbox,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ContactInboxPicker(
        inboxes: inboxes,
        onSelectInbox: onSelectInbox,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;

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
              ),
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: inboxes.length,
              itemBuilder: (ctx, index) {
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

                Widget channelIcon;
                Color iconColor = AppColors.primary;
                if (isWhatsApp) {
                  channelIcon = Image.asset(
                    'assets/images/channels/whatsapp.png',
                    width: 22,
                    height: 22,
                    errorBuilder: (_, __, ___) => const Icon(Icons.chat, color: Color(0xFF25D366)),
                  );
                } else if (isMessenger) {
                  channelIcon = Image.asset(
                    'assets/images/channels/messenger.png',
                    width: 22,
                    height: 22,
                    errorBuilder: (_, __, ___) => const Icon(Icons.facebook, color: Color(0xFF0084FF)),
                  );
                } else if (isInstagram) {
                  channelIcon = Image.asset(
                    'assets/images/channels/instagram.png',
                    width: 22,
                    height: 22,
                    errorBuilder: (_, __, ___) => const Icon(Icons.camera_alt, color: Color(0xFFE4405F)),
                  );
                } else if (isEmail) {
                  channelIcon = const Icon(Icons.email_outlined, color: Color(0xFFEA4335), size: 22);
                } else {
                  channelIcon = Icon(Icons.language_rounded, color: iconColor, size: 22);
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9),
                    child: channelIcon,
                  ),
                  title: Text(
                    rawName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      color: textPrimary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                  onTap: () {
                    Navigator.pop(ctx);
                    onSelectInbox(inb);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
