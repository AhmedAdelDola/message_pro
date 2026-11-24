import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final bool isArabic;
  final Color borderColor;
  final Color inputBg;
  final Color textPrimary;
  final VoidCallback? onPressed;

  const GoogleSignInButton({
    super.key,
    required this.isLoading,
    required this.isArabic,
    required this.borderColor,
    required this.inputBg,
    required this.textPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45.h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor),
          backgroundColor: inputBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 18.r,
                height: 18.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textPrimary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 20.r,
                    height: 20.r,
                    alignment: Alignment.center,
                    child: Text(
                      'G',
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4285F4),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    isArabic ? 'المتابعة باستخدام Google' : 'Continue with Google',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
