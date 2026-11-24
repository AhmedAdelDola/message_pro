import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:message_pro/data/models/user.dart';

class ProfileAccountDetailsCard extends StatelessWidget {
  final User user;

  const ProfileAccountDetailsCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cardBg = isDark ? const Color(0xFF161616) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0D0D0D);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _buildReadOnlyRow(
            label: isArabic ? 'الدور الوظيفي' : 'Role',
            value: user.role.toUpperCase(),
            icon: Icons.security_rounded,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          Divider(color: borderColor, height: 16.h),
          _buildReadOnlyRow(
            label: isArabic ? 'معرّف الحساب النشط' : 'Active Account ID',
            value: '#${user.accountId}',
            icon: Icons.tag_rounded,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          Divider(color: borderColor, height: 16.h),
          _buildReadOnlyRow(
            label: isArabic ? 'عدد مساحات العمل' : 'Workspaces',
            value: '${user.accounts.length}',
            icon: Icons.business_rounded,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow({
    required String label,
    required String value,
    required IconData icon,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: textSecondary),
          SizedBox(width: 10.w),
          Text(
            label,
            style: TextStyle(
              color: textSecondary,
              fontSize: 13.sp,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
