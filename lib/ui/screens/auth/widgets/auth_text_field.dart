import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:message_pro/core/constants/app_colors.dart';

class AuthTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final textTertiary = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inputBg = isDark ? AppColors.darkInputBg : AppColors.lightInputBg;
    const accentColor = AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: isArabic ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            color: textSecondary,
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 7.h),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textDirection: TextDirection.ltr,
          textAlign: isArabic ? TextAlign.right : TextAlign.left,
          onFieldSubmitted: onFieldSubmitted,
          style: TextStyle(
            fontSize: 13.sp,
            color: textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintTextDirection: TextDirection.ltr,
            hintStyle: TextStyle(
              color: textTertiary,
              fontSize: 13.sp,
            ),
            filled: true,
            fillColor: inputBg,
            suffixIcon: suffixIcon,
            contentPadding: EdgeInsetsDirectional.only(
              start: 12.w,
              end: 12.w,
              top: 12.h,
              bottom: 12.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7.r),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7.r),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7.r),
              borderSide: const BorderSide(color: accentColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7.r),
              borderSide: const BorderSide(color: Color(0xFFFB7185)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7.r),
              borderSide: const BorderSide(color: Color(0xFFFB7185), width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
