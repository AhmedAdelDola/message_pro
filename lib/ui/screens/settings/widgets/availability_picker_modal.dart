import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_pro/logic/auth/auth_cubit.dart';
import 'package:message_pro/ui/widgets/break_countdown_banner.dart';

class AvailabilityPickerModal {
  static void show(BuildContext context, String currentStatus, bool isArabic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161616) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0D0D0D);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB);

    final statuses = [
      {
        'key': 'online',
        'label': isArabic ? 'متصل (Online)' : 'Online',
        'desc': isArabic ? 'متاح لاستقبال المحادثات الجديدة' : 'Available for new conversations',
        'color': const Color(0xFF2CA54A),
      },
      {
        'key': 'busy',
        'label': isArabic ? 'مشغول (Busy)' : 'Busy',
        'desc': isArabic ? 'غير متاح حالياً لاستقبال محادثات جديدة' : 'Currently not taking new conversations',
        'color': const Color(0xFFFA8900),
      },
      {
        'key': 'on_break',
        'label': isArabic ? 'استراحة (On break)' : 'On break',
        'desc': isArabic ? 'في استراحة مؤقتة عن استقبال المحادثات' : 'Taking a temporary break',
        'color': const Color(0xFF6B5DE8),
      },
      {
        'key': 'offline',
        'label': isArabic ? 'غير متصل (Offline)' : 'Offline',
        'desc': isArabic ? 'تسجيل الخروج من التواجد' : 'Not available to handle chats',
        'color': const Color(0xFF80838D),
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text(
                  isArabic ? 'تحديد حالة التواجد' : 'Set Availability',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                for (final item in statuses) ...[
                  InkWell(
                    onTap: () async {
                      Navigator.pop(sheetCtx);
                      final key = item['key'] as String;
                      if (key == 'on_break' || key == 'break') {
                        final duration = await BreakDurationSheet.show(context);
                        if (duration != null && context.mounted) {
                          context.read<AuthCubit>().updateAvailability('break', breakDurationMinutes: duration);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isArabic ? 'بدأت الاستراحة لمدة $duration دقيقة' : 'Break started for $duration minutes',
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: const Color(0xFF6B5DE8),
                            ),
                          );
                        }
                      } else {
                        context.read<AuthCubit>().updateAvailability(key);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isArabic
                                  ? 'تم تغيير الحالة إلى: ${item['label']}'
                                  : 'Status updated to: ${item['label']}',
                            ),
                            duration: const Duration(seconds: 2),
                            backgroundColor: const Color(0xFF1E2024),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: currentStatus == item['key']
                            ? (isDark ? const Color(0xFF1E222A) : const Color(0xFFF1F5F9))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: currentStatus == item['key']
                              ? (item['color'] as Color)
                              : borderColor,
                          width: currentStatus == item['key'] ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: item['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['label'] as String,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['desc'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (currentStatus == item['key'])
                            Icon(Icons.check_circle_rounded, color: item['color'] as Color, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
