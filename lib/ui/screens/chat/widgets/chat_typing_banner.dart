import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatTypingBanner extends StatelessWidget {
  final Set<String> typingUsers;

  const ChatTypingBanner({
    super.key,
    required this.typingUsers,
  });

  @override
  Widget build(BuildContext context) {
    if (typingUsers.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      color: Colors.blue.withValues(alpha: 0.1),
      child: Row(
        children: [
          SizedBox(
            width: 12.r,
            height: 12.r,
            child: const CircularProgressIndicator(strokeWidth: 1.5),
          ),
          SizedBox(width: 8.w),
          Text(
            '${typingUsers.join(', ')} يكتب الآن...',
            style: TextStyle(fontSize: 12.sp, color: Colors.blue, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
