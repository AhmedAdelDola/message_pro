import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'ai_agent_takeover_banner.dart';

class ChatAiTakeoverArea extends StatelessWidget {
  final String channelName;
  final String aiAgentName;
  final bool isTakingOver;
  final VoidCallback onTakeover;

  const ChatAiTakeoverArea({
    super.key,
    required this.channelName,
    required this.aiAgentName,
    required this.isTakingOver,
    required this.onTakeover,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.8,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 6.h),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/channels/whatsapp.png',
                    width: 15.r,
                    height: 15.r,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 15.r,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    channelName,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 10.h),
              child: AiAgentTakeoverBanner(
                agentName: aiAgentName,
                isLoading: isTakingOver,
                onTakeover: onTakeover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
