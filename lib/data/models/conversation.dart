import 'contact.dart';
import 'message.dart';
import 'user.dart';

class Conversation {
  final int id;
  final int accountId;
  final int inboxId;
  final String status; // open, resolved, pending, snoozed
  final int unreadCount;
  final String? priority;
  final String channel;
  final Contact contact;
  final Message? lastMessage;
  final User? assignee;
  final Team? team;
  final List<String> labels;
  final LifecycleStage? lifecycleStage;
  final DateTime updatedAt;
  final DateTime createdAt;

  Conversation({
    required this.id,
    required this.accountId,
    required this.inboxId,
    this.status = 'open',
    this.unreadCount = 0,
    this.priority,
    this.channel = 'web',
    required this.contact,
    this.lastMessage,
    this.assignee,
    this.team,
    this.labels = const [],
    this.lifecycleStage,
    required this.updatedAt,
    required this.createdAt,
  });

  Conversation copyWith({
    int? id,
    int? accountId,
    int? inboxId,
    String? status,
    int? unreadCount,
    String? priority,
    String? channel,
    Contact? contact,
    Message? lastMessage,
    User? assignee,
    Team? team,
    List<String>? labels,
    LifecycleStage? lifecycleStage,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      inboxId: inboxId ?? this.inboxId,
      status: status ?? this.status,
      unreadCount: unreadCount ?? this.unreadCount,
      priority: priority ?? this.priority,
      channel: channel ?? this.channel,
      contact: contact ?? this.contact,
      lastMessage: lastMessage ?? this.lastMessage,
      assignee: assignee ?? this.assignee,
      team: team ?? this.team,
      labels: labels ?? this.labels,
      lifecycleStage: lifecycleStage ?? this.lifecycleStage,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    // Contact extraction
    Contact parsedContact;
    if (json['meta'] != null && json['meta']['sender'] is Map<String, dynamic>) {
      parsedContact = Contact.fromJson(json['meta']['sender']);
    } else if (json['contact'] is Map<String, dynamic>) {
      parsedContact = Contact.fromJson(json['contact']);
    } else {
      parsedContact = Contact(id: 0, name: 'Contact #${json['id']}');
    }

    // Last message
    Message? lastMsg;
    final rawLast = json['last_non_activity_message'] ?? json['messages'] is List && (json['messages'] as List).isNotEmpty ? (json['messages'] as List).last : null;
    if (rawLast is Map<String, dynamic>) {
      lastMsg = Message.fromJson(rawLast);
    }

    // Assignee
    User? parsedAssignee;
    final rawAssignee = json['meta']?['assignee'] ?? json['assignee'];
    if (rawAssignee is Map<String, dynamic>) {
      parsedAssignee = User.fromJson(rawAssignee);
    }

    // Team
    Team? parsedTeam;
    final rawTeam = json['meta']?['team'] ?? json['team'];
    if (rawTeam is Map<String, dynamic>) {
      parsedTeam = Team.fromJson(rawTeam);
    }

    // Channel detection
    String ch = 'web';
    final rawChannel = json['meta']?['channel'] ?? json['inbox']?['channel_type'];
    if (rawChannel is String) {
      final lower = rawChannel.toLowerCase();
      if (lower.contains('whatsapp')) {
        ch = 'whatsapp';
      } else if (lower.contains('facebook')) {
        ch = 'facebook';
      } else if (lower.contains('email')) {
        ch = 'email';
      } else if (lower.contains('telegram')) {
        ch = 'telegram';
      } else if (lower.contains('api')) {
        ch = 'api';
      }
    }

    // Labels
    final labelsList = <String>[];
    final rawLabels = json['labels'];
    if (rawLabels is List) {
      for (final l in rawLabels) {
        if (l is String) {
          labelsList.add(l);
        } else if (l is Map && l['title'] != null) {
          labelsList.add(l['title'].toString());
        }
      }
    }

    // Lifecycle stage
    LifecycleStage? stage;
    final rawStage = json['lifecycle_stage'];
    if (rawStage is Map<String, dynamic>) {
      stage = LifecycleStage.fromJson(rawStage);
    }

    DateTime dtUpdated = DateTime.now();
    if (json['timestamp'] != null) {
      final t = json['timestamp'];
      if (t is int) {
        dtUpdated = DateTime.fromMillisecondsSinceEpoch(t > 1e11 ? t : t * 1000);
      }
    } else if (json['last_activity_at'] != null) {
      final t = json['last_activity_at'];
      if (t is int) {
        dtUpdated = DateTime.fromMillisecondsSinceEpoch(t > 1e11 ? t : t * 1000);
      } else if (t is String) {
        dtUpdated = DateTime.tryParse(t) ?? DateTime.now();
      }
    }

    DateTime dtCreated = DateTime.now();
    if (json['created_at'] != null) {
      final c = json['created_at'];
      if (c is int) {
        dtCreated = DateTime.fromMillisecondsSinceEpoch(c > 1e11 ? c : c * 1000);
      } else if (c is String) {
        dtCreated = DateTime.tryParse(c) ?? DateTime.now();
      }
    }

    return Conversation(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      accountId: json['account_id'] is int ? json['account_id'] : int.tryParse(json['account_id'].toString()) ?? 0,
      inboxId: json['inbox_id'] is int ? json['inbox_id'] : int.tryParse(json['inbox_id'].toString()) ?? 0,
      status: json['status'] ?? 'open',
      unreadCount: json['unread_count'] is int ? json['unread_count'] : 0,
      priority: json['priority'],
      channel: ch,
      contact: parsedContact,
      lastMessage: lastMsg,
      assignee: parsedAssignee,
      team: parsedTeam,
      labels: labelsList,
      lifecycleStage: stage,
      updatedAt: dtUpdated,
      createdAt: dtCreated,
    );
  }
}
