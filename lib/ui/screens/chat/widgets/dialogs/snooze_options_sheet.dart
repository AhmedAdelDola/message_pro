import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';

class SnoozeOptionsSheet extends StatelessWidget {
  final String status;
  final ValueChanged<String?> onSnoozeSelected;

  const SnoozeOptionsSheet({
    super.key,
    required this.status,
    required this.onSnoozeSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required String status,
    required ValueChanged<String?> onSnoozeSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => SnoozeOptionsSheet(
        status: status,
        onSnoozeSelected: onSnoozeSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Text(
              isArabic ? 'خيارات تأجيل المحادثة' : 'Snooze Conversation',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          if (status == 'snoozed')
            ListTile(
              leading: const Icon(Icons.alarm_off_rounded, color: Color(0xFFFA8900)),
              title: Text(isArabic ? 'إلغاء التأجيل (Unsnooze)' : 'Unsnooze'),
              subtitle: Text(isArabic ? 'إعادة المحادثة للوضع المفتوح' : 'Revert conversation to open'),
              onTap: () {
                Navigator.pop(context);
                onSnoozeSelected('unsnooze');
              },
            ),
          ListTile(
            leading: const Icon(Icons.reply_rounded, color: AppColors.primary),
            title: Text(isArabic ? 'حتى الرد القادم' : 'Until next reply'),
            subtitle: Text(isArabic ? 'تظل مؤجلة حتى يرد العميل' : 'Snooze until customer replies'),
            onTap: () {
              Navigator.pop(context);
              onSnoozeSelected(null);
            },
          ),
          ListTile(
            leading: const Icon(Icons.today_rounded, color: Color(0xFF10B981)),
            title: Text(isArabic ? 'حتى الغد 9:00 ص' : 'Tomorrow at 9:00 AM'),
            subtitle: Text(
              DateFormat('EEEE, d MMM - 9:00 AM').format(
                DateTime.now().add(const Duration(days: 1)).copyWith(hour: 9, minute: 0, second: 0),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              final now = DateTime.now();
              final tomorrow9am = DateTime(now.year, now.month, now.day + 1, 9, 0, 0);
              onSnoozeSelected(tomorrow9am.toUtc().toIso8601String());
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_rounded, color: Color(0xFF8B5CF6)),
            title: Text(isArabic ? 'الأسبوع القادم' : 'Next week'),
            subtitle: Text(
              DateFormat('EEEE, d MMM - 9:00 AM').format(
                DateTime.now().add(Duration(days: ((8 - DateTime.now().weekday) <= 0 ? 7 : (8 - DateTime.now().weekday)))).copyWith(hour: 9, minute: 0, second: 0),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              final now = DateTime.now();
              final daysUntilNextMonday = (DateTime.monday - now.weekday + 7) % 7;
              final addDays = daysUntilNextMonday == 0 ? 7 : daysUntilNextMonday;
              final nextWeekMonday9am = DateTime(now.year, now.month, now.day + addDays, 9, 0, 0);
              onSnoozeSelected(nextWeekMonday9am.toUtc().toIso8601String());
            },
          ),
        ],
      ),
    );
  }
}
