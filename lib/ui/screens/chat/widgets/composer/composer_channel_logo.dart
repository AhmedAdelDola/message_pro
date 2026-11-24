import 'package:flutter/material.dart';

class ComposerChannelLogo extends StatelessWidget {
  final String channelType;
  final String channelName;
  final double size;

  const ComposerChannelLogo({
    super.key,
    required this.channelType,
    required this.channelName,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final lower = channelType.toLowerCase();

    // 1. WhatsApp
    if (lower.contains('whatsapp') ||
        lower.contains('twilio') ||
        lower.contains('message-pro') ||
        channelName.toLowerCase().contains('message-pro') ||
        channelName.toLowerCase().contains('whatsapp')) {
      return Image.asset(
        'assets/images/channels/whatsapp.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Color(0xFF25D366),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.chat_bubble, size: size * 0.55, color: Colors.white),
        ),
      );
    }

    // 2. Facebook / Messenger
    if (lower.contains('facebook') || lower.contains('messenger')) {
      return Image.asset(
        'assets/images/channels/messenger.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Color(0xFF0084FF),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.bolt_rounded, size: size * 0.65, color: Colors.white),
        ),
      );
    }

    // 3. Instagram
    if (lower.contains('instagram')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.camera_alt_rounded, size: size * 0.6, color: Colors.white),
      );
    }

    // 4. Telegram
    if (lower.contains('telegram')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF2AABEE),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.send_rounded, size: size * 0.55, color: Colors.white),
      );
    }

    // 5. Email
    if (lower.contains('email')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFEA4335),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.mail_rounded, size: size * 0.55, color: Colors.white),
      );
    }

    // Default / Web
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF4162E3),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.language_rounded, size: size * 0.55, color: Colors.white),
    );
  }
}
