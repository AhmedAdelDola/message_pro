import 'package:flutter_test/flutter_test.dart';
import 'package:message_pro/data/models/message.dart';
import 'package:message_pro/data/models/user.dart';

void main() {
  group('MessageActions Tests', () {
    test('parses message_actions correctly from JSON', () {
      final json = {
        'edit': false,
        'delete': true,
        'react': true,
        'forward': true,
        'edit_until': null,
        'delete_until': 1999999999, // far future
      };

      final actions = MessageActions.fromJson(json);
      expect(actions.canEdit, isFalse);
      expect(actions.canDelete, isTrue);
      expect(actions.canReact, isTrue);
      expect(actions.canForward, isTrue);
      expect(actions.deleteUntil, equals(1999999999));
      expect(actions.isDeleteExpired, isFalse);
      expect(actions.remainingDeleteTime, isNotNull);
      expect(actions.remainingDeleteTime!.inSeconds, greaterThan(0));
    });

    test('isDeleteExpired returns true when delete_until is in the past', () {
      final json = {
        'delete': true,
        'delete_until': 1600000000, // past timestamp
      };
      final actions = MessageActions.fromJson(json);
      expect(actions.canDelete, isTrue);
      expect(actions.isDeleteExpired, isTrue);
      expect(actions.remainingDeleteTime, equals(Duration.zero));
    });
  });

  group('Message Permissions & State Tests', () {
    final now = DateTime.now();

    final normalUser = User(id: 10, name: 'Agent Smith', email: 'smith@test.com', accountId: 1, role: 'agent');
    final adminUser = User(id: 99, name: 'Admin Boss', email: 'admin@test.com', accountId: 1, role: 'administrator');
    final otherUser = User(id: 20, name: 'Other Agent', email: 'other@test.com', accountId: 1, role: 'agent');

    test('canDeleteBy validates sender, admin, and delete permissions', () {
      final msgActions = MessageActions(
        canDelete: true,
        deleteUntil: (now.millisecondsSinceEpoch ~/ 1000) + 3600, // +1 hour
      );

      final msg = Message(
        id: 101,
        conversationId: 50,
        messageType: 1, // outgoing
        senderId: 10,
        senderName: 'Agent Smith',
        createdAt: now,
        messageActions: msgActions,
      );

      // Sender can delete
      expect(msg.canDeleteBy(normalUser), isTrue);

      // Admin can delete
      expect(msg.canDeleteBy(adminUser), isTrue);

      // Unrelated user cannot delete
      expect(msg.canDeleteBy(otherUser), isFalse);

      // If delete permission is false
      final msgNoDelete = msg.copyWith(
        messageActions: const MessageActions(canDelete: false),
      );
      expect(msgNoDelete.canDeleteBy(normalUser), isFalse);
      expect(msgNoDelete.canDeleteBy(adminUser), isFalse);
    });

    test('isDeleted is true when content_attributes.deleted is true', () {
      final msg = Message(
        id: 102,
        conversationId: 50,
        messageType: 0,
        createdAt: now,
        contentAttributes: {'deleted': true},
        messageActions: const MessageActions(canDelete: true),
      );

      expect(msg.isDeleted, isTrue);
      // Once deleted, canDeleteBy and canEditBy must return false
      expect(msg.canDeleteBy(adminUser), isFalse);
      expect(msg.canEditBy(adminUser), isFalse);
    });

    test('isEdited is NOT true just because updatedAt > createdAt (bug fix)', () {
      final msgNotEdited = Message(
        id: 103,
        conversationId: 50,
        messageType: 0,
        createdAt: now,
        updatedAt: now.add(const Duration(minutes: 5)), // updatedAt changed by read receipt
        contentAttributes: {},
        additionalAttributes: {},
      );

      // Must be false because no edit action took place
      expect(msgNotEdited.isEdited, isFalse);

      // Must be true when explicit edited flag is present
      final msgEdited = Message(
        id: 104,
        conversationId: 50,
        messageType: 1,
        createdAt: now,
        contentAttributes: {'is_edited': true},
      );
      expect(msgEdited.isEdited, isTrue);
    });
  });

  group('cleanMessageText & Mentions Tests', () {
    test('cleans markdown mentions to @PersonName only', () {
      const rawText = 'Hello [@Ahmed Mohamed](mention://user/123/Ahmed%20Mohamed) please review this.';
      final cleaned = Message.cleanMessageText(rawText);
      expect(cleaned, equals('Hello @Ahmed Mohamed please review this.'));
    });

    test('cleans escaped mentions and bracketed mentions', () {
      const rawText = r'Ping \[@Sara Ali\](mention://user/456) and [@Support Team]';
      final cleaned = Message.cleanMessageText(rawText);
      expect(cleaned, equals('Ping @Sara Ali and @Support Team'));
    });

    test(r'removes markdown escape backslashes \ without breaking punctuation', () {
      const rawText = r'This is a test \[with brackets\] and \*bold\* \- bullet \. \! \\';
      final cleaned = Message.cleanMessageText(rawText);
      expect(cleaned, equals('This is a test [with brackets] and *bold* - bullet . ! '));
    });

    test('preserves proper newlines', () {
      const rawText = 'Line 1\nLine 2\r\nLine 3';
      final cleaned = Message.cleanMessageText(rawText);
      expect(cleaned, equals('Line 1\nLine 2\nLine 3'));
    });
  });
}
