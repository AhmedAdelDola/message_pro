import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../data/models/message_template.dart';

/// Shared stacked interactive/template action buttons for chat bubbles.
class InteractiveActionButtons extends StatelessWidget {
  final List<TemplateButton> buttons;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;

  const InteractiveActionButtons({
    super.key,
    required this.buttons,
    required this.backgroundColor,
    required this.borderColor,
    this.foregroundColor = const Color(0xFF2563EB),
  });

  @override
  Widget build(BuildContext context) {
    if (buttons.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 0.9,
        ),
      ),
      child: Column(
        children: List.generate(buttons.length, (idx) {
          final btn = buttons[idx];
          final isLast = idx == buttons.length - 1;

          return InkWell(
            onTap: () async {
              if (btn.isUrl && btn.url != null) {
                final uri = Uri.tryParse(btn.url!);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
            borderRadius: BorderRadius.vertical(
              top: idx == 0 ? const Radius.circular(8) : Radius.zero,
              bottom: isLast ? const Radius.circular(8) : Radius.zero,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: borderColor,
                          width: 0.8,
                        ),
                      ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    btn.isUrl ? Icons.open_in_new_rounded : Icons.reply_rounded,
                    size: 15,
                    color: foregroundColor,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      btn.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: foregroundColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
