import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';

class AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;
  final String? channel;
  final bool isOnline;
  final bool showStatus;
  final String? availabilityStatus;

  const AvatarWidget({
    super.key,
    this.avatarUrl,
    required this.name,
    this.size = 44,
    this.channel,
    this.isOnline = false,
    this.showStatus = false,
    this.availabilityStatus,
  });

  String get _initials {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    final firstChar = parts[0].isNotEmpty ? parts[0][0] : '';
    final secondChar = parts[1].isNotEmpty ? parts[1][0] : '';
    final res = '$firstChar$secondChar'.trim();
    return res.isNotEmpty ? res.toUpperCase() : '?';
  }

  Color get _backgroundColor {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
    ];
    if (name.trim().isEmpty || name.codeUnits.isEmpty) return colors[0];
    final sum = name.codeUnits.reduce((a, b) => a + b);
    return colors[sum % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final double responsiveSize = size.r;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: responsiveSize,
          height: responsiveSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _backgroundColor,
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: avatarUrl!,
                    fit: BoxFit.cover,
                    // Performance optimization: limit decoded image resolution in memory
                    memCacheWidth: (responsiveSize * 2.5).round(),
                    memCacheHeight: (responsiveSize * 2.5).round(),
                    placeholder: (context, url) => Center(
                      child: Text(
                        _initials,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: responsiveSize * 0.4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Text(
                        _initials,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: responsiveSize * 0.4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      _initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsiveSize * 0.4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ),
        if (channel != null && channel!.isNotEmpty)
          PositionedDirectional(
            end: -2.w,
            bottom: -2.h,
            child: RepaintBoundary(
              child: _buildChannelBadge(context, channel!, responsiveSize),
            ),
          )
        else if (showStatus)
          PositionedDirectional(
            end: 0,
            bottom: 0,
            child: RepaintBoundary(
              child: Container(
                width: responsiveSize * 0.28,
                height: responsiveSize * 0.28,
                decoration: BoxDecoration(
                  color: _resolveStatusColor(),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5.r,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _resolveStatusColor() {
    if (availabilityStatus != null) {
      switch (availabilityStatus!.toLowerCase()) {
        case 'busy':
          return const Color(0xFFFA8900);
        case 'offline':
          return const Color(0xFF80838D);
        case 'online':
        default:
          return const Color(0xFF2CA54A);
      }
    }
    return isOnline ? AppColors.success : const Color(0xFF80838D);
  }

  Widget _buildChannelBadge(BuildContext context, String ch, double responsiveSize) {
    final lower = ch.toLowerCase();
    final badgeSize = (responsiveSize * 0.42).clamp(16.0, 22.0);
    final borderColor = Theme.of(context).cardColor;

    // 1. WhatsApp: WhatsApp icon (green circle with white chat bubble matching CRM web exactly)
    if (lower.contains('whatsapp')) {
      return Container(
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E),
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
            width: 1.5.r,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22C55E).withValues(alpha: 0.35),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Icon(Icons.chat_bubble, size: badgeSize * 0.58, color: Colors.white),
        ),
      );
    }

    // 2. Instagram: Instagram gradient / magenta icon
    if (lower.contains('instagram')) {
      return Container(
        width: badgeSize,
        height: badgeSize,
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
          border: Border.all(
            color: borderColor,
            width: 1.5.r,
          ),
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
            size: badgeSize * 0.58,
            color: Colors.white,
          ),
        ),
      );
    }

    // 3. Facebook / Messenger: Messenger blue icon
    if (lower.contains('facebook') || lower.contains('messenger')) {
      return Container(
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF00C6FF), Color(0xFF0078FF)],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
            width: 1.5.r,
          ),
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
              child: Icon(Icons.bolt_rounded, size: badgeSize * 0.65, color: Colors.white),
            ),
          ),
        ),
      );
    }

    // 4. Telegram: Paper plane icon
    if (lower.contains('telegram')) {
      return Container(
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          color: const Color(0xFF229ED9),
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
            width: 1.5.r,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF229ED9).withValues(alpha: 0.35),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Icon(Icons.send_rounded, size: badgeSize * 0.55, color: Colors.white),
        ),
      );
    }

    // 5. Email: Amber/Red envelope icon
    if (lower.contains('email')) {
      return Container(
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEA4335), Color(0xFFF59E0B)],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
            width: 1.5.r,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEA4335).withValues(alpha: 0.35),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Icon(Icons.mail_rounded, size: badgeSize * 0.58, color: Colors.white),
        ),
      );
    }

    // 6. SMS: Emerald SMS icon
    if (lower.contains('sms')) {
      return Container(
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
            width: 1.5.r,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Icon(Icons.sms_rounded, size: badgeSize * 0.55, color: Colors.white),
        ),
      );
    }

    // 7. API / Webhook: Slate/Indigo code icon
    if (lower.contains('api') || lower.contains('webhook')) {
      return Container(
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1),
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
            width: 1.5.r,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.35),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Icon(Icons.code_rounded, size: badgeSize * 0.58, color: Colors.white),
        ),
      );
    }

    // 8. Website / LiveChat / WebWidget: Livechat / Web globe icon
    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 1.5.r,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Icon(Icons.language_rounded, size: badgeSize * 0.58, color: Colors.white),
      ),
    );
  }
}
