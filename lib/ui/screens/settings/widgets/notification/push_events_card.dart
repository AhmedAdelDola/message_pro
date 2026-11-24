import 'package:flutter/material.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/data/models/notification_settings.dart';

class PushEventsCard extends StatefulWidget {
  final NotificationSettings settings;
  final void Function(String eventKey, bool enable) onToggleEvent;
  final String Function(String eventKey, bool isArabic) eventTitle;
  final String Function(String eventKey, bool isArabic) eventDescription;

  const PushEventsCard({
    super.key,
    required this.settings,
    required this.onToggleEvent,
    required this.eventTitle,
    required this.eventDescription,
  });

  @override
  State<PushEventsCard> createState() => _PushEventsCardState();
}

class _PushEventsCardState extends State<PushEventsCard> {
  bool _isExpanded = true;

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
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'تخصيص أحداث الموبايل' : 'Mobile Alert Events',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isArabic
                              ? 'حدد الأحداث التي تود تلقي إشعار فوري بها على هاتفك.'
                              : 'Select exactly which events trigger a push alert.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            Divider(color: borderColor, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: NotificationSettings.allEvents.map((eventKey) {
                  final isEnabled = widget.settings.hasPushFlag(eventKey);
                  return SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    activeTrackColor: AppColors.primary,
                    activeThumbColor: Colors.white,
                    title: Text(
                      widget.eventTitle(eventKey, isArabic),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      widget.eventDescription(eventKey, isArabic),
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    value: isEnabled,
                    onChanged: (val) => widget.onToggleEvent(eventKey, val),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
