class NotificationItem {
  final int id;
  final String notificationType;
  final int? primaryActorId;
  final String? primaryActorType;
  final String? title;
  final String? message;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.notificationType,
    this.primaryActorId,
    this.primaryActorType,
    this.title,
    this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime dt = DateTime.now();
    if (json['created_at'] != null) {
      if (json['created_at'] is int) {
        final val = json['created_at'] as int;
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

    return NotificationItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      notificationType: rawType,
      primaryActorId: json['primary_actor_id'],
      primaryActorType: json['primary_actor_type'],
      title: json['title'] ?? genTitle,
      message: json['message'] ?? genMessage,
      isRead: json['read_at'] != null,
      createdAt: dt,
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
}
