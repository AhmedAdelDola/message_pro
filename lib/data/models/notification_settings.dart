import 'package:equatable/equatable.dart';

class NotificationSettings extends Equatable {
  final int? id;
  final int? accountId;
  final int? userId;
  final List<String> selectedEmailFlags;
  final List<String> selectedPushFlags;

  const NotificationSettings({
    this.id,
    this.accountId,
    this.userId,
    this.selectedEmailFlags = const [],
    this.selectedPushFlags = const [],
  });

  // Standard flag keys
  static const String flagConversationCreation = 'conversation_creation';
  static const String flagConversationAssignment = 'conversation_assignment';
  static const String flagConversationMention = 'conversation_mention';
  static const String flagAssignedConversationNewMessage = 'assigned_conversation_new_message';
  static const String flagParticipatingConversationNewMessage = 'participating_conversation_new_message';

  static const List<String> allEvents = [
    flagConversationCreation,
    flagConversationAssignment,
    flagConversationMention,
    flagAssignedConversationNewMessage,
    flagParticipatingConversationNewMessage,
  ];

  bool hasEmailFlag(String eventKey) {
    return selectedEmailFlags.contains('email_$eventKey') || selectedEmailFlags.contains(eventKey);
  }

  bool hasPushFlag(String eventKey) {
    return selectedPushFlags.contains('push_$eventKey') || selectedPushFlags.contains(eventKey);
  }

  NotificationSettings toggleEmailFlag(String eventKey, bool enable) {
    final flag = 'email_$eventKey';
    final updated = List<String>.from(selectedEmailFlags);
    if (enable) {
      if (!updated.contains(flag) && !updated.contains(eventKey)) {
        updated.add(flag);
      }
    } else {
      updated.remove(flag);
      updated.remove(eventKey);
    }
    return copyWith(selectedEmailFlags: updated);
  }

  NotificationSettings togglePushFlag(String eventKey, bool enable) {
    final flag = 'push_$eventKey';
    final updated = List<String>.from(selectedPushFlags);
    if (enable) {
      if (!updated.contains(flag) && !updated.contains(eventKey)) {
        updated.add(flag);
      }
    } else {
      updated.remove(flag);
      updated.remove(eventKey);
    }
    return copyWith(selectedPushFlags: updated);
  }

  /// Preset mode helper: 'All conversations', 'Assigned only', 'None', or 'Custom selection'
  String get pushPresetMode {
    final hasAll = allEvents.every((e) => hasPushFlag(e));
    if (hasAll) return 'All conversations';

    final hasNone = allEvents.every((e) => !hasPushFlag(e));
    if (hasNone) return 'None';

    final assignedOnly = hasPushFlag(flagConversationAssignment) &&
        hasPushFlag(flagAssignedConversationNewMessage) &&
        hasPushFlag(flagConversationMention) &&
        !hasPushFlag(flagConversationCreation) &&
        !hasPushFlag(flagParticipatingConversationNewMessage);
    if (assignedOnly) return 'Assigned only';

    return 'Custom selection';
  }

  NotificationSettings applyPushPreset(String preset) {
    switch (preset) {
      case 'All conversations':
        return copyWith(
          selectedPushFlags: allEvents.map((e) => 'push_$e').toList(),
        );
      case 'Assigned only':
        return copyWith(
          selectedPushFlags: [
            'push_$flagConversationAssignment',
            'push_$flagAssignedConversationNewMessage',
            'push_$flagConversationMention',
          ],
        );
      case 'None':
        return copyWith(selectedPushFlags: []);
      default:
        return this;
    }
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final source = json['data'] ?? json['notification_settings'] ?? json;

    final emailList = <String>[];
    if (source['selected_email_flags'] is List) {
      for (final item in source['selected_email_flags']) {
        if (item != null) emailList.add(item.toString());
      }
    }

    final pushList = <String>[];
    if (source['selected_push_flags'] is List) {
      for (final item in source['selected_push_flags']) {
        if (item != null) pushList.add(item.toString());
      }
    }

    return NotificationSettings(
      id: source['id'] is int ? source['id'] : int.tryParse(source['id']?.toString() ?? ''),
      accountId: source['account_id'] is int ? source['account_id'] : int.tryParse(source['account_id']?.toString() ?? ''),
      userId: source['user_id'] is int ? source['user_id'] : int.tryParse(source['user_id']?.toString() ?? ''),
      selectedEmailFlags: emailList,
      selectedPushFlags: pushList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'user_id': userId,
      'selected_email_flags': selectedEmailFlags,
      'selected_push_flags': selectedPushFlags,
    };
  }

  Map<String, dynamic> toUpdatePayload() {
    final flags = {
      'selected_email_flags': selectedEmailFlags,
      'selected_push_flags': selectedPushFlags,
    };
    return {
      'notification_settings': flags,
      ...flags,
    };
  }

  NotificationSettings copyWith({
    int? id,
    int? accountId,
    int? userId,
    List<String>? selectedEmailFlags,
    List<String>? selectedPushFlags,
  }) {
    return NotificationSettings(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      userId: userId ?? this.userId,
      selectedEmailFlags: selectedEmailFlags ?? this.selectedEmailFlags,
      selectedPushFlags: selectedPushFlags ?? this.selectedPushFlags,
    );
  }

  @override
  List<Object?> get props => [id, accountId, userId, selectedEmailFlags, selectedPushFlags];
}
