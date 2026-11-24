import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginHeader extends StatelessWidget {
  final bool isArabic;
  final bool isDark;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onLanguageToggle;

  const LoginHeader({
    super.key,
    required this.isArabic,
    required this.isDark,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onLanguageToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/brand/fulllogobabyblue2.png',
          width: 200.w,
          height: 62.h,
          fit: BoxFit.contain,
          alignment: AlignmentDirectional.centerStart,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/images/brand/fulllogobabyblue2.png',
            width: 160.w,
            height: 32.h,
            fit: BoxFit.contain,
            alignment: AlignmentDirectional.centerStart,
          ),
        ),
        InkWell(
          onTap: onLanguageToggle,
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E20) : const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/translate-stroke-rounded.svg',
                  width: 14.r,
                  height: 14.r,
                  colorFilter: ColorFilter.mode(textSecondary, BlendMode.srcIn),
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.language,
                    size: 14.r,
                    color: textSecondary,
                  ),
                ),
                SizedBox(width: 5.w),
                Text(
                  isArabic ? 'English' : 'العربية',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
