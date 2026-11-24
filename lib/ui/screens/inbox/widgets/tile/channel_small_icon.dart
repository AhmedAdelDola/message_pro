import 'package:flutter/material.dart';

class ChannelSmallIcon extends StatelessWidget {
  final String channelType;

  const ChannelSmallIcon({super.key, required this.channelType});

  @override
  Widget build(BuildContext context) {
    final lower = channelType.toLowerCase();
    if (lower.contains('whatsapp')) {
      return Image.asset(
        'assets/images/channels/whatsapp.png',
        width: 12,
        height: 12,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.chat_bubble_rounded,
          size: 11,
          color: Color(0xFF25D366),
        ),
      );
    }
    if (lower.contains('instagram')) {
      return const Icon(
        Icons.camera_alt_rounded,
        size: 11,
        color: Color(0xFFDD2A7B),
      );
    }
    if (lower.contains('facebook') || lower.contains('messenger')) {
      return Image.asset(
        'assets/images/channels/messenger.png',
        width: 12,
        height: 12,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.bolt_rounded,
          size: 11,
          color: Color(0xFF0084FF),
        ),
      );
    }
    if (lower.contains('telegram')) {
      return const Icon(Icons.send_rounded, size: 11, color: Color(0xFF229ED9));
    }
    if (lower.contains('email')) {
      return const Icon(Icons.mail_rounded, size: 11, color: Color(0xFFEA4335));
    }
    if (lower.contains('sms')) {
      return const Icon(Icons.sms_rounded, size: 11, color: Color(0xFF10B981));
    }
    if (lower.contains('api') || lower.contains('webhook')) {
      return const Icon(Icons.code_rounded, size: 11, color: Color(0xFF6366F1));
    }
    return const Icon(
      Icons.language_rounded,
      size: 11,
      color: Color(0xFF0284C7),
    );
  }
}
