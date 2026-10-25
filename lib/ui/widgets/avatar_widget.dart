import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';

class AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;
  final String? channel;
  final bool isOnline;
  final bool showStatus;

  const AvatarWidget({
    super.key,
    this.avatarUrl,
    required this.name,
    this.size = 44,
    this.channel,
    this.isOnline = false,
    this.showStatus = false,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
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
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnits.reduce((a, b) => a + b) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _backgroundColor,
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: avatarUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: Text(
                        _initials,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size * 0.4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Text(
                        _initials,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size * 0.4,
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
                        fontSize: size * 0.4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ),
        if (channel != null)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                color: _getChannelColor(channel!),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
              child: Icon(
                _getChannelIcon(channel!),
                size: size * 0.28,
                color: Colors.white,
              ),
            ),
          )
        else if (showStatus)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.success : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getChannelColor(String ch) {
    switch (ch.toLowerCase()) {
      case 'whatsapp':
        return AppColors.whatsapp;
      case 'facebook':
        return AppColors.facebook;
      case 'email':
        return AppColors.email;
      case 'telegram':
        return AppColors.telegram;
      default:
        return AppColors.website;
    }
  }

  IconData _getChannelIcon(String ch) {
    switch (ch.toLowerCase()) {
      case 'whatsapp':
        return Icons.phone_android;
      case 'facebook':
        return Icons.facebook;
      case 'email':
        return Icons.email;
      case 'telegram':
        return Icons.send;
      default:
        return Icons.language;
    }
  }
}
