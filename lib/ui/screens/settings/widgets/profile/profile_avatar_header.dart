import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:message_pro/data/models/user.dart';
import 'package:message_pro/ui/widgets/avatar_widget.dart';

class ProfileAvatarHeader extends StatelessWidget {
  final User user;
  final String availabilityStatus;
  final Color statusColor;

  const ProfileAvatarHeader({
    super.key,
    required this.user,
    required this.availabilityStatus,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0D0D0D);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Center(
      child: Column(
        children: [
          Container(
            width: 88.r,
            height: 88.r,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: statusColor, width: 2.5),
            ),
            child: AvatarWidget(
              avatarUrl: user.avatarUrl,
              name: user.name,
              size: 80,
              showStatus: true,
              availabilityStatus: availabilityStatus,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            user.name,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            user.email,
            style: TextStyle(
              fontSize: 13.sp,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
