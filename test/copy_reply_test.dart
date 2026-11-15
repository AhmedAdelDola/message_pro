import 'package:flutter_test/flutter_test.dart';
import 'package:message_pro/data/models/message.dart';

void main() {
  group('Copy & Reply Tests', () {
    test('Message model parses inReplyToId from int correctly', () {
      final json = {
        'id': 1001,
        'message_type': 1,
        'content': 'This is a reply to message 500',
        'content_attributes': {
          'in_reply_to': 500,
        },
      };

      final msg = Message.fromJson(json);
      expect(msg.inReplyToId, 500);
    });

    test('Message model parses inReplyToId from string correctly', () {
      final json = {
        'id': 1002,
        'message_type': 0,
        'content': 'Customer reply to 600',
        'content_attributes': {
          'in_reply_to': '600',
        },
      };

      final msg = Message.fromJson(json);
      expect(msg.inReplyToId, 600);
    });

    test('Message model parses inReplyToId from nested map or external id', () {
      final json = {
        'id': 1003,
        'message_type': 1,
        'content': 'Nested reply structure',
        'content_attributes': {
          'in_reply_to': {
            'id': 700,
          },
        },
      };

      final msg = Message.fromJson(json);
      expect(msg.inReplyToId, 700);
    });

    test('Message without in_reply_to returns null for inReplyToId', () {
      final json = {
        'id': 1004,
        'message_type': 0,
        'content': 'Regular message without reply',
      };

      final msg = Message.fromJson(json);
      expect(msg.inReplyToId, isNull);
    });
  });
}
