import 'package:flutter/material.dart';
import '../../../../../data/models/message.dart';

class BubbleReactionsPill extends StatelessWidget {
  final Message message;
  final bool isDark;
  final ValueChanged<Message>? onViewReactions;

  const BubbleReactionsPill({
    super.key,
    required this.message,
    required this.isDark,
    this.onViewReactions,
  });

  @override
  Widget build(BuildContext context) {
    if (message.reactions.isEmpty) return const SizedBox.shrink();
    final summary = message.reactionsSummary;
    if (summary.isEmpty) return const SizedBox.shrink();

    final bgColor = isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? const Color(0xFF383838) : const Color(0xFFCBD5E1);
    final count = message.reactions.length;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onViewReactions?.call(message),
      child: Container(
        margin: const EdgeInsets.only(top: 2, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...message.uniqueReactionEmojis.take(3).map((e) => Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Text(e, style: const TextStyle(fontSize: 13)),
            )),
            if (count > 1) ...[
              const SizedBox(width: 2),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
