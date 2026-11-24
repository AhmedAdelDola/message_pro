import 'package:flutter/material.dart';
import '../../../../../data/models/message.dart';

class MessageDeliveryStatus extends StatelessWidget {
  final Message message;
  final bool isTemplate;
  final bool isDark;

  const MessageDeliveryStatus({
    super.key,
    required this.message,
    this.isTemplate = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final status = message.status;
    if (status == 'sending' || message.isSending) {
      return Icon(
        Icons.access_time_rounded,
        size: 13,
        color: isTemplate
            ? (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))
            : Colors.white70,
      );
    } else if (status == 'failed') {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 12, color: Color(0xFFDC2626)),
          SizedBox(width: 2),
          Text(
            'فشل الإرسال',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626),
            ),
          ),
        ],
      );
    } else if (status == 'read' || status == 'seen') {
      return const Icon(
        Icons.done_all_rounded,
        size: 14,
        color: Color(0xFF2563EB), // Vibrant blue for read/seen!
      );
    } else if (status == 'delivered') {
      return Icon(
        Icons.done_all_rounded,
        size: 14,
        color: isTemplate
            ? (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))
            : Colors.white70,
      );
    } else if (status == 'sent') {
      return Icon(
        Icons.check_rounded,
        size: 14,
        color: isTemplate
            ? (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))
            : Colors.white70,
      );
    }
    return const SizedBox.shrink();
  }
}

class ExternalStatusIndicator extends StatelessWidget {
  final Message message;
  final VoidCallback? onRetry;

  const ExternalStatusIndicator({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isFailed) {
      return InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF87171), width: 1),
          ),
          child: const Icon(
            Icons.refresh_rounded,
            size: 15,
            color: Color(0xFFDC2626),
          ),
        ),
      );
    } else if (message.isRead) {
      return const Padding(
        padding: EdgeInsets.only(right: 6),
        child: Icon(
          Icons.done_all_rounded,
          size: 19,
          color: Color(0xFF2563EB),
        ),
      );
    } else if (message.isDelivered) {
      return const Padding(
        padding: EdgeInsets.only(right: 6),
        child: Icon(
          Icons.done_all_rounded,
          size: 19,
          color: Color(0xFF9CA3AF),
        ),
      );
    } else if (message.isSent) {
      return const Padding(
        padding: EdgeInsets.only(right: 6),
        child: Icon(
          Icons.done_rounded,
          size: 17,
          color: Color(0xFF9CA3AF),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
