import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'custom_button.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData? icon;
  final String? lottieAsset;
  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    this.icon,
    this.lottieAsset,
    required this.title,
    required this.description,
    this.buttonText,
    this.onButtonPressed,
  }) : assert(icon != null || lottieAsset != null, 'Either icon or lottieAsset must be provided');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.0.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (lottieAsset != null)
              SizedBox(
                width: 140.r,
                height: 140.r,
                child: Lottie.asset(
                  lottieAsset!,
                  repeat: true,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon ?? Icons.inbox_rounded,
                        size: 44.r,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    );
                  },
                ),
              )
            else if (icon != null)
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon!,
                  size: 44.r,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            SizedBox(height: 18.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              SizedBox(height: 20.h),
              CustomButton(
                text: buttonText!,
                onPressed: onButtonPressed,
                height: 42,
              ),
            ],
          ]
              .animate(interval: 50.ms)
              .fadeIn(duration: 350.ms, curve: Curves.easeOut)
              .slideY(begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOut),
        ),
      ),
    );
  }
}
