import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'open':
        bg = AppColors.success.withValues(alpha: 0.15);
        text = AppColors.success;
        label = 'مفتوح (Open)';
        break;
      case 'resolved':
        bg = Colors.grey.withValues(alpha: 0.15);
        text = Colors.grey;
        label = 'مغلق (Resolved)';
        break;
      case 'snoozed':
        bg = AppColors.warning.withValues(alpha: 0.15);
        text = AppColors.warning;
        label = 'مؤجل (Snoozed)';
        break;
      case 'pending':
        bg = AppColors.info.withValues(alpha: 0.15);
        text = AppColors.info;
        label = 'معلق (Pending)';
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.15);
        text = Colors.grey;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
