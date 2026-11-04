class NotificationItem {
  final int id;
  final String notificationType;
  final int? primaryActorId;
  final String? primaryActorType;
  final int? conversationId;
  final String? title;
  final String? message;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.notificationType,
    this.primaryActorId,
    this.primaryActorType,
    this.conversationId,
    this.title,
    this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime dt = DateTime.now();
    if (json['created_at'] != null) {
      if (json['created_at'] is num) {
        final val = (json['created_at'] as num).toInt();
        dt = DateTime.fromMillisecondsSinceEpoch(val > 1e11 ? val : val * 1000);
      } else if (json['created_at'] is String) {
        dt = DateTime.tryParse(json['created_at']) ?? DateTime.now();
      }
    }

    final rawType = json['notification_type'] ?? 'conversation_creation';
    String genTitle = 'New Notification';
    String genMessage = 'You have a new update';

    if (rawType == 'conversation_assignment') {
      genTitle = 'Conversation Assigned';
      genMessage = 'A conversation was assigned to you';
    } else if (rawType == 'conversation_creation') {
      genTitle = 'New Conversation';
      genMessage = 'A new conversation was created';
    } else if (rawType == 'conversation_mention') {
      genTitle = 'You were mentioned';
      genMessage = 'Someone mentioned you in a private note';
    } else if (rawType == 'assigned_conversation_new_message') {
      genTitle = 'New Message';
      genMessage = 'New message in your assigned conversation';
    }

    // Per handoff doc: For a Conversation actor, navigate using primary_actor.id (display ID), not primary_actor_id
    int? resolvedConvId;
    final actorType = json['primary_actor_type']?.toString();
    if (actorType == 'Conversation') {
      final actor = json['primary_actor'];
      if (actor is Map && actor['id'] != null) {
        resolvedConvId = actor['id'] is int ? actor['id'] : int.tryParse(actor['id'].toString());
      } else {
        resolvedConvId = json['primary_actor_id'] is int
            ? json['primary_actor_id']
            : int.tryParse(json['primary_actor_id']?.toString() ?? '');
      }
    }

    return NotificationItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      notificationType: rawType,
      primaryActorId: json['primary_actor_id'] is int
          ? json['primary_actor_id']
          : int.tryParse(json['primary_actor_id']?.toString() ?? ''),
      primaryActorType: actorType,
      conversationId: resolvedConvId,
      title: json['push_message_title'] ?? json['title'] ?? genTitle,
      message: json['push_message_body'] ?? json['message'] ?? genMessage,
      isRead: json['read_at'] != null,
      createdAt: dt,
    );
  }

  DateTime get timestamp => createdAt;

  NotificationItem copyWith({
    int? id,
    String? notificationType,
    int? primaryActorId,
    String? primaryActorType,
    int? conversationId,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      notificationType: notificationType ?? this.notificationType,
      primaryActorId: primaryActorId ?? this.primaryActorId,
      primaryActorType: primaryActorType ?? this.primaryActorType,
      conversationId: conversationId ?? this.conversationId,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CallItem {
  final String id;
  final String contactName;
  final String? contactPhone;
  final String? avatarUrl;
  final String callType; // 'incoming', 'outgoing', 'missed'
  final String duration;
  final DateTime timestamp;

  CallItem({
    required this.id,
    required this.contactName,
    this.contactPhone,
    this.avatarUrl,
    required this.callType,
    required this.duration,
    required this.timestamp,
  });

  String get phoneNumber => contactPhone ?? '';
}
