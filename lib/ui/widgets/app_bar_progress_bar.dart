import 'package:flutter/material.dart';

/// Indeterminate blue linear progress indicator designed for AppBars across the entire application.
class AppBarProgressBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isLoading;
  final double height;
  final Color color;
  final Color? idleBorderColor;

  const AppBarProgressBar({
    super.key,
    required this.isLoading,
    this.height = 2.5,
    this.color = const Color(0xFF4162E3),
    this.idleBorderColor,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return SizedBox(
        height: height,
        child: idleBorderColor != null
            ? Container(color: idleBorderColor)
            : null,
      );
    }
    return SizedBox(
      height: height,
      child: LinearProgressIndicator(
        minHeight: height,
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

/// Standalone header linear progress bar for screens using custom headers inside body.
class LinearHeaderLoader extends StatelessWidget {
  final bool isLoading;
  final double height;
  final Color color;

  const LinearHeaderLoader({
    super.key,
    required this.isLoading,
    this.height = 3.5,
    this.color = const Color(0xFF4162E3),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: isLoading ? height : 0,
      child: isLoading
          ? LinearProgressIndicator(
              minHeight: height,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            )
          : const SizedBox.shrink(),
    );
  }
}
