import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:message_pro/ui/widgets/channel_logo_widget.dart';

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
    return ChannelLogoWidget(
      channelType: channelType ?? '',
      size: size,
    );
  }
}
