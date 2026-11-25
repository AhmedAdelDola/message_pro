import 'package:flutter/material.dart';

/// Renders the authentic channel logo for WhatsApp, Messenger, Instagram, Telegram, Email, SMS, API, or Web.
class ChannelLogoWidget extends StatelessWidget {
  final String channelType;
  final String? channelName;
  final double size;

  const ChannelLogoWidget({
    super.key,
    required this.channelType,
    this.channelName,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final lower = channelType.toLowerCase();
    final nameLower = (channelName ?? '').toLowerCase();

    // 1. WhatsApp
    if (lower.contains('whatsapp') ||
        lower.contains('twilio') ||
        lower.contains('message-pro') ||
        nameLower.contains('whatsapp') ||
        nameLower.contains('message-pro')) {
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
          child: Icon(Icons.chat_rounded, size: size * 0.58, color: Colors.white),
        ),
      );
    }

    // 2. Facebook / Messenger
    if (lower.contains('facebook') ||
        lower.contains('messenger') ||
        nameLower.contains('facebook') ||
        nameLower.contains('messenger')) {
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

    // 3. Instagram (Authentic rounded-square gradient + white camera glyph)
    if (lower.contains('instagram') || nameLower.contains('instagram')) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _InstagramLogoPainter(),
        ),
      );
    }

    // 4. Telegram
    if (lower.contains('telegram') || nameLower.contains('telegram')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF229ED9),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.send_rounded, size: size * 0.54, color: Colors.white),
      );
    }

    // 5. Email
    if (lower.contains('email') || nameLower.contains('email')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFEA4335),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.mail_rounded, size: size * 0.56, color: Colors.white),
      );
    }

    // 6. SMS
    if (lower.contains('sms') || nameLower.contains('sms')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF10B981),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.sms_rounded, size: size * 0.55, color: Colors.white),
      );
    }

    // 7. API / Webhook
    if (lower.contains('api') || lower.contains('webhook')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF6366F1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.code_rounded, size: size * 0.58, color: Colors.white),
      );
    }

    // 8. Default / Web Widget
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF0284C7),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.language_rounded, size: size * 0.58, color: Colors.white),
    );
  }
}

class _InstagramLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.width * 0.24),
    );

    const gradient = LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [
        Color(0xFFFEDA75),
        Color(0xFFFA7E1E),
        Color(0xFFD62976),
        Color(0xFF962FBF),
        Color(0xFF4F5BD5),
      ],
    );

    final bgPaint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRRect(rrect, bgPaint);

    final strokeWidth = (size.width * 0.085).clamp(1.0, 3.0);
    final whiteStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Inner rounded camera frame
    final inset = size.width * 0.19;
    final innerRect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, Radius.circular(size.width * 0.16)),
      whiteStroke,
    );

    // Center lens circle
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.155,
      whiteStroke,
    );

    // Top-right flash dot
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(size.width * 0.695, size.height * 0.305),
      size.width * 0.052,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
