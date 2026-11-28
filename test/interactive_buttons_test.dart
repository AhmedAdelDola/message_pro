import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_pro/data/models/message.dart';
import 'package:message_pro/data/models/message_template.dart';
import 'package:message_pro/ui/screens/chat/widgets/bubble/outgoing_bubble_view.dart';

void main() {
  group('TemplateButton & Message interactive buttons', () {
    test('TemplateButton.from parses WhatsApp Cloud reply structure', () {
      final btn = TemplateButton.from({
        'type': 'reply',
        'reply': {'id': 'opt_1', 'title': '١-٢ مستخدم'},
      });

      expect(btn.text, '١-٢ مستخدم');
      expect(btn.type, 'QUICK_REPLY');
    });

    test('Message.templateActionButtons extracts Chatwoot input_select items', () {
      final msg = Message(
        id: 1,
        content: 'محتاج كام مستخدم على المنصة؟',
        messageType: 1,
        contentType: 'input_select',
        contentAttributes: {
          'items': [
            {'title': '١-٢ مستخدم', 'value': '1-2'},
            {'title': '٣-٥ مستخدمين', 'value': '3-5'},
            {'title': '٦ مستخدمين أو أكثر', 'value': '6+'},
          ],
        },
        createdAt: DateTime(2026, 1, 1),
      );

      expect(msg.isTemplate, isFalse);
      expect(msg.hasInteractiveButtons, isTrue);
      expect(msg.templateButtons, [
        '١-٢ مستخدم',
        '٣-٥ مستخدمين',
        '٦ مستخدمين أو أكثر',
      ]);
    });

    test('Message.templateActionButtons extracts WhatsApp interactive sections', () {
      final msg = Message(
        id: 2,
        content: 'اختر باقة',
        messageType: 1,
        additionalAttributes: {
          'interactive': {
            'action': {
              'sections': [
                {
                  'rows': [
                    {'id': 'r1', 'title': 'الباقة الأساسية'},
                    {'id': 'r2', 'title': 'الباقة الاحترافية'},
                  ],
                },
              ],
            },
          },
        },
        createdAt: DateTime(2026, 1, 1),
      );

      expect(msg.hasInteractiveButtons, isTrue);
      expect(msg.templateButtons, ['الباقة الأساسية', 'الباقة الاحترافية']);
    });

    testWidgets('OutgoingBubbleView renders interactive reply buttons', (tester) async {
      final msg = Message(
        id: 3,
        content: 'محتاج كام مستخدم على المنصة؟',
        messageType: 1,
        contentType: 'input_select',
        contentAttributes: {
          'items': [
            {'title': '١-٢ مستخدم', 'value': '1-2'},
            {'title': '٣-٥ مستخدمين', 'value': '3-5'},
            {'title': '٦ مستخدمين أو أكثر', 'value': '6+'},
          ],
        },
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutgoingBubbleView(
              message: msg,
              isDark: false,
              isArabic: true,
            ),
          ),
        ),
      );

      expect(find.text('١-٢ مستخدم'), findsOneWidget);
      expect(find.text('٣-٥ مستخدمين'), findsOneWidget);
      expect(find.text('٦ مستخدمين أو أكثر'), findsOneWidget);
      expect(find.byIcon(Icons.reply_rounded), findsNWidgets(3));
    });
  });
}
