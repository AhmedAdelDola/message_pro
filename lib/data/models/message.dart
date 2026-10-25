class MessageAttachment {
  final int? id;
  final String fileType; // 'image', 'audio', 'video', 'file'
  final String dataUrl;
  final String? thumbUrl;
  final int? fileSize;

  MessageAttachment({
    this.id,
    required this.fileType,
    required this.dataUrl,
    this.thumbUrl,
    this.fileSize,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'],
      fileType: json['file_type'] ?? 'file',
      dataUrl: json['data_url'] ?? '',
      thumbUrl: json['thumb_url'],
      fileSize: json['file_size'],
    );
  }
}

class Message {
  final int id;
  final String? content;
  final int? conversationId;
  final int? inboxId;
  final int messageType; // 0 = incoming, 1 = outgoing, 2 = activity, 3 = template
  final String contentType;
  final bool private; // Internal note
  final String status; // sent, delivered, read, failed
  final DateTime createdAt;
  final String? senderName;
  final String? senderAvatar;
  final List<MessageAttachment> attachments;

  Message({
    required this.id,
    this.content,
    this.conversationId,
    this.inboxId,
    required this.messageType,
    this.contentType = 'text',
    this.private = false,
    this.status = 'sent',
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
    this.attachments = const [],
  });

  bool get isIncoming => messageType == 0;
  bool get isOutgoing => messageType == 1;
  bool get isActivity => messageType == 2;
  bool get isPrivateNote => private;

  factory Message.fromJson(Map<String, dynamic> json) {
    final rawSender = json['sender'];
    String? sName;
    String? sAvatar;
    if (rawSender is Map<String, dynamic>) {
      sName = rawSender['name'];
      sAvatar = rawSender['avatar_url'] ?? rawSender['thumbnail'];
    }

    final rawAttachments = json['attachments'];
    final attList = <MessageAttachment>[];
    if (rawAttachments is List) {
      for (final a in rawAttachments) {
        if (a is Map<String, dynamic>) {
          attList.add(MessageAttachment.fromJson(a));
        }
      }
    }

    DateTime dt = DateTime.now();
    if (json['created_at'] != null) {
      if (json['created_at'] is int) {
        final val = json['created_at'] as int;
        dt = DateTime.fromMillisecondsSinceEpoch(val > 1e11 ? val : val * 1000);
      } else if (json['created_at'] is String) {
        dt = DateTime.tryParse(json['created_at']) ?? DateTime.now();
      }
    }

    final msgTypeRaw = json['message_type'];
    int msgType = 0;
    if (msgTypeRaw is int) {
      msgType = msgTypeRaw;
    } else if (msgTypeRaw is String) {
      if (msgTypeRaw == 'outgoing') {
        msgType = 1;
      } else if (msgTypeRaw == 'activity') {
        msgType = 2;
      } else if (msgTypeRaw == 'template') {
        msgType = 3;
      } else {
        msgType = 0;
      }
    }

    return Message(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      content: json['content'],
      conversationId: json['conversation_id'],
      inboxId: json['inbox_id'],
      messageType: msgType,
      contentType: json['content_type'] ?? 'text',
      private: json['private'] == true,
      status: json['status'] ?? 'sent',
      createdAt: dt,
      senderName: sName,
      senderAvatar: sAvatar,
      attachments: attList,
    );
  }
}
