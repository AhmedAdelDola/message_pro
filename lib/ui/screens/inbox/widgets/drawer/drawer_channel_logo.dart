import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DrawerChannelLogo extends StatelessWidget {
  final String? channelType;
  final String? avatarUrl;
  final double size;

  const DrawerChannelLogo({
    super.key,
    this.channelType,
    this.avatarUrl,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _buildChannelDefaultIcon(channelType, size: size),
        ),
      );
    }
    return _buildChannelDefaultIcon(channelType, size: size);
  }

  Widget _buildChannelDefaultIcon(String? channelType, {double size = 32}) {
    final lower = (channelType ?? '').toLowerCase();
    String? assetPath;
    Color iconColor = const Color(0xFF0284C7);
    IconData fallbackIcon = Icons.language_rounded;

    if (lower.contains('whatsapp')) {
      assetPath = 'assets/images/channels/whatsapp.png';
      iconColor = const Color(0xFF25D366);
      fallbackIcon = Icons.chat_bubble_rounded;
    } else if (lower.contains('messenger') || lower.contains('facebook')) {
      assetPath = 'assets/images/channels/messenger.png';
      iconColor = const Color(0xFF0084FF);
      fallbackIcon = Icons.bolt_rounded;
    } else if (lower.contains('instagram')) {
      iconColor = const Color(0xFFDD2A7B);
      fallbackIcon = Icons.camera_alt_rounded;
    } else if (lower.contains('telegram')) {
      iconColor = const Color(0xFF229ED9);
      fallbackIcon = Icons.send_rounded;
    } else if (lower.contains('email')) {
      iconColor = const Color(0xFFEA4335);
      fallbackIcon = Icons.mail_rounded;
    } else if (lower.contains('sms')) {
      iconColor = const Color(0xFF10B981);
      fallbackIcon = Icons.sms_rounded;
    } else if (lower.contains('api') || lower.contains('webhook')) {
      iconColor = const Color(0xFF6366F1);
      fallbackIcon = Icons.code_rounded;
    }

    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(fallbackIcon, size: size * 0.7, color: iconColor),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(fallbackIcon, size: size * 0.55, color: iconColor),
    );
  }
}
