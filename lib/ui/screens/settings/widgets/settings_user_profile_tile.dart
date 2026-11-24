import 'package:flutter/material.dart';
import 'package:message_pro/data/models/user.dart';
import 'package:message_pro/ui/widgets/avatar_widget.dart';

class SettingsUserProfileTile extends StatelessWidget {
  final User user;
  final Color statusColor;
  final Color borderColor;
  final VoidCallback onTap;

  const SettingsUserProfileTile({
    super.key,
    required this.user,
    required this.statusColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textPrimary = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0D0D0D);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF626F7F);
    final availability = user.availabilityStatus;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: statusColor,
                  width: 2,
                ),
              ),
              child: AvatarWidget(
                avatarUrl: user.avatarUrl,
                name: user.name,
                size: 44,
                showStatus: true,
                availabilityStatus: availability,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              color: const Color(0xFF80838D),
            ),
          ],
        ),
      ),
    );
  }
}
