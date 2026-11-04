import 'package:flutter_test/flutter_test.dart';
import 'package:message_pro/data/models/notification_settings.dart';

void main() {
  group('NotificationSettings Model Tests', () {
    test('parses notification_settings from JSON correctly', () {
      final json = {
        'id': 42,
        'account_id': 1,
        'user_id': 5,
        'selected_email_flags': [
          'email_conversation_creation',
          'email_conversation_assignment',
        ],
        'selected_push_flags': [
          'push_conversation_creation',
          'push_conversation_assignment',
          'push_conversation_mention',
          'push_assigned_conversation_new_message',
          'push_participating_conversation_new_message',
        ],
      };

      final settings = NotificationSettings.fromJson(json);

      expect(settings.id, 42);
      expect(settings.accountId, 1);
      expect(settings.userId, 5);
      expect(settings.selectedEmailFlags.length, 2);
      expect(settings.selectedPushFlags.length, 5);
      expect(settings.hasEmailFlag(NotificationSettings.flagConversationCreation), isTrue);
      expect(settings.hasEmailFlag(NotificationSettings.flagConversationMention), isFalse);
      expect(settings.hasPushFlag(NotificationSettings.flagConversationCreation), isTrue);
      expect(settings.pushPresetMode, 'All conversations');
    });

    test('correctly computes push preset modes', () {
      // None preset
      const noneSettings = NotificationSettings(selectedPushFlags: []);
      expect(noneSettings.pushPresetMode, 'None');

      // Assigned only preset
      final assignedOnly = const NotificationSettings().applyPushPreset('Assigned only');
      expect(assignedOnly.pushPresetMode, 'Assigned only');
      expect(assignedOnly.hasPushFlag(NotificationSettings.flagConversationAssignment), isTrue);
      expect(assignedOnly.hasPushFlag(NotificationSettings.flagAssignedConversationNewMessage), isTrue);
      expect(assignedOnly.hasPushFlag(NotificationSettings.flagConversationMention), isTrue);
      expect(assignedOnly.hasPushFlag(NotificationSettings.flagConversationCreation), isFalse);

      // All conversations preset
      final allSettings = const NotificationSettings().applyPushPreset('All conversations');
      expect(allSettings.pushPresetMode, 'All conversations');
      expect(allSettings.selectedPushFlags.length, 5);
    });

    test('toggles flags without mutating original', () {
      const initial = NotificationSettings(
        selectedPushFlags: ['push_conversation_creation'],
      );

      final added = initial.togglePushFlag(NotificationSettings.flagConversationAssignment, true);
      expect(initial.selectedPushFlags.length, 1);
      expect(added.selectedPushFlags.length, 2);
      expect(added.hasPushFlag(NotificationSettings.flagConversationAssignment), isTrue);

      final removed = added.togglePushFlag(NotificationSettings.flagConversationCreation, false);
      expect(removed.selectedPushFlags.length, 1);
      expect(removed.hasPushFlag(NotificationSettings.flagConversationCreation), isFalse);
    });

    test('generates valid update payload', () {
      const settings = NotificationSettings(
        selectedEmailFlags: ['email_conversation_creation'],
        selectedPushFlags: ['push_conversation_creation'],
      );

      final payload = settings.toUpdatePayload();
      expect(payload['selected_email_flags'], ['email_conversation_creation']);
      expect(payload['selected_push_flags'], ['push_conversation_creation']);
      expect(payload['notification_settings'], isNotNull);
    });
  });
}
