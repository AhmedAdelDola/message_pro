import 'package:flutter_test/flutter_test.dart';
import 'package:message_pro/data/models/message.dart';

void main() {
  group('Message Activity & Workflow Step Classification Tests', () {
    test('Incoming customer message containing "Automation" and "CRM" is NOT an activity', () {
      final msg = Message(
        id: 1001,
        content: 'مساء الخير، أنا بتواصل مع حضرتكم للاستفسار عن خدمات وعروض الـ CRM & Automation المتاحة لديكم. WhatsApp Automation, Email Automation, Chatbots',
        messageType: 0,
        createdAt: DateTime.now(),
      );

      expect(msg.isActivity, isFalse, reason: 'Incoming message must never be classified as an activity');
      expect(msg.isIncoming, isTrue, reason: 'Incoming message must have isIncoming = true');
      expect(msg.isOutgoing, isFalse);
      expect(msg.isPrivateNote, isFalse);
    });

    test('Incoming customer message mentioning "workflow" is NOT an activity', () {
      final msg = Message(
        id: 1002,
        content: 'هل يمكن ربط النظام بـ workflow معين لمتابعة المبيعات؟',
        messageType: 0,
        createdAt: DateTime.now(),
      );

      expect(msg.isActivity, isFalse);
      expect(msg.isIncoming, isTrue);
      expect(msg.isOutgoing, isFalse);
    });

    test('Outgoing agent/bot message mentioning "Automation" and "Workflow" is NOT an activity', () {
      final msg = Message(
        id: 1003,
        content: 'أهلاً بحضرتك، نوفر نظام Automation متكامل مع WhatsApp workflows لإدارة المحادثات تلقائياً.',
        messageType: 1,
        createdAt: DateTime.now(),
      );

      expect(msg.isActivity, isFalse, reason: 'Outgoing message must never be classified as an activity');
      expect(msg.isOutgoing, isTrue, reason: 'Outgoing message must have isOutgoing = true');
      expect(msg.isIncoming, isFalse);
      expect(msg.isPrivateNote, isFalse);
    });

    test('Private note mentioning "automation" or "assigned to" is NOT an activity', () {
      final msg = Message(
        id: 1004,
        content: 'Workflow triggered: Contact assigned to agent by automation system',
        messageType: 1,
        private: true,
        createdAt: DateTime.now(),
      );

      expect(msg.isActivity, isFalse, reason: 'Private note must never be classified as an activity');
      expect(msg.isPrivateNote, isTrue, reason: 'Private note must have isPrivateNote = true');
    });

    test('True activity message (message_type == 2) is classified as an activity', () {
      final msg = Message(
        id: 1005,
        content: 'Automation System changed the contact lifecycle stage from New Lead to Engaged Lead',
        messageType: 2,
        createdAt: DateTime.now(),
      );

      expect(msg.isActivity, isTrue);
      expect(msg.isIncoming, isFalse);
      expect(msg.isOutgoing, isFalse);
      expect(msg.isPrivateNote, isFalse);
    });

    test('Ambiguous messageType fallback only matches explicit system prefixes', () {
      // Ambiguous messageType (e.g. 99) with explicit system prefix
      final systemMsg = Message(
        id: 1006,
        content: 'System: Conversation priority changed to High',
        messageType: 99,
        createdAt: DateTime.now(),
      );
      expect(systemMsg.isActivity, isTrue);

      final workflowMsg = Message(
        id: 1007,
        content: 'Workflow "Assigning" triggered (Conversation opened)',
        messageType: 99,
        createdAt: DateTime.now(),
      );
      expect(workflowMsg.isActivity, isTrue);

      // Ambiguous messageType with normal conversation text mentioning automation
      final normalTextMsg = Message(
        id: 1008,
        content: 'We need automation for our team',
        messageType: 99,
        createdAt: DateTime.now(),
      );
      expect(normalTextMsg.isActivity, isFalse);
    });

    test('JSON parsing preserves message_type 0 and 1 with automation keywords correctly', () {
      final jsonIncoming = {
        'id': 2001,
        'content': 'استفسار عن أسعار الأتمتة WhatsApp Automation',
        'message_type': 0,
        'created_at': 1731686400,
      };
      final parsedIncoming = Message.fromJson(jsonIncoming);
      expect(parsedIncoming.isActivity, isFalse);
      expect(parsedIncoming.isIncoming, isTrue);

      final jsonOutgoing = {
        'id': 2002,
        'content': 'سعر باقة الـ Automation يبدأ من 50 دولار',
        'message_type': 1,
        'created_at': 1731686500,
      };
      final parsedOutgoing = Message.fromJson(jsonOutgoing);
      expect(parsedOutgoing.isActivity, isFalse);
      expect(parsedOutgoing.isOutgoing, isTrue);

      final jsonActivity = {
        'id': 2003,
        'content': 'Contact assigned to Khaled Ahmed by Khaled Ahmed',
        'message_type': 2,
        'created_at': 1731686600,
      };
      final parsedActivity = Message.fromJson(jsonActivity);
      expect(parsedActivity.isActivity, isTrue);
      expect(parsedActivity.isIncoming, isFalse);
      expect(parsedActivity.isOutgoing, isFalse);
    });
  });
}
