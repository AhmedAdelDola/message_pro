import 'package:flutter/material.dart';
import '../../../../../data/models/message.dart';

class ActivityBubbleView extends StatelessWidget {
  final Message message;
  final bool isDark;

  const ActivityBubbleView({
    super.key,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final rawText = message.content ?? '';
    final text = rawText
        .replaceAll(RegExp(r'</?(b|strong|p|span)[^>]*>', caseSensitive: false), '')
        .replaceAll('*', '')
        .trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 16),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.normal,
            height: 1.25,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
