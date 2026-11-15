import 'package:equatable/equatable.dart';

class LinkPreviewMetadata extends Equatable {
  final String originalUrl;
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;
  final String domain;

  const LinkPreviewMetadata({
    required this.originalUrl,
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
    required this.domain,
  });

  bool get hasContent =>
      (title != null && title!.trim().isNotEmpty) ||
      (description != null && description!.trim().isNotEmpty) ||
      (imageUrl != null && imageUrl!.trim().isNotEmpty);

  factory LinkPreviewMetadata.fromJson(Map<String, dynamic> json, {String? originalUrl}) {
    final rawUrl = json['url'] ?? json['original_url'] ?? originalUrl ?? '';
    final urlStr = rawUrl.toString();

    String parsedDomain = '';
    try {
      final uri = Uri.tryParse(urlStr.startsWith('http') ? urlStr : 'https://$urlStr');
      if (uri != null) {
        parsedDomain = uri.host.replaceFirst(RegExp(r'^www\.'), '').toUpperCase();
      }
    } catch (_) {}

    return LinkPreviewMetadata(
      originalUrl: originalUrl ?? urlStr,
      url: urlStr,
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      imageUrl: (json['image'] ?? json['image_url'] ?? json['thumbnail_url'])?.toString(),
      siteName: json['site_name']?.toString(),
      domain: json['domain']?.toString() ?? parsedDomain,
    );
  }

  Map<String, dynamic> toJson() => {
        'original_url': originalUrl,
        'url': url,
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'site_name': siteName,
        'domain': domain,
      };

  @override
  List<Object?> get props => [originalUrl, url, title, description, imageUrl, siteName, domain];
}
