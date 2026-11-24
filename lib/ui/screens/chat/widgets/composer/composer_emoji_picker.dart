import 'package:flutter/material.dart';

class ComposerEmojiPicker extends StatelessWidget {
  final ValueChanged<String> onSelectEmoji;

  const ComposerEmojiPicker({
    super.key,
    required this.onSelectEmoji,
  });

  static Future<void> show({
    required BuildContext context,
    required ValueChanged<String> onSelectEmoji,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => ComposerEmojiPicker(onSelectEmoji: onSelectEmoji),
    );
  }

  @override
  Widget build(BuildContext context) {
    const emojis = [
      '👍', '👋', '❤️', '😊', '🙏',
      '🔥', '🎉', '👏', '✅', '✨',
      '🤝', '😃', '💯', '👌', '🎯',
      '🙌', '⭐', '💐', '💪', '🚀',
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        color: isDark ? const Color(0xFF161616) : Colors.white,
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: emojis.map((e) {
            return InkWell(
              onTap: () {
                onSelectEmoji(e);
                Navigator.pop(context);
              },
              child: Text(e, style: const TextStyle(fontSize: 28)),
            );
          }).toList(),
        ),
      ),
    );
  }
}
