import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:message_pro/core/constants/app_colors.dart';

class ChatMutedBanner extends StatelessWidget {
  final VoidCallback onUnmute;

  const ChatMutedBanner({
    super.key,
    required this.onUnmute,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232529) : const Color(0xFFF3F4F6),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_off_rounded, size: 16.r, color: const Color(0xFF80838D)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              isArabic ? 'إشعارات هذه المحادثة مكتومة' : 'This conversation is muted',
              style: TextStyle(
                fontSize: 12.5.sp,
                color: const Color(0xFF80838D),
              ),
            ),
          ),
          TextButton(
            onPressed: onUnmute,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.primary,
            ),
            child: Text(
              isArabic ? 'إلغاء الكتم' : 'Unmute',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
