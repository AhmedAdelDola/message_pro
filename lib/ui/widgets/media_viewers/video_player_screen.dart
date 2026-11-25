import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String? title;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    this.title,
  });

  static Future<void> open(
    BuildContext context, {
    required String videoUrl,
    String? title,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          videoUrl: videoUrl,
          title: title,
        ),
      ),
    );
  }

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitializing = true;
  bool _hasError = false;
  String? _errorText;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    setState(() {
      _isInitializing = true;
      _hasError = false;
      _errorText = null;
    });

    final uri = Uri.tryParse(widget.videoUrl);
    if (uri == null) {
      setState(() {
        _isInitializing = false;
        _hasError = true;
        _errorText = 'رابط الفيديو غير صالح';
      });
      return;
    }

    try {
      await _controller?.dispose();
      final controller = VideoPlayerController.networkUrl(uri);
      _controller = controller;
      controller.addListener(_onPlayerTick);
      await controller.initialize();
      await controller.play();
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
          _errorText = e.toString();
        });
      }
    }
  }

  void _onPlayerTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onPlayerTick);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.videoUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final controller = _controller;
    final isInitialized = controller != null && controller.value.isInitialized;
    final isPlaying = isInitialized && controller.value.isPlaying;
    final position = isInitialized ? controller.value.position : Duration.zero;
    final duration = isInitialized ? controller.value.duration : Duration.zero;
    final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
    final posMs = position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title ?? (isArabic ? 'تشغيل الفيديو' : 'Video'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (isInitialized)
            IconButton(
              icon: Icon(_isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded),
              onPressed: () {
                setState(() => _isMuted = !_isMuted);
                controller.setVolume(_isMuted ? 0.0 : 1.0);
              },
            ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: isArabic ? 'فتح في تطبيق خارجي' : 'Open externally',
            onPressed: _openExternally,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _isInitializing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : _hasError
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.white70,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  isArabic
                                      ? 'تعذر تشغيل الفيديو داخل التطبيق'
                                      : 'Unable to play video in app',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_errorText != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    _errorText!,
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 10,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _initPlayer,
                                      icon: const Icon(Icons.refresh_rounded, size: 18),
                                      label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: _openExternally,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: Colors.white38),
                                      ),
                                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                                      label: Text(isArabic ? 'فتح خارجياً' : 'Open externally'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : (controller == null || !isInitialized)
                            ? const SizedBox.shrink()
                            : GestureDetector(
                            onTap: () {
                              if (isPlaying) {
                                controller.pause();
                              } else {
                                controller.play();
                              }
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AspectRatio(
                                  aspectRatio: controller.value.aspectRatio > 0
                                      ? controller.value.aspectRatio
                                      : 16 / 9,
                                  child: VideoPlayer(controller),
                                ),
                                if (!isPlaying)
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 38,
                                    ),
                                  ),
                              ],
                            ),
                          ),
              ),
            ),
            if (isInitialized)
              Container(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
                color: Colors.black87,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        if (isPlaying) {
                          controller.pause();
                        } else {
                          controller.play();
                        }
                      },
                    ),
                    Text(
                      _formatDuration(position),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Expanded(
                      child: Slider(
                        value: posMs,
                        min: 0,
                        max: maxMs,
                        activeColor: const Color(0xFF4162E3),
                        inactiveColor: Colors.white24,
                        onChanged: (val) {
                          controller.seekTo(Duration(milliseconds: val.toInt()));
                        },
                      ),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
