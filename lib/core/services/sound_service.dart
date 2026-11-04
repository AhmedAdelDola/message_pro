import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  AudioPlayer? _player;
  bool _soundEnabled = true;

  bool get isSoundEnabled => _soundEnabled;

  /// Initialize sound setting from SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('in_app_sound_enabled') ?? true;
    } catch (_) {
      _soundEnabled = true;
    }
  }

  /// Toggle and persist sound preference
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('in_app_sound_enabled', enabled);
    } catch (e) {
      debugPrint('Error saving sound preference: $e');
    }
  }

  AudioPlayer get _audioPlayer {
    _player ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    return _player!;
  }

  /// Play incoming message sound (like WhatsApp incoming chime)
  Future<void> playIncomingSound() async {
    if (!_soundEnabled) return;
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('sounds/message_received.wav'), mode: PlayerMode.lowLatency);
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (e) {
      debugPrint('Error playing incoming message sound: $e');
    }
  }

  /// Play outgoing message sound (like WhatsApp sent pop)
  Future<void> playOutgoingSound() async {
    if (!_soundEnabled) return;
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('sounds/message_sent.wav'), mode: PlayerMode.lowLatency);
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (e) {
      debugPrint('Error playing outgoing message sound: $e');
    }
  }

  void dispose() {
    _player?.dispose();
    _player = null;
  }
}
