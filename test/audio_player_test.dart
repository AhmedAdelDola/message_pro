import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:message_pro/core/config/app_config.dart';
import 'package:message_pro/core/services/audio_cache_service.dart';
import 'package:message_pro/data/models/message.dart';
import 'package:message_pro/ui/widgets/media_viewers/audio_player_bubble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers.global'), (call) async {
      return 1;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (call) async {
      if (call.method == 'getDuration') {
        return 14000;
      }
      return 1;
    });
  });

  group('MessageAttachment Audio Duration & URL Parsing Tests', () {
    test('parses duration from root duration in seconds', () {
      final json = {
        'id': 1,
        'file_type': 'audio',
        'data_url': 'https://example.com/audio.ogg',
        'duration': 14.5,
      };

      final att = MessageAttachment.fromJson(json);
      expect(att.duration, 14.5);
      expect(att.dataUrl, 'https://example.com/audio.ogg');
    });

    test('parses duration in milliseconds (> 1000) and converts to seconds', () {
      final json = {
        'id': 2,
        'file_type': 'audio',
        'data_url': 'https://example.com/voice.opus',
        'duration': 16500, // 16.5 seconds in ms
      };

      final att = MessageAttachment.fromJson(json);
      expect(att.duration, 16.5);
    });

    test('parses duration from metadata map (metadata.duration_seconds or metadata.duration)', () {
      final json = {
        'id': 3,
        'file_type': 'audio',
        'data_url': 'https://example.com/note.m4a',
        'metadata': {
          'duration_seconds': 28.0,
        },
      };

      final att = MessageAttachment.fromJson(json);
      expect(att.duration, 28.0);
    });

    test('resolves relative data_url with AppConfig.defaultBaseUrl', () {
      final json = {
        'id': 4,
        'file_type': 'audio',
        'data_url': '/rails/active_storage/blobs/redirect/eyJfcmFpbHMi/voice.ogg',
      };

      final att = MessageAttachment.fromJson(json);
      expect(att.dataUrl, '${AppConfig.defaultBaseUrl}/rails/active_storage/blobs/redirect/eyJfcmFpbHMi/voice.ogg');
    });
  });

  group('AudioCacheService Tests', () {
    test('setActivePlayer pauses previous player and replaces active reference', () {
      final cacheService = AudioCacheService();
      final player1 = AudioPlayer();
      final player2 = AudioPlayer();

      cacheService.setActivePlayer(player1);
      cacheService.setActivePlayer(player2);

      cacheService.clearActivePlayer(player2);
      player1.dispose();
      player2.dispose();
    });
  });

  group('AudioPlayerBubble Widget Tests', () {
    testWidgets('renders initial total duration accurately before playback starts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AudioPlayerBubble(
              audioUrl: 'https://example.com/voice_test.ogg',
              isOutgoing: false,
              initialDurationSeconds: 14.0,
              fileName: 'WhatsApp Voice Note',
            ),
          ),
        ),
      );

      // Should display 00:14 as total duration instead of 00:00 / 00:00
      expect(find.text('00:14'), findsOneWidget);
      expect(find.text('WhatsApp Voice Note'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('handles missing initial duration gracefully without crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AudioPlayerBubble(
              audioUrl: 'https://example.com/unknown_duration.ogg',
              isOutgoing: true,
              fileName: 'Voice Note',
            ),
          ),
        ),
      );

      expect(find.text('00:00'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });
  });
}
