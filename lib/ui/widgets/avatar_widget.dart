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
        if (channel != null)
          Positioned(
            right: -2.w,
            bottom: -2.h,
            child: RepaintBoundary(
              child: Container(
                padding: EdgeInsets.all(2.5.r),
                decoration: BoxDecoration(
                  color: _getChannelColor(channel!),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5.r,
                  ),
                ),
                child: Icon(
                  _getChannelIcon(channel!),
                  size: responsiveSize * 0.28,
                  color: Colors.white,
                ),
              ),
            ),
          )
        else if (showStatus)
          Positioned(
            right: 0,
            bottom: 0,
            child: RepaintBoundary(
              child: Container(
                width: responsiveSize * 0.28,
                height: responsiveSize * 0.28,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.success : Colors.grey,
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
