import 'package:flutter_test/flutter_test.dart';
import 'package:message_pro/data/models/conversation.dart';

void main() {
  group('Conversation parsing tests', () {
    test('parses conversation with last_non_activity_message correctly without type error', () {
      final json = {
        'id': 101,
        'account_id': 1,
        'inbox_id': 2,
        'status': 'open',
        'unread_count': 3,
        'meta': {
          'sender': {
            'id': 55,
            'name': 'Ahmed Ali',
            'phone_number': '+201000000000',
          },
          'assignee': {
            'id': 12,
            'name': 'Support Agent',
          },
          'channel': 'Channel::Whatsapp',
        },
        'last_non_activity_message': {
          'id': 999,
          'content': 'مرحبا، كيف يمكنني المساعدة؟',
          'message_type': 1,
          'created_at': 1700000000,
        },
        'messages': [
          {
            'id': 998,
            'content': 'رسالة قديمة',
            'message_type': 0,
            'created_at': 1699999000,
          }
        ],
        'timestamp': 1700000000,
      };

      final conv = Conversation.fromJson(json);

      expect(conv.id, 101);
      expect(conv.contact.name, 'Ahmed Ali');
      expect(conv.channel, 'whatsapp');
      expect(conv.lastMessage, isNotNull);
      expect(conv.lastMessage!.id, 999);
      expect(conv.lastMessage!.content, 'مرحبا، كيف يمكنني المساعدة؟');
      expect(conv.assignee?.name, 'Support Agent');
    });

    test('parses fallback to last message in messages list when last_non_activity_message is null', () {
      final json = {
        'id': 102,
        'account_id': 1,
        'inbox_id': 2,
        'contact': {
          'id': 60,
          'name': 'Sara',
        },
        'messages': [
          {
            'id': 500,
            'content': 'آخر رسالة',
            'message_type': 0,
          }
        ],
      };

      final conv = Conversation.fromJson(json);

      expect(conv.id, 102);
      expect(conv.contact.name, 'Sara');
      expect(conv.lastMessage, isNotNull);
      expect(conv.lastMessage!.content, 'آخر رسالة');
    });
  });
}
