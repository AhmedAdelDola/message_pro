import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:message_pro/ui/widgets/break_countdown_banner.dart';

class ProfileAvailabilitySelector extends StatelessWidget {
  final String selectedAvailability;
  final void Function(String key, int? breakDuration) onSelected;

  const ProfileAvailabilitySelector({
    super.key,
    required this.selectedAvailability,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cardBg = isDark ? const Color(0xFF161616) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final options = [
      {
        'key': 'online',
        'label': isArabic ? 'متصل' : 'Online',
        'color': const Color(0xFF2CA54A),
      },
      {
        'key': 'busy',
        'label': isArabic ? 'مشغول' : 'Busy',
        'color': const Color(0xFFFA8900),
      },
      {
        'key': 'on_break',
        'label': isArabic ? 'استراحة' : 'On break',
        'color': const Color(0xFF6B5DE8),
      },
      {
        'key': 'offline',
        'label': isArabic ? 'غير متصل' : 'Offline',
        'color': const Color(0xFF80838D),
      },
    ];

    return Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = selectedAvailability == opt['key'];
          final color = opt['color'] as Color;

          return Expanded(
            child: InkWell(
              onTap: () async {
                final key = opt['key'] as String;
                if (key == 'on_break' || key == 'break') {
                  final duration = await BreakDurationSheet.show(context);
                  if (duration != null) {
                    onSelected('break', duration);
                  }
                } else {
                  onSelected(key, null);
                }
              },
              borderRadius: BorderRadius.circular(10.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 7.r,
                      height: 7.r,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        opt['label'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? color : textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
