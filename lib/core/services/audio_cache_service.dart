import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class AudioCacheService {
  static final AudioCacheService _instance = AudioCacheService._internal();
  factory AudioCacheService() => _instance;
  AudioCacheService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  final Map<String, Future<String?>> _inFlight = {};
  AudioPlayer? _activePlayer;

  /// Register active player and automatically pause previous player
  void setActivePlayer(AudioPlayer player) {
    if (_activePlayer != null && _activePlayer != player) {
      try {
        _activePlayer!.pause();
      } catch (_) {}
    }
    _activePlayer = player;
  }

  void clearActivePlayer(AudioPlayer player) {
    if (_activePlayer == player) {
      _activePlayer = null;
    }
  }

  /// Get local cached file path if file already exists on disk
  Future<String?> getCachedFilePath(String rawUrl) async {
    final clean = rawUrl.trim();
    if (clean.isEmpty) return null;

    if (clean.startsWith('file://')) {
      final p = clean.replaceFirst('file://', '');
      if (File(p).existsSync()) return p;
    }

    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      if (File(clean).existsSync()) return clean;
      return null;
    }

    try {
      final cacheDir = await _getCacheDir();
      final targetFile = File('${cacheDir.path}/${_generateCacheFileName(clean)}');
      if (await targetFile.exists() && (await targetFile.length()) > 0) {
        return targetFile.path;
      }
    } catch (_) {}

    return null;
  }

  /// Cache remote audio file to local disk for accurate duration & instant seeking
  Future<String?> cacheAudioFile(String rawUrl) async {
    final clean = rawUrl.trim();
    if (clean.isEmpty) return null;

    // Local file handling
    if (clean.startsWith('file://')) {
      final p = clean.replaceFirst('file://', '');
      if (await File(p).exists()) return p;
    }
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      if (await File(clean).exists()) return clean;
      return null;
    }

    // Check disk cache
    final existing = await getCachedFilePath(clean);
    if (existing != null) return existing;

    // Check in-flight download
    if (_inFlight.containsKey(clean)) {
      return await _inFlight[clean];
    }

    final future = _downloadAudio(clean);
    _inFlight[clean] = future;

    try {
      final path = await future;
      return path;
    } finally {
      _inFlight.remove(clean);
    }
  }

  Future<String?> _downloadAudio(String url) async {
    try {
      final cacheDir = await _getCacheDir();
      final targetFile = File('${cacheDir.path}/${_generateCacheFileName(url)}');
      final tempFile = File('${targetFile.path}.tmp');

      if (await targetFile.exists() && (await targetFile.length()) > 0) {
        return targetFile.path;
      }

      await _dio.download(
        url,
        tempFile.path,
        deleteOnError: true,
      );

      if (await tempFile.exists() && (await tempFile.length()) > 0) {
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
        await tempFile.rename(targetFile.path);
        return targetFile.path;
      }
    } catch (_) {}

    return null;
  }

  Future<Directory> _getCacheDir() async {
    final temp = await getTemporaryDirectory();
    final dir = Directory('${temp.path}/audio_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _generateCacheFileName(String url) {
    final bytes = utf8.encode(url);
    final base64Hash = base64Url.encode(bytes).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final shortHash = base64Hash.length > 32 ? base64Hash.substring(0, 32) : base64Hash;
    String ext = '.ogg';
    final lower = url.toLowerCase();
    if (lower.contains('.mp3')) {
      ext = '.mp3';
    } else if (lower.contains('.m4a')) {
      ext = '.m4a';
    } else if (lower.contains('.wav')) {
      ext = '.wav';
    } else if (lower.contains('.aac')) {
      ext = '.aac';
    } else if (lower.contains('.opus')) {
      ext = '.opus';
    }
    return '${url.hashCode.abs()}_$shortHash$ext';
  }
}
