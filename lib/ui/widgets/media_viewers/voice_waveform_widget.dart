import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A sleek, interactive audio waveform widget inspired by Telegram and WhatsApp.
/// Displays vertical rounded bars that fill progressively with playback and
/// allow tapping or dragging to seek to a specific position.
class VoiceWaveformWidget extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final ValueChanged<double>? onSeek;
  final String seedKey;
  final Color activeColor;
  final Color inactiveColor;
  final double height;
  final int barCount;

  const VoiceWaveformWidget({
    super.key,
    required this.progress,
    this.onSeek,
    required this.seedKey,
    required this.activeColor,
    required this.inactiveColor,
    this.height = 36.0,
    this.barCount = 38,
  });

  @override
  State<VoiceWaveformWidget> createState() => _VoiceWaveformWidgetState();
}

class _VoiceWaveformWidgetState extends State<VoiceWaveformWidget> {
  late List<double> _barHeights;

  @override
  void initState() {
    super.initState();
    _generateBars();
  }

  @override
  void didUpdateWidget(covariant VoiceWaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seedKey != widget.seedKey || oldWidget.barCount != widget.barCount) {
      _generateBars();
    }
  }

  void _generateBars() {
    // Generate deterministic pseudo-random heights based on seedKey
    final seed = widget.seedKey.hashCode;
    final random = math.Random(seed);
    _barHeights = List.generate(widget.barCount, (i) {
      // Natural voice envelope: smoother bell curve in the middle
      final normalizedPos = i / widget.barCount;
      final envelope = math.sin(normalizedPos * math.pi) * 0.4 + 0.6;
      final raw = 0.25 + random.nextDouble() * 0.75;
      return (raw * envelope).clamp(0.2, 1.0);
    });
  }

  void _handleSeek(Offset localPosition, double totalWidth) {
    if (widget.onSeek == null || totalWidth <= 0) return;
    final target = (localPosition.dx / totalWidth).clamp(0.0, 1.0);
    widget.onSeek!(target);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) {
          final totalWidth = context.size?.width ?? 0;
          _handleSeek(details.localPosition, totalWidth);
        },
        onTapDown: (details) {
          final totalWidth = context.size?.width ?? 0;
          _handleSeek(details.localPosition, totalWidth);
        },
        child: CustomPaint(
          size: Size.infinite,
          painter: _WaveformPainter(
            progress: widget.progress.clamp(0.0, 1.0),
            bars: _barHeights,
            activeColor: widget.activeColor,
            inactiveColor: widget.inactiveColor,
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final List<double> bars;
  final Color activeColor;
  final Color inactiveColor;

  _WaveformPainter({
    required this.progress,
    required this.bars,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty || size.width <= 0 || size.height <= 0) return;

    final n = bars.length;
    // Calculate bar width and spacing
    final totalSpacingFactor = (n - 1) * 1.5;
    final barWidth = (size.width / (n + totalSpacingFactor * 0.8)).clamp(1.5, 4.0);
    final spacing = (size.width - (barWidth * n)) / (n - 1);

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;

    final centerY = size.height / 2;

    for (int i = 0; i < n; i++) {
      final x = i * (barWidth + spacing);
      final barNormalizedX = x / size.width;
      final isPlayed = barNormalizedX <= progress;

      final barH = (bars[i] * size.height).clamp(4.0, size.height);
      final top = centerY - (barH / 2);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barH),
        Radius.circular(barWidth / 2),
      );

      canvas.drawRRect(rect, isPlayed ? activePaint : inactivePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.bars != bars;
  }
}
