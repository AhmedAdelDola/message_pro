import 'package:flutter/material.dart';
import 'package:message_pro/ui/widgets/channel_logo_widget.dart';

class ChannelSmallIcon extends StatelessWidget {
  final String channelType;

  const ChannelSmallIcon({super.key, required this.channelType});

  @override
  Widget build(BuildContext context) {
    return ChannelLogoWidget(
      channelType: channelType,
      size: 13,
    );
  }
}
