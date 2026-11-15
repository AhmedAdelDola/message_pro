import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_pro/core/services/link_preview_service.dart';
import 'package:message_pro/data/models/link_preview_metadata.dart';
import 'package:message_pro/ui/screens/chat/widgets/clickable_text_with_links.dart';
import 'package:message_pro/ui/screens/chat/widgets/link_preview_card.dart';

void main() {
  group('LinkPreviewService URL Extraction Tests', () {
    test('extracts first HTTP/HTTPS URL accurately', () {
      expect(
        LinkPreviewService.extractFirstUrl('مرحباً بك في موقعنا https://example.com/page لمزيد من المعلومات'),
        'https://example.com/page',
      );
    });

    test('extracts www. URL properly', () {
      expect(
        LinkPreviewService.extractFirstUrl('يرجى زيارة www.flutter.dev شكراً'),
        'www.flutter.dev',
      );
    });

    test('strips trailing punctuation like commas, periods and brackets', () {
      expect(
        LinkPreviewService.extractFirstUrl('تفضل بالدخول هنا (https://google.com).'),
        'https://google.com',
      );
      expect(
        LinkPreviewService.extractFirstUrl('الرابط هو https://pub.dev/packages,'),
        'https://pub.dev/packages',
      );
    });

    test('returns null for text with no URLs', () {
      expect(LinkPreviewService.extractFirstUrl('رسالة نصية عادية بدون أي روابط'), isNull);
      expect(LinkPreviewService.extractFirstUrl(''), isNull);
      expect(LinkPreviewService.extractFirstUrl(null), isNull);
    });

    test('extractAllUrls returns all valid URLs without duplicates', () {
      const text = 'زوروا https://site1.com وأيضاً https://site2.com وأخيراً www.site3.com';
      final urls = LinkPreviewService.extractAllUrls(text);
      expect(urls.length, 3);
      expect(urls[0], 'https://site1.com');
      expect(urls[1], 'https://site2.com');
      expect(urls[2], 'www.site3.com');
    });
  });

  group('LinkPreviewMetadata Model Tests', () {
    test('parses JSON with OpenGraph data correctly', () {
      final json = {
        'url': 'https://youtube.com/watch?v=123',
        'title': 'Flutter 3.29 Walkthrough Video',
        'description': 'A deep dive into Flutter widgets and multi-platform performance.',
        'image': 'https://img.youtube.com/vi/123/hqdefault.jpg',
        'domain': 'YOUTUBE.COM',
        'site_name': 'YouTube',
      };

      final meta = LinkPreviewMetadata.fromJson(json);

      expect(meta.url, 'https://youtube.com/watch?v=123');
      expect(meta.title, 'Flutter 3.29 Walkthrough Video');
      expect(meta.description, 'A deep dive into Flutter widgets and multi-platform performance.');
      expect(meta.imageUrl, 'https://img.youtube.com/vi/123/hqdefault.jpg');
      expect(meta.domain, 'YOUTUBE.COM');
      expect(meta.hasContent, isTrue);
    });

    test('hasContent returns false when all metadata fields are empty', () {
      const meta = LinkPreviewMetadata(
        originalUrl: 'https://empty.com',
        url: 'https://empty.com',
        domain: 'EMPTY.COM',
      );

      expect(meta.hasContent, isFalse);
    });
  });

  group('ClickableTextWithLinks & LinkPreviewCard Widget Tests', () {
    testWidgets('ClickableTextWithLinks renders plain text when no link is present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClickableTextWithLinks(
              text: 'رسالة نصية عادية *مع خط عريض*',
              textStyle: TextStyle(color: Colors.black),
            ),
          ),
        ),
      );

      expect(find.text('رسالة نصية عادية مع خط عريض', findRichText: true), findsOneWidget);
    });

    testWidgets('ClickableTextWithLinks detects URL and renders rich text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClickableTextWithLinks(
              text: 'زيارة الرابط https://flutter.dev هنا',
              textStyle: TextStyle(color: Colors.black),
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
      expect(find.text('زيارة الرابط https://flutter.dev هنا', findRichText: true), findsOneWidget);
    });

    testWidgets('LinkPreviewCard renders preview with title and domain', (tester) async {
      const sampleMeta = LinkPreviewMetadata(
        originalUrl: 'https://pub.dev',
        url: 'https://pub.dev',
        title: 'The official package repository for Dart and Flutter',
        description: 'Find packages to help you build Flutter apps.',
        domain: 'PUB.DEV',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LinkPreviewCard(
              url: 'https://pub.dev',
              isOutgoing: false,
              isDark: false,
              initialMetadata: sampleMeta,
            ),
          ),
        ),
      );

      expect(find.text('PUB.DEV'), findsOneWidget);
      expect(find.text('The official package repository for Dart and Flutter'), findsOneWidget);
      expect(find.text('Find packages to help you build Flutter apps.'), findsOneWidget);
    });

    testWidgets('LinkPreviewCard renders SizedBox.shrink when metadata has no content', (tester) async {
      const emptyMeta = LinkPreviewMetadata(
        originalUrl: 'https://empty.com',
        url: 'https://empty.com',
        domain: 'EMPTY.COM',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LinkPreviewCard(
              url: 'https://empty.com',
              isOutgoing: true,
              isDark: false,
              initialMetadata: emptyMeta,
            ),
          ),
        ),
      );

      expect(find.text('EMPTY.COM'), findsNothing);
    });
  });
}
