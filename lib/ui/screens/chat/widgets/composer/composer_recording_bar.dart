import 'package:flutter/material.dart';
import '../../../../../core/constants/app_lottie.dart';

class ComposerRecordingBar extends StatelessWidget {
  final int recordDuration;
  final bool isDark;
  final bool isArabic;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const ComposerRecordingBar({
    super.key,
    required this.recordDuration,
    required this.isDark,
    required this.isArabic,
    required this.onCancel,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = (recordDuration ~/ 60).toString().padLeft(2, '0');
    final seconds = (recordDuration % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AppLottie.voiceRecording(
            width: 26,
            height: 26,
          ),
          const SizedBox(width: 8),
          Text(
            '$minutes:$seconds',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isArabic ? 'جاري تسجيل صوتي...' : 'Recording voice note...',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
            tooltip: isArabic ? 'إلغاء' : 'Cancel',
            onPressed: onCancel,
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onSend,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
