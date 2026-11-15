import 'dart:async';
import 'package:dio/dio.dart';
import '../../data/models/link_preview_metadata.dart';

class LinkPreviewService {
  static final LinkPreviewService _instance = LinkPreviewService._internal();
  factory LinkPreviewService() => _instance;
  LinkPreviewService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 3500),
      receiveTimeout: const Duration(milliseconds: 4000),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      },
      followRedirects: true,
      maxRedirects: 3,
      responseType: ResponseType.plain,
    ),
  );

  static final RegExp urlRegExp = RegExp(
    r'(https?:\/\/[^\s<>"{}|\\^`]+|www\.[^\s<>"{}|\\^`]+)',
    caseSensitive: false,
  );

  final Map<String, LinkPreviewMetadata?> _cache = {};
  final Map<String, Future<LinkPreviewMetadata?>> _inFlight = {};

  /// Extract the first valid URL from a message text
  static String? extractFirstUrl(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final match = urlRegExp.firstMatch(text);
    if (match == null) return null;

    var rawUrl = match.group(0)!;
    // Strip trailing punctuation often typed at the end of a sentence
    rawUrl = rawUrl.replaceAll(RegExp(r'[\.,\?!:;\)\]]+$'), '');
    if (rawUrl.isEmpty) return null;

    return rawUrl;
  }

  /// Extract all URLs found in the text
  static List<String> extractAllUrls(String? text) {
    if (text == null || text.trim().isEmpty) return const [];
    final matches = urlRegExp.allMatches(text);
    final results = <String>[];
    for (final m in matches) {
      var raw = m.group(0)!;
      raw = raw.replaceAll(RegExp(r'[\.,\?!:;\)\]]+$'), '');
      if (raw.isNotEmpty && !results.contains(raw)) {
        results.add(raw);
      }
    }
    return results;
  }

  /// Get cached metadata immediately if available
  LinkPreviewMetadata? getCached(String url) {
    final cleanUrl = _normalizeUrl(url);
    return _cache[cleanUrl];
  }

  /// Fetch OpenGraph and HTML metadata for a URL with caching
  Future<LinkPreviewMetadata?> fetchMetadata(String url) async {
    final cleanUrl = _normalizeUrl(url);
    if (_cache.containsKey(cleanUrl)) {
      return _cache[cleanUrl];
    }

    if (_inFlight.containsKey(cleanUrl)) {
      return await _inFlight[cleanUrl];
    }

    final future = _doFetch(cleanUrl);
    _inFlight[cleanUrl] = future;

    try {
      final result = await future;
      _cache[cleanUrl] = result;
      return result;
    } finally {
      _inFlight.remove(cleanUrl);
    }
  }

  Future<LinkPreviewMetadata?> _doFetch(String normalizedUrl) async {
    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return null;
    }

    String domain = uri.host.replaceFirst(RegExp(r'^www\.'), '').toUpperCase();

    try {
      final response = await _dio.get(normalizedUrl);
      final rawHtml = response.data?.toString() ?? '';
      if (rawHtml.isEmpty) return null;

      // Restrict analysis to head or first 80KB to keep parsing lightweight
      final html = rawHtml.length > 80000 ? rawHtml.substring(0, 80000) : rawHtml;

      String? title = _extractMetaTag(html, 'og:title') ??
          _extractMetaTag(html, 'twitter:title') ??
          _extractTitleTag(html);

      String? description = _extractMetaTag(html, 'og:description') ??
          _extractMetaTag(html, 'twitter:description') ??
          _extractMetaTag(html, 'description', attr: 'name');

      String? imageUrl = _extractMetaTag(html, 'og:image') ??
          _extractMetaTag(html, 'twitter:image') ??
          _extractLinkRel(html, 'image_src');

      String? siteName = _extractMetaTag(html, 'og:site_name');

      // Resolve relative image URLs
      if (imageUrl != null && imageUrl.isNotEmpty) {
        if (imageUrl.startsWith('//')) {
          imageUrl = '${uri.scheme}:$imageUrl';
        } else if (imageUrl.startsWith('/')) {
          final portStr = uri.hasPort ? ':${uri.port}' : '';
          imageUrl = '${uri.scheme}://${uri.host}$portStr$imageUrl';
        } else if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
          imageUrl = uri.resolve(imageUrl).toString();
        }
      }

      title = _cleanHtmlEntities(title);
      description = _cleanHtmlEntities(description);
      siteName = _cleanHtmlEntities(siteName);

      if ((title != null && title.isNotEmpty) ||
          (description != null && description.isNotEmpty) ||
          (imageUrl != null && imageUrl.isNotEmpty)) {
        return LinkPreviewMetadata(
          originalUrl: normalizedUrl,
          url: normalizedUrl,
          title: title,
          description: description,
          imageUrl: imageUrl,
          siteName: siteName,
          domain: domain,
        );
      }
    } catch (_) {
      // Ignore network failures gracefully
    }

    return null;
  }

  static String _normalizeUrl(String raw) {
    var u = raw.trim();
    if (u.toLowerCase().startsWith('www.')) {
      u = 'https://$u';
    }
    return u;
  }

  static String? _extractMetaTag(String html, String property, {String attr = 'property'}) {
    // Match either property="og:title" content="..." or content="..." property="og:title"
    final regex1 = RegExp(
      '<$attr=["\']$property["\'][^>]*?content=["\']([^"\']*)["\']',
      caseSensitive: false,
    );
    final match1 = regex1.firstMatch(html);
    if (match1 != null && match1.group(1)?.trim().isNotEmpty == true) {
      return match1.group(1)!.trim();
    }

    final regex2 = RegExp(
      '<meta[^>]*?content=["\']([^"\']*)["\'][^>]*?$attr=["\']$property["\']',
      caseSensitive: false,
    );
    final match2 = regex2.firstMatch(html);
    if (match2 != null && match2.group(1)?.trim().isNotEmpty == true) {
      return match2.group(1)!.trim();
    }

    return null;
  }

  static String? _extractTitleTag(String html) {
    final titleRegex = RegExp(r'<title[^>]*>([^<]*)<\/title>', caseSensitive: false);
    final match = titleRegex.firstMatch(html);
    if (match != null && match.group(1)?.trim().isNotEmpty == true) {
      return match.group(1)!.trim();
    }
    return null;
  }

  static String? _extractLinkRel(String html, String rel) {
    final regex = RegExp(
      '<link[^>]*?rel=["\']$rel["\'][^>]*?href=["\']([^"\']*)["\']',
      caseSensitive: false,
    );
    final match = regex.firstMatch(html);
    if (match != null && match.group(1)?.trim().isNotEmpty == true) {
      return match.group(1)!.trim();
    }
    return null;
  }

  static String? _cleanHtmlEntities(String? text) {
    if (text == null) return null;
    var t = text
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .trim();
    return t.isEmpty ? null : t;
  }
}
