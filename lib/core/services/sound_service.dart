import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatSoundOption {
  final String id;
  final String nameEn;
  final String nameAr;
  final String assetPath;
  final IconData icon;

  const ChatSoundOption({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.assetPath,
    required this.icon,
  });
}

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _soundEnabled = true;
  String _selectedSound = 'whatsapp';

  bool get isSoundEnabled => _soundEnabled;
  String get selectedSound => _selectedSound;

  static const List<ChatSoundOption> availableSounds = [
    ChatSoundOption(
      id: 'whatsapp',
      nameEn: 'WhatsApp Classic',
      nameAr: 'واتساب كلاسيك (الافتراضي)',
      assetPath: 'sounds/message_received.wav',
      icon: Icons.chat_bubble_outline_rounded,
    ),
    ChatSoundOption(
      id: 'note',
      nameEn: 'iPhone Note',
      nameAr: 'نغمة الآيفون (Note)',
      assetPath: 'sounds/note.wav',
      icon: Icons.phone_iphone_rounded,
    ),
    ChatSoundOption(
      id: 'pop',
      nameEn: 'Soft Pop',
      nameAr: 'بوب ناعم (Pop)',
      assetPath: 'sounds/pop.wav',
      icon: Icons.bubble_chart_rounded,
    ),
    ChatSoundOption(
      id: 'crystal',
      nameEn: 'Crystal Chime',
      nameAr: 'رنين كريستال (Crystal)',
      assetPath: 'sounds/crystal.wav',
      icon: Icons.auto_awesome_rounded,
    ),
    ChatSoundOption(
      id: 'bell',
      nameEn: 'Modern Bell',
      nameAr: 'جرس عصري (Bell)',
      assetPath: 'sounds/bell.wav',
      icon: Icons.notifications_active_outlined,
    ),
    ChatSoundOption(
      id: 'droplet',
      nameEn: 'Water Droplet',
      nameAr: 'قطرة ماء (Droplet)',
      assetPath: 'sounds/droplet.wav',
      icon: Icons.water_drop_outlined,
    ),
  ];

  ChatSoundOption get currentSoundOption {
    return availableSounds.firstWhere(
      (s) => s.id == _selectedSound,
      orElse: () => availableSounds.first,
    );
  }

  /// Initialize sound settings from SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('in_app_sound_enabled') ?? true;
      _selectedSound = prefs.getString('in_app_selected_sound') ?? 'whatsapp';
    } catch (_) {
      _soundEnabled = true;
      _selectedSound = 'whatsapp';
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

  /// Change and persist selected sound
  Future<void> setSound(String soundId) async {
    _selectedSound = soundId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('in_app_selected_sound', soundId);
    } catch (e) {
      debugPrint('Error saving selected sound: $e');
    }
  }

  /// Play a preview of any sound by ID
  Future<void> playPreview(String soundId) async {
    try {
      final sound = availableSounds.firstWhere(
        (s) => s.id == soundId,
        orElse: () => availableSounds.first,
      );
      final player = AudioPlayer();
      await player.play(AssetSource(sound.assetPath), mode: PlayerMode.lowLatency);
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (e) {
      debugPrint('Error playing sound preview: $e');
    }
  }

  /// Play incoming message sound using user's chosen sound
  Future<void> playIncomingSound() async {
    if (!_soundEnabled) return;
    try {
      final sound = currentSoundOption;
      final player = AudioPlayer();
      await player.play(AssetSource(sound.assetPath), mode: PlayerMode.lowLatency);
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (e) {
      debugPrint('Error playing incoming message sound: $e');
    }
  }

  /// Play outgoing message sound
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
}
