import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerBubble extends StatefulWidget {
  final String audioUrl;
  final bool isOutgoing;
  final String? fileName;

  const AudioPlayerBubble({
    super.key,
    required this.audioUrl,
    required this.isOutgoing,
    this.fileName,
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

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudioListeners();
  }

  void _initAudioListeners() {
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
          if (state == PlayerState.playing || state == PlayerState.paused) {
            _isLoading = false;
          }
        });
      }
    });

    _durationSub = _player.onDurationChanged.listen((dur) {
      if (mounted) {
        setState(() => _duration = dur);
      }
    });

    _positionSub = _player.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });

    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _playerState = PlayerState.completed;
        });
      }
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else {
      setState(() => _isLoading = true);
      try {
        if (_playerState == PlayerState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play(UrlSource(widget.audioUrl));
      } catch (_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
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

    final maxSeconds = _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0;
    final currentSeconds = _position.inSeconds.toDouble().clamp(0.0, maxSeconds);

    return Container(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                      ? Padding(
                          padding: const EdgeInsets.all(9),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isOutgoing ? Colors.white : Colors.white,
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

              // Audio progress slider
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
                    value: currentSeconds,
                    min: 0.0,
                    max: maxSeconds,
                    onChanged: (val) {
                      _player.seek(Duration(seconds: val.toInt()));
                    },
                  ),
                ),
              ),
            ],
          ),

          // Duration display & Voice Note label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.mic_rounded,
                      size: 13,
                      color: secondaryColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      widget.fileName ?? 'Voice Note',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: secondaryColor,
                        fontFamily: 'Gontserrat',
                      ),
                    ),
                  ],
                ),
                Text(
                  _position.inSeconds > 0
                      ? '${_formatDuration(_position)} / ${_formatDuration(_duration)}'
                      : _formatDuration(_duration),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: secondaryColor,
                    fontFamily: 'Gontserrat',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
