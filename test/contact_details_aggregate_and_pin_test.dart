import 'package:flutter_test/flutter_test.dart';
import 'package:message_pro/data/models/contact_details_aggregate.dart';
import 'package:message_pro/data/models/conversation.dart';

void main() {
  group('isPinned Parsing Tests', () {
    test('parses exact camelCase isPinned boolean from JSON', () {
      final pinnedConv = Conversation.fromJson({
        'id': 905,
        'account_id': 10,
        'inbox_id': 1,
        'status': 'open',
        'isPinned': true,
      });
      expect(pinnedConv.isPinned, isTrue);

      final unpinnedConv = Conversation.fromJson({
        'id': 906,
        'account_id': 10,
        'inbox_id': 1,
        'status': 'open',
        'isPinned': false,
      });
      expect(unpinnedConv.isPinned, isFalse);
    });
  });

  group('ContactDetailsAggregate Parsing Tests', () {
    test('parses full aggregate object without payload wrapper', () {
      final json = {
        'contact': {
          'id': 144924,
          'name': 'فرح اكونت مانجر',
          'phone_number': '+201555819662',
          'labels': ['vip', 'lead'],
          'custom_attributes': {'company_name': 'Wapilot'},
        },
        'calls': [],
        'ai_activity': [
          {
            'id': 1,
            'title': 'AI Assistant',
            'summary': 'Answered inquiry',
            'status': 'completed',
          }
        ],
        'attachments': [
          {
            'id': 10,
            'message_id': 500,
            'conversation_id': 905,
            'file_type': 'audio',
            'data_url': 'https://example.com/no-filename.oga',
            'file_size': 33792,
          }
        ],
        'activities': [
          {
            'id': 2,
            'content': 'You unassigned this person',
            'conversation_id': 905,
          }
        ],
        'notes': [
          {
            'id': 3,
            'content': 'Ping [@Khaled Ahmed](mention://user/1/Khaled)',
            'conversation_id': 905,
            'sender': {'name': 'Noran karam'},
          }
        ],
        'calendar': [],
        'ecommerce': {
          'enabled': true,
          'stores': [
            {
              'connection': {'id': 'conn_1', 'name': 'Wapilot', 'shop_domain': 'wapilot.myshopify.com'},
              'match': {'matched': false},
              'orders': [],
              'page_info': {'has_next_page': false},
              'error': {'code': 'SHOPIFY_TIMEOUT', 'message': 'Store API timed out'},
            }
          ],
        },
        'meta': {
          'sections': ['ai_activity', 'attachments', 'activities', 'notes', 'calendar', 'ecommerce'],
          'pagination': {
            'notes': {'has_more': true, 'next_page': 2, 'current_page': 1},
          },
        },
      };

      final agg = ContactDetailsAggregate.fromJson(json);
      expect(agg.contact?.id, equals(144924));
      expect(agg.labels, containsAll(['vip', 'lead']));
      expect(agg.aiActivity?.length, equals(1));
      expect(agg.attachments?.first.formattedSize, equals('33 KB'));
      expect(agg.activities?.first.title, equals('Unassigned'));
      expect(agg.notes?.first.authorName, equals('Noran karam'));
      expect(agg.ecommerce?.enabled, isTrue);
      expect(agg.ecommerce?.stores.first.error?.code, equals('SHOPIFY_TIMEOUT'));
      expect(agg.pagination['notes']?.hasMore, isTrue);
      expect(agg.pagination['notes']?.nextPage, equals(2));
    });

    test('omitted sections stay null so partial responses do not wipe state', () {
      final partialJson = {
        'contact': {'id': 55, 'name': 'Test'},
        'notes': [
          {'id': 9, 'content': 'Page 2 note'}
        ],
        'meta': {
          'sections': ['notes'],
          'pagination': {
            'notes': {'has_more': false, 'next_page': null, 'current_page': 2},
          },
        },
      };

      final agg = ContactDetailsAggregate.fromJson(partialJson);
      expect(agg.notes?.length, equals(1));
      expect(agg.attachments, isNull);
      expect(agg.activities, isNull);
      expect(agg.ecommerce, isNull);
    });
  });
}
