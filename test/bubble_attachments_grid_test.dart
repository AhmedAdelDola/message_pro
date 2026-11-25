import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_pro/data/models/message.dart';
import 'package:message_pro/ui/screens/chat/widgets/bubble/incoming_bubble_view.dart';
import 'package:message_pro/ui/screens/chat/widgets/bubble/outgoing_bubble_view.dart';

Widget _wrapWithApp(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (context, _) => MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

Message _buildImageMessage({required int id, required int imageCount, required bool isOutgoing}) {
  return Message.fromJson({
    'id': id,
    'conversation_id': 1,
    'message_type': isOutgoing ? 1 : 0,
    'content': 'Images ($imageCount)',
    'attachments': List.generate(
      imageCount,
      (index) => {
        'id': index + 1,
        'file_type': 'image',
        'data_url': 'https://example.com/photo_$index.jpg',
        'file_name': 'photo_$index.jpg',
      },
    ),
  });
}

void main() {
  group('Bubble image grid layout inside IntrinsicWidth', () {
    for (final count in [2, 3, 4, 5]) {
      testWidgets('OutgoingBubbleView lays out $count images without finite width assertion', (
        tester,
      ) async {
        final msg = _buildImageMessage(id: count, imageCount: count, isOutgoing: true);

        await tester.pumpWidget(
          _wrapWithApp(
            OutgoingBubbleView(
              message: msg,
              isDark: false,
              isArabic: false,
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('IncomingBubbleView lays out $count images without finite width assertion', (
        tester,
      ) async {
        final msg = _buildImageMessage(id: 100 + count, imageCount: count, isOutgoing: false);

        await tester.pumpWidget(
          _wrapWithApp(
            IncomingBubbleView(
              message: msg,
              contactName: 'Test User',
              isDark: false,
              isArabic: false,
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }
  });
}
