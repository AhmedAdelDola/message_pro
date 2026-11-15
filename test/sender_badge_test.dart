import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_pro/data/models/message.dart';
import 'package:message_pro/ui/screens/chat/widgets/message_bubble.dart';

void main() {
  group('Sender Badge Classification Tests', () {
    test('Identifies message sent by Agent (type User)', () {
      final msg = Message.fromJson({
        'id': 1,
        'message_type': 1,
        'content': 'Hello from agent',
        'sender': {
          'id': 10,
          'name': 'Ahmed Agent',
          'type': 'user',
        },
      });

      expect(msg.senderType, 'user');
      expect(msg.isSentByAgent, isTrue);
      expect(msg.isBot, isFalse);
      expect(msg.isSentFromPlatform, isFalse);
    });

    test('Identifies message sent by Bot / AI Agent', () {
      final msg = Message.fromJson({
        'id': 2,
        'message_type': 1,
        'content': 'Hello from AI Bot',
        'sender': {
          'id': 11,
          'name': 'AI Agent Assistant',
          'type': 'agent_bot',
        },
      });

      expect(msg.isBot, isTrue);
      expect(msg.isSentByAgent, isFalse);
      expect(msg.isSentFromPlatform, isFalse);
    });

    test('Identifies message sent directly from WhatsApp platform', () {
      // Direct message from WhatsApp phone app sync has no agent user sender
      final msg = Message.fromJson({
        'id': 3,
        'message_type': 1,
        'content': 'Hello directly from WhatsApp app',
        'sender': null,
      });

      expect(msg.senderType, isNull);
      expect(msg.isSentByAgent, isFalse);
      expect(msg.isBot, isFalse);
      expect(msg.isSentFromPlatform, isTrue);
    });

    test('Identifies platform message when sender is generic platform name', () {
      final msg = Message.fromJson({
        'id': 4,
        'message_type': 1,
        'content': 'Auto sync from Messenger',
        'sender': {
          'name': 'Messenger',
        },
      });

      expect(msg.isSentByAgent, isFalse);
      expect(msg.isSentFromPlatform, isTrue);
    });
  });

  group('Sender Badge Widget Tests', () {
    testWidgets('Renders WhatsApp platform badge & tooltip for platform outgoing message', (tester) async {
      final msg = Message(
        id: 101,
        content: 'Sent from WhatsApp directly',
        messageType: 1, // Outgoing
        createdAt: DateTime.now(),
        senderName: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: msg,
              channel: 'Channel::Whatsapp',
            ),
          ),
        ),
      );

      // Verify Tooltip has "مُرسل من واتساب"
      final tooltipFinder = find.byType(Tooltip);
      expect(tooltipFinder, findsWidgets);

      final tooltip = tester.widget<Tooltip>(tooltipFinder.first);
      expect(tooltip.message, 'مُرسل من واتساب');

      // Verify WhatsApp asset image is loaded
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
    });

    testWidgets('Renders Messenger platform badge & tooltip for Messenger message', (tester) async {
      final msg = Message(
        id: 102,
        content: 'Sent from Messenger directly',
        messageType: 1, // Outgoing
        createdAt: DateTime.now(),
        senderName: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: msg,
              channel: 'Channel::FacebookPage',
            ),
          ),
        ),
      );

      final tooltipFinder = find.byType(Tooltip);
      expect(tooltipFinder, findsWidgets);

      final tooltip = tester.widget<Tooltip>(tooltipFinder.first);
      expect(tooltip.message, 'مُرسل من ماسنجر');

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
    });

    testWidgets('Renders Agent initial and tooltip for agent-sent message', (tester) async {
      final msg = Message(
        id: 103,
        content: 'Sent by Sarah Agent',
        messageType: 1, // Outgoing
        createdAt: DateTime.now(),
        senderName: 'Sarah',
        senderType: 'user',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: msg,
              channel: 'Channel::Whatsapp',
            ),
          ),
        ),
      );

      // Verify Agent Initial 'S' is rendered
      expect(find.text('S'), findsOneWidget);

      // Verify Tooltip shows agent's name 'Sarah'
      final tooltipFinder = find.byType(Tooltip);
      expect(tooltipFinder, findsWidgets);

      final tooltip = tester.widget<Tooltip>(tooltipFinder.first);
      expect(tooltip.message, 'Sarah');
    });

    testWidgets('Renders Bot badge and tooltip for bot outgoing message', (tester) async {
      final msg = Message(
        id: 104,
        content: 'Automatic welcome response',
        messageType: 1, // Outgoing
        createdAt: DateTime.now(),
        senderName: 'Bot System',
        senderType: 'agent_bot',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: msg,
              channel: 'Channel::Whatsapp',
            ),
          ),
        ),
      );

      // Verify Bot Icon is rendered
      expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);

      // Verify Tooltip shows 'رد آلي / بوت'
      final tooltipFinder = find.byType(Tooltip);
      expect(tooltipFinder, findsWidgets);

      final tooltip = tester.widget<Tooltip>(tooltipFinder.first);
      expect(tooltip.message, 'رد آلي / بوت');
    });
  });
}
