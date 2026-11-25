import 'package:flutter/material.dart';
import 'package:message_pro/ui/widgets/channel_logo_widget.dart';

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
    return ChannelLogoWidget(
      channelType: channelType,
      channelName: channelName,
      size: size,
    );
  }
}
