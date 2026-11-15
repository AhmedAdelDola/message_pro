import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/audio_cache_service.dart';

class AudioPlayerBubble extends StatefulWidget {
  final String audioUrl;
  final bool isOutgoing;
  final String? fileName;
  final double? initialDurationSeconds;
  final String? transcribedText;

  const AudioPlayerBubble({
    super.key,
    required this.audioUrl,
    required this.isOutgoing,
    this.fileName,
    this.initialDurationSeconds,
    this.transcribedText,
  });

  @override
  State<AudioPlayerBubble> createState() => _AudioPlayerBubbleState();
}

class _AudioPlayerBubbleState extends State<AudioPlayerBubble> {
  late final AudioPlayer _player;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  bool _isSeeking = false;
  double _playbackSpeed = 1.0;

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;

  String get _cleanAudioUrl {
    var u = widget.audioUrl.trim();
    if (u.isNotEmpty && u.startsWith('/')) {
      u = '${AppConfig.defaultBaseUrl}$u';
    }
    return u;
  }

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    if (widget.initialDurationSeconds != null && widget.initialDurationSeconds! > 0) {
      _duration = Duration(milliseconds: (widget.initialDurationSeconds! * 1000).round());
    }

    _initAudio();
  }

  Future<Source> _resolveSource() async {
    final url = _cleanAudioUrl;
    final cached = await AudioCacheService().cacheAudioFile(url);
    if (cached != null && File(cached).existsSync()) {
      return DeviceFileSource(cached);
    }
    if (url.startsWith('file://')) {
      return DeviceFileSource(url.replaceFirst('file://', ''));
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (File(url).existsSync()) {
        return DeviceFileSource(url);
      }
    }
    return UrlSource(url);
  }

  void _initAudio() async {
    _initAudioListeners();

    final url = _cleanAudioUrl;
    if (url.isEmpty) return;

    // Check disk cache first to get duration immediately if already cached
    final cachedPath = await AudioCacheService().getCachedFilePath(url);
    if (cachedPath != null && mounted) {
      try {
        await _player.setSource(DeviceFileSource(cachedPath));
        final dur = await _player.getDuration();
        if (dur != null && dur > Duration.zero && mounted) {
          setState(() => _duration = dur);
        }
      } catch (_) {}
    } else {
      // Background preload for instantaneous play & duration resolution
      AudioCacheService().cacheAudioFile(url).then((path) async {
        if (path != null && mounted && _playerState == PlayerState.stopped) {
          try {
            await _player.setSource(DeviceFileSource(path));
            final dur = await _player.getDuration();
            if (dur != null && dur > Duration.zero && mounted) {
              setState(() => _duration = dur);
            }
          } catch (_) {}
        }
      });
    }
  }

  void _initAudioListeners() {
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
          if (state == PlayerState.playing || state == PlayerState.paused || state == PlayerState.completed) {
            _isLoading = false;
          }
        });
      }
    });

    _durationSub = _player.onDurationChanged.listen((dur) {
      if (mounted && dur > Duration.zero) {
        setState(() {
          _duration = dur;
          _isLoading = false;
        });
      }
    });

    _positionSub = _player.onPositionChanged.listen((pos) {
      if (mounted && !_isSeeking) {
        setState(() {
          _position = pos;
          if (pos > _duration) {
            _duration = pos;
          }
          if (_isLoading) _isLoading = false;
        });
      }
    });

    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _playerState = PlayerState.completed;
          _isLoading = false;
        });
        AudioCacheService().clearActivePlayer(_player);
      }
    });
  }

  @override
  void dispose() {
    AudioCacheService().clearActivePlayer(_player);
    _stateSub?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
      AudioCacheService().clearActivePlayer(_player);
      if (mounted) {
        setState(() {
          _playerState = PlayerState.paused;
          _isLoading = false;
        });
      }
    } else {
      AudioCacheService().setActivePlayer(_player);
      if (mounted) setState(() => _isLoading = true);
      try {
        if (_playerState == PlayerState.completed || (_duration > Duration.zero && _position >= _duration)) {
          await _player.seek(Duration.zero);
          _position = Duration.zero;
          await _player.resume();
        } else if (_playerState == PlayerState.paused) {
          await _player.resume();
        } else {
          final source = await _resolveSource();
          await _player.play(source);
        }
        await _player.setPlaybackRate(_playbackSpeed);

        // Probe duration after starting
        final dur = await _player.getDuration();
        if (dur != null && dur > Duration.zero && mounted) {
          setState(() => _duration = dur);
        }
      } catch (e) {
        try {
          await _player.stop();
          final source = await _resolveSource();
          await _player.play(source);
        } catch (_) {}
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _toggleSpeed() async {
    double nextSpeed = 1.0;
    if (_playbackSpeed == 1.0) {
      nextSpeed = 1.5;
    } else if (_playbackSpeed == 1.5) {
      nextSpeed = 2.0;
    } else {
      nextSpeed = 1.0;
    }

    setState(() => _playbackSpeed = nextSpeed);
    try {
      await _player.setPlaybackRate(nextSpeed);
    } catch (_) {}
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isOutgoing = widget.isOutgoing;
    final secondaryColor = isOutgoing ? Colors.white70 : Colors.black54;
    final sliderActiveColor = isOutgoing ? Colors.white : const Color(0xFF4162E3);
    final sliderInactiveColor = isOutgoing ? Colors.white30 : Colors.black12;

    // Use millisecond precision for silky-smooth progress tracking
    final totalMs = _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0;
    final currentMs = _position.inMilliseconds.toDouble().clamp(0.0, totalMs);

    String durationLabel;
    if (_playerState != PlayerState.playing &&
        _playerState != PlayerState.paused &&
        _position == Duration.zero) {
      durationLabel = _duration > Duration.zero ? _formatDuration(_duration) : '00:00';
    } else {
      durationLabel =
          '${_formatDuration(_position)} / ${_duration > Duration.zero ? _formatDuration(_duration) : "--:--"}';
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 230, maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isOutgoing ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOutgoing ? Colors.white24 : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Play / Pause button
              InkWell(
                onTap: _togglePlayPause,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isOutgoing ? Colors.white.withValues(alpha: 0.25) : const Color(0xFF4162E3),
                    shape: BoxShape.circle,
                  ),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _playerState == PlayerState.playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),
              const SizedBox(width: 8),

              // Audio progress slider (Smooth milliseconds)
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 3,
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: sliderActiveColor,
                    inactiveTrackColor: sliderInactiveColor,
                    thumbColor: sliderActiveColor,
                  ),
                  child: Slider(
                    value: currentMs,
                    min: 0.0,
                    max: totalMs,
                    onChangeStart: (_) {
                      _isSeeking = true;
                    },
                    onChanged: (val) {
                      setState(() {
                        _position = Duration(milliseconds: val.round());
                      });
                    },
                    onChangeEnd: (val) async {
                      _isSeeking = false;
                      try {
                        await _player.seek(Duration(milliseconds: val.round()));
                      } catch (_) {}
                    },
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Speed button (1x / 1.5x / 2x)
              InkWell(
                onTap: _toggleSpeed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOutgoing ? Colors.white24 : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_playbackSpeed == 1.0 ? "1" : _playbackSpeed == 1.5 ? "1.5" : "2"}x',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isOutgoing ? Colors.white : const Color(0xFF334155),
                      fontFamily: 'Gontserrat',
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Duration display & Voice Note label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.mic_rounded,
                        size: 13,
                        color: secondaryColor,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          widget.fileName ?? 'Voice Note',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: secondaryColor,
                            fontFamily: 'Gontserrat',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  durationLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: secondaryColor,
                    fontFamily: 'Gontserrat',
                  ),
                ),
              ],
            ),
          ),

          // AI Transcript if present (matching web interface)
          if (widget.transcribedText != null && widget.transcribedText!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isOutgoing ? Colors.black12 : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isOutgoing ? Colors.white12 : const Color(0xFFE2E8F0),
                  width: 0.6,
                ),
              ),
              child: Text(
                widget.transcribedText!,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isOutgoing ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E293B),
                  fontFamily: 'Gontserrat',
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
