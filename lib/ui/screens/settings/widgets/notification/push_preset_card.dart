import 'package:flutter/material.dart';
import 'package:message_pro/core/constants/app_colors.dart';

class PushPresetCard extends StatelessWidget {
  final String presetValue;
  final ValueChanged<String?> onPresetChanged;

  const PushPresetCard({
    super.key,
    required this.presetValue,
    required this.onPresetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'إشعارات الموبايل المباشرة (Push)' : 'Mobile push notifications',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: presetValue,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: textSecondary),
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                dropdownColor: cardBg,
                onChanged: onPresetChanged,
                items: [
                  DropdownMenuItem(
                    value: 'All conversations',
                    child: Text(isArabic ? 'كل المحادثات' : 'All conversations'),
                  ),
                  DropdownMenuItem(
                    value: 'Assigned only',
                    child: Text(isArabic ? 'المحادثات المعينة لي فقط' : 'Assigned only'),
                  ),
                  DropdownMenuItem(
                    value: 'Custom selection',
                    child: Text(isArabic ? 'تحديد مخصص' : 'Custom selection'),
                  ),
                  DropdownMenuItem(
                    value: 'None',
                    child: Text(isArabic ? 'إيقاف الإشعارات' : 'None'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isArabic
                ? 'تتحكم هذه القائمة في أحداث التنبيهات لأجهزتك المحمولة المسجلة لدى الخادم.'
                : 'Controls notification events dispatched to your registered mobile devices.',
            style: TextStyle(
              fontSize: 12.5,
              color: textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
