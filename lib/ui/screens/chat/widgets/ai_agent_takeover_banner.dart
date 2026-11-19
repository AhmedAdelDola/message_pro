import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_lottie.dart';

class AiAgentTakeoverBanner extends StatelessWidget {
  final String agentName;
  final bool isLoading;
  final VoidCallback onTakeover;

  const AiAgentTakeoverBanner({
    super.key,
    required this.agentName,
    required this.isLoading,
    required this.onTakeover,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final bgColor = isDark ? const Color(0xFF231D33) : const Color(0xFFFBF8FF);
    final borderColor = isDark ? const Color(0xFF3F325E) : const Color(0xFFE9E5FA);
    final titleColor = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    const purplePrimary = Color(0xFF5850EC);

    final displayName = agentName.isNotEmpty ? agentName : (isArabic ? 'مساعد الذكاء الاصطناعي' : 'AI Agent');

    // Extract leading emoji if present (e.g. 🤠 Sales agent)
    String iconEmoji = '🤖';
    final trimmed = displayName.trim();
    if (trimmed.isNotEmpty) {
      final firstChar = trimmed.characters.first;
      if (firstChar.runes.isNotEmpty && (firstChar.runes.first > 255 || firstChar.runes.first == 0x2B50)) {
        iconEmoji = firstChar;
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Emoji or Bot Icon with AI Sparkle Lottie
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: EdgeInsets.all(7.r),
                decoration: BoxDecoration(
                  color: purplePrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  iconEmoji,
                  style: TextStyle(fontSize: 18.sp),
                ),
              ),
              Positioned(
                top: -6.r,
                right: -6.r,
                child: AppLottie.aiSparkle(
                  width: 18.r,
                  height: 18.r,
                ),
              ),
            ],
          ),
          SizedBox(width: 10.w),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isArabic
                      ? '$displayName يتولى إدارة هذه المحادثة الآن'
                      : '$displayName is handling this conversation',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  isArabic
                      ? "اضغط 'Takeover' وسيتوقف مساعد الذكاء الاصطناعي عن الرد. سيتم تعيين المحادثة لك."
                      : "Click 'Takeover' and the AI Agent will stop responding. You will be assigned to the conversation.",
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    color: subtitleColor,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),

          // Takeover Button
          ElevatedButton(
            onPressed: isLoading ? null : onTakeover,
            style: ElevatedButton.styleFrom(
              backgroundColor: purplePrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              minimumSize: Size(0, 34.h),
            ),
            child: isLoading
                ? SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Takeover',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
