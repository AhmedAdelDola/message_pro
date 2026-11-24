import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../data/models/message.dart';

class BubblePlatformBadge extends StatelessWidget {
  final String channelName;
  final double size;

  const BubblePlatformBadge({
    super.key,
    required this.channelName,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final lower = channelName.toLowerCase();

    // 1. WhatsApp
    if (lower.contains('whatsapp')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF25D366),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF25D366).withValues(alpha: 0.35),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2.5),
        child: ClipOval(
          child: Image.asset(
            'assets/images/channels/whatsapp.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Center(
              child: Icon(Icons.chat_bubble_rounded, size: size * 0.55, color: Colors.white),
            ),
          ),
        ),
      );
    }

    // 2. Facebook / Messenger
    if (lower.contains('facebook') || lower.contains('messenger')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF00C6FF), Color(0xFF0078FF)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0078FF).withValues(alpha: 0.35),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/channels/messenger.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(
              child: Icon(Icons.bolt_rounded, size: size * 0.6, color: Colors.white),
            ),
          ),
        ),
      );
    }

    // 3. Instagram
    if (lower.contains('instagram')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xFFF58529),
              Color(0xFFDD2A7B),
              Color(0xFF8134AF),
              Color(0xFF515BD4),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDD2A7B).withValues(alpha: 0.35),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.camera_alt_rounded,
            size: size * 0.55,
            color: Colors.white,
          ),
        ),
      );
    }

    // 4. Telegram
    if (lower.contains('telegram')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF229ED9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF229ED9).withValues(alpha: 0.35),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Icon(Icons.send_rounded, size: size * 0.5, color: Colors.white),
        ),
      );
    }

    // Default / Web
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF4162E3),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4162E3).withValues(alpha: 0.35),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Icon(Icons.language_rounded, size: size * 0.55, color: Colors.white),
      ),
    );
  }
}

class OutgoingSenderBadge extends StatelessWidget {
  final Message message;
  final String? channel;
  final double size;

  const OutgoingSenderBadge({
    super.key,
    required this.message,
    this.channel,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveChannel = channel ??
        message.contentAttributes['channel']?.toString() ??
        'whatsapp';

    Widget badgeContent;
    String tooltipMsg;

    if (message.isSentByAgent || (message.senderAvatar != null && message.senderAvatar!.isNotEmpty)) {
      final name = message.senderName?.trim();
      tooltipMsg = (name != null && name.isNotEmpty) ? name : 'موظف';
      if (message.senderAvatar != null && message.senderAvatar!.isNotEmpty) {
        badgeContent = CircleAvatar(
          radius: size / 2,
          backgroundImage: CachedNetworkImageProvider(message.senderAvatar!),
        );
      } else {
        badgeContent = CircleAvatar(
          radius: size / 2,
          backgroundColor: const Color(0xFF4162E3).withValues(alpha: 0.15),
          child: Text(
            (name != null && name.isNotEmpty)
                ? name[0].toUpperCase()
                : 'A',
            style: TextStyle(
              fontSize: size * 0.42,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4162E3),
            ),
          ),
        );
      }
    } else if (message.isBot) {
      tooltipMsg = 'رد آلي / بوت';
      badgeContent = CircleAvatar(
        radius: size / 2,
        backgroundColor: const Color(0xFFEFF6FF),
        child: Icon(
          Icons.smart_toy_outlined,
          size: size * 0.58,
          color: const Color(0xFF3B82F6),
        ),
      );
    } else {
      final chLower = effectiveChannel.toLowerCase();
      if (chLower.contains('whatsapp')) {
        tooltipMsg = 'مُرسل من واتساب';
      } else if (chLower.contains('messenger') || chLower.contains('facebook')) {
        tooltipMsg = 'مُرسل من ماسنجر';
      } else if (chLower.contains('instagram')) {
        tooltipMsg = 'مُرسل من إنستغرام';
      } else if (chLower.contains('telegram')) {
        tooltipMsg = 'مُرسل من تيليجرام';
      } else {
        tooltipMsg = 'مُرسل من المنصة';
      }
      badgeContent = BubblePlatformBadge(channelName: effectiveChannel, size: size);
    }

    return Tooltip(
      message: tooltipMsg,
      preferBelow: false,
      child: SizedBox(
        width: size,
        height: size,
        child: badgeContent,
      ),
    );
  }
}
