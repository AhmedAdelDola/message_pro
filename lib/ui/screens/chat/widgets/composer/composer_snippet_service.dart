import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:message_pro/core/config/app_config.dart';
import 'package:message_pro/core/storage/secure_storage_service.dart';

class ComposerSnippetService {
  final SecureStorageService _storage;
  final Dio _dio;

  ComposerSnippetService({
    SecureStorageService? storage,
    Dio? dio,
  })  : _storage = storage ?? SecureStorageService(),
        _dio = dio ?? Dio();

  Future<List<String>> downloadSnippetFiles({
    required List<String> fileUrls,
    required int currentAttachedCount,
    required int maxLimit,
  }) async {
    final downloadedPaths = <String>[];
    if (fileUrls.isEmpty) return downloadedPaths;

    try {
      final tempDir = await getTemporaryDirectory();
      final base = await _storage.getBaseUrl();
      final uri = Uri.tryParse(base.isNotEmpty ? base : AppConfig.defaultBaseUrl);
      final domainRoot = uri != null
          ? '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}'
          : AppConfig.defaultBaseUrl;

      final authHeaders = await _storage.getAuthHeaders();
      final headers = <String, String>{};
      if (authHeaders != null) {
        if (authHeaders['access-token'] != null) headers['access-token'] = authHeaders['access-token']!;
        if (authHeaders['client'] != null) headers['client'] = authHeaders['client']!;
        if (authHeaders['uid'] != null) headers['uid'] = authHeaders['uid']!;
      }

      _dio.options = BaseOptions(
        connectTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 35),
        headers: headers,
        followRedirects: true,
        validateStatus: (status) => status != null && status < 400,
      );

      for (int i = 0; i < fileUrls.length; i++) {
        if (currentAttachedCount + downloadedPaths.length >= maxLimit) {
          break;
        }
        var url = fileUrls[i].trim();
        if (url.isEmpty) continue;
        if (url.startsWith('/')) {
          url = '$domainRoot$url';
        }

        try {
          final cleanUrl = url.split('?').first;
          final lastSegment = cleanUrl.split('/').last;
          String ext = lastSegment.contains('.')
              ? lastSegment.split('.').last.toLowerCase()
              : '';
          if (ext.length > 5 || ext.isEmpty) {
            ext = 'png';
          }

          final fileName = 'snippet_${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
          final file = File('${tempDir.path}/$fileName');

          final response = await _dio.get<List<int>>(
            url,
            options: Options(responseType: ResponseType.bytes),
          );

          if (response.data != null && response.data!.isNotEmpty) {
            await file.writeAsBytes(response.data!);
            downloadedPaths.add(file.path);
          }
        } catch (e) {
          debugPrint('Error downloading snippet file ($url): $e');
        }
      }
    } catch (e) {
      debugPrint('Error in downloadSnippetFiles: $e');
    }
    return downloadedPaths;
  }
}
