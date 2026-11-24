import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'composer_channel_logo.dart';

class ComposerRestrictedBanner extends StatelessWidget {
  final String channelType;
  final String channelName;
  final bool isDark;
  final bool isArabic;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onOpenTemplates;

  const ComposerRestrictedBanner({
    super.key,
    required this.channelType,
    required this.channelName,
    required this.isDark,
    required this.isArabic,
    required this.textPrimary,
    required this.textSecondary,
    required this.onOpenTemplates,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C1519) : const Color(0xFFFFF0F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF501C24) : const Color(0xFFFECDD3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Channel Logo + Name + Dropdown
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                ComposerChannelLogo(
                  channelType: channelType,
                  channelName: channelName,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  channelName,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: textSecondary,
                ),
              ],
            ),
          ),

          // Middle Row: 24h Restriction warning with clickable underline
          InkWell(
            onTap: onOpenTemplates,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(Icons.info_rounded, size: 16, color: Color(0xFFE11D48)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFBE123C),
                        ),
                        children: [
                          TextSpan(
                            text: isArabic
                                ? 'يمكنك الرد على هذه المحادثة فقط باستخدام قالب رسالة نظراً لـ '
                                : 'You can only reply to this conversation using a template message due to ',
                          ),
                          TextSpan(
                            text: isArabic
                                ? 'قيد نافذة الـ 24 ساعة للرسائل'
                                : '24 hour message window restriction',
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Row inside pink box: (B) on left, disabled send airplane on right
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                InkWell(
                  onTap: onOpenTemplates,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF132A1C) : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? const Color(0xFF166534) : const Color(0xFF86EFAC),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'B Templates',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF22C55E) : const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                InkWell(
                  onTap: onOpenTemplates,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF242238) : const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSent,
                      color: isDark ? const Color(0xFF818CF8) : const Color(0xFFA5B4FC),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
