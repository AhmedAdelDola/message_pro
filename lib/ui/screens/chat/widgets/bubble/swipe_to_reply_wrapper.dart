import 'package:flutter/material.dart';
import '../../../../../core/services/haptic_service.dart';

class SwipeToReplyWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onReply;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final bool isOutgoing;

  const SwipeToReplyWrapper({
    super.key,
    required this.child,
    this.onReply,
    this.onDoubleTap,
    this.onLongPress,
    required this.isOutgoing,
  });

  @override
  State<SwipeToReplyWrapper> createState() => _SwipeToReplyWrapperState();
}

class _SwipeToReplyWrapperState extends State<SwipeToReplyWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  double _dragOffset = 0.0;
  bool _hasTriggeredHaptic = false;
  static const double _replyThreshold = 38.0;
  static const double _maxDrag = 65.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    )..addListener(() {
        setState(() {
          _dragOffset = _animation.value;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.onReply == null) return;

    final delta = details.primaryDelta ?? 0;
    final newOffset = _dragOffset + delta;

    if (newOffset.abs() <= _maxDrag) {
      setState(() => _dragOffset = newOffset);
    }

    if (_dragOffset.abs() >= _replyThreshold && !_hasTriggeredHaptic) {
      _hasTriggeredHaptic = true;
      HapticService.lightImpact();
    } else if (_dragOffset.abs() < _replyThreshold) {
      _hasTriggeredHaptic = false;
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.onReply == null) return;

    if (_dragOffset.abs() >= _replyThreshold) {
      widget.onReply!();
    }

    _animation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward(from: 0);
    _hasTriggeredHaptic = false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onReply == null && widget.onDoubleTap == null && widget.onLongPress == null) {
      return widget.child;
    }

    final showIcon = _dragOffset.abs() > 8;
    final progress = (_dragOffset.abs() / _replyThreshold).clamp(0.0, 1.0);
    final isDraggingRight = _dragOffset > 0;

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onDoubleTap: () {
        HapticService.lightImpact();
        (widget.onDoubleTap ?? widget.onReply)?.call();
      },
      onLongPress: () {
        HapticService.mediumImpact();
        widget.onLongPress?.call();
      },
      behavior: HitTestBehavior.translucent,
      child: Stack(
        alignment: isDraggingRight ? Alignment.centerLeft : Alignment.centerRight,
        children: [
          if (showIcon)
            Positioned(
              left: isDraggingRight ? 12 : null,
              right: !isDraggingRight ? 12 : null,
              child: Opacity(
                opacity: progress,
                child: Transform.scale(
                  scale: 0.6 + (0.4 * progress),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4162E3).withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.reply_rounded,
                      size: 20,
                      color: Color(0xFF4162E3),
                    ),
                  ),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
