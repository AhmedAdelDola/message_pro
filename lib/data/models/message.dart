import 'dart:convert';
import 'message_template.dart';
import 'message_template_registry.dart';

class MessageAttachment {
  final int? id;
  final String fileType; // 'image', 'audio', 'video', 'file'
  final String dataUrl;
  final String? thumbUrl;
  final int? fileSize;
  final String? fileName;

  MessageAttachment({
    this.id,
    required this.fileType,
    required this.dataUrl,
    this.thumbUrl,
    this.fileSize,
    this.fileName,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'],
      fileType: json['file_type'] ?? 'file',
      dataUrl: json['data_url'] ?? '',
      thumbUrl: json['thumb_url'],
      fileSize: json['file_size'],
      fileName: json['file_name'] ?? json['filename'] ?? json['name'] ?? json['title'],
    );
  }
}

class MessageReferral {
  final String? headline;
  final String? body;
  final String? sourceType;
  final String? sourceUrl;
  final String? sourceId;
  final String? imageUrl;
  final String? videoUrl;
  final String? mediaType;
  final String? platform;
  final String? ctwaClid;

  MessageReferral({
    this.headline,
    this.body,
    this.sourceType,
    this.sourceUrl,
    this.sourceId,
    this.imageUrl,
    this.videoUrl,
    this.mediaType,
    this.platform,
    this.ctwaClid,
  });

  bool get hasContent =>
      (headline != null && headline!.trim().isNotEmpty) ||
      (body != null && body!.trim().isNotEmpty) ||
      (sourceUrl != null && sourceUrl!.trim().isNotEmpty) ||
      (imageUrl != null && imageUrl!.trim().isNotEmpty) ||
      (videoUrl != null && videoUrl!.trim().isNotEmpty) ||
      (sourceId != null && sourceId!.trim().isNotEmpty);

  factory MessageReferral.fromJson(Map<String, dynamic> json) {
    return MessageReferral(
      headline: (json['headline'] ?? json['title'] ?? json['header'] ?? json['name'])?.toString(),
      body: (json['body'] ?? json['description'] ?? json['text'] ?? json['caption'] ?? json['ad_body'])?.toString(),
      sourceType: (json['source_type'] ?? json['sourceType'] ?? json['type'])?.toString(),
      sourceUrl: (json['source_url'] ?? json['sourceUrl'] ?? json['url'] ?? json['link'] ?? json['ad_url'])?.toString(),
      sourceId: (json['source_id'] ?? json['sourceId'] ?? json['ad_id'] ?? json['id'])?.toString(),
      imageUrl: (json['thumbnail_url'] ??
              json['image_url'] ??
              json['imageUrl'] ??
              json['thumbnailUrl'] ??
              json['media_url'] ??
              json['mediaUrl'] ??
              json['picture'] ??
              json['preview_url'])
          ?.toString(),
      videoUrl: (json['video_url'] ?? json['videoUrl'])?.toString(),
      mediaType: (json['media_type'] ?? json['mediaType'])?.toString(),
      platform: json['platform']?.toString(),
      ctwaClid: (json['ctwa_clid'] ?? json['ctwaClid'])?.toString(),
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
  final Map<String, dynamic> contentAttributes;
  final Map<String, dynamic> additionalAttributes;
  final MessageReferral? referral;

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
    this.contentAttributes = const {},
    this.additionalAttributes = const {},
    this.referral,
  });

  Message copyWith({
    int? id,
    String? content,
    int? conversationId,
    int? inboxId,
    int? messageType,
    String? contentType,
    bool? private,
    String? status,
    DateTime? createdAt,
    String? senderName,
    String? senderAvatar,
    List<MessageAttachment>? attachments,
    Map<String, dynamic>? contentAttributes,
    Map<String, dynamic>? additionalAttributes,
    MessageReferral? referral,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      conversationId: conversationId ?? this.conversationId,
      inboxId: inboxId ?? this.inboxId,
      messageType: messageType ?? this.messageType,
      contentType: contentType ?? this.contentType,
      private: private ?? this.private,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      attachments: attachments ?? this.attachments,
      contentAttributes: contentAttributes ?? this.contentAttributes,
      additionalAttributes: additionalAttributes ?? this.additionalAttributes,
      referral: referral ?? this.referral,
    );
  }

  bool get isIncoming => messageType == 0 && !isActivity;
  bool get isOutgoing => messageType == 1;
  bool get isActivity =>
      messageType == 2 ||
      (content != null &&
          (content!.toLowerCase().contains('workflow') ||
           content!.toLowerCase().contains('assigned to') ||
           content!.toLowerCase().contains('contact assigned') ||
           content!.toLowerCase().contains('conversation was') ||
           content!.toLowerCase().contains('priority changed') ||
           content!.toLowerCase().contains('automation') ||
           content!.toLowerCase().contains('system:')));
  bool get isPrivateNote => private;
  bool get isTemplate =>
      messageType == 3 ||
      contentType == 'template' ||
      contentAttributes['template_params'] != null ||
      additionalAttributes['template_params'] != null ||
      contentAttributes['type'] == 'template' ||
      templateName != null;

  bool get isSent => status == 'sent';
  bool get isDelivered => status == 'delivered';
  bool get isRead => status == 'read' || status == 'seen';
  bool get isFailed => status == 'failed';

  String? get failureReason {
    if (!isFailed) return null;
    final err = contentAttributes['external_error'] ??
        contentAttributes['error'] ??
        additionalAttributes['error'];
    if (err is Map) {
      return err['message']?.toString() ?? err.toString();
    }
    if (err != null && err.toString().trim().isNotEmpty) {
      return err.toString();
    }
    return null;
  }

  String? get templateName {
    final t1 = contentAttributes['template_params'];
    if (t1 is Map && t1['name'] != null) return t1['name'].toString();
    final t2 = additionalAttributes['template_params'];
    if (t2 is Map && t2['name'] != null) return t2['name'].toString();
    if (contentAttributes['template_name'] != null) return contentAttributes['template_name'].toString();
    if (additionalAttributes['template_name'] != null) return additionalAttributes['template_name'].toString();
    if (contentAttributes['name'] != null) return contentAttributes['name'].toString();
    final match = MessageTemplateRegistry.findByContent(content);
    if (match != null) return match.name;
    return null;
  }

  List<TemplateButton> get templateActionButtons {
    final rawBtns = contentAttributes['buttons'] ??
        contentAttributes['interactive']?['action']?['buttons'] ??
        additionalAttributes['interactive']?['action']?['buttons'] ??
        contentAttributes['items'];
    final rawList = rawBtns is List ? rawBtns : null;

    return MessageTemplateRegistry.getButtonsForMessage(
      templateName: templateName,
      content: content,
      rawButtons: rawList,
    );
  }

  List<String> get templateButtons =>
      templateActionButtons.map((b) => b.text).toList();

  factory Message.fromJson(Map<String, dynamic> json) {
    final rawSender = json['sender'];
    String? sName;
    String? sAvatar;
    if (rawSender is Map) {
      sName = rawSender['name']?.toString();
      sAvatar = (rawSender['avatar_url'] ?? rawSender['thumbnail'])?.toString();
    }

    final rawAttachments = json['attachments'];
    final attList = <MessageAttachment>[];
    if (rawAttachments is List) {
      for (final a in rawAttachments) {
        if (a is Map) {
          attList.add(MessageAttachment.fromJson(Map<String, dynamic>.from(a)));
        }
      }
    }

    DateTime dt = DateTime.fromMillisecondsSinceEpoch(0);
    if (json['created_at'] != null) {
      if (json['created_at'] is num) {
        final val = (json['created_at'] as num).toInt();
        dt = DateTime.fromMillisecondsSinceEpoch(val > 1e11 ? val : val * 1000);
      } else if (json['created_at'] is String) {
        dt = DateTime.tryParse(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
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

    final cAttr = json['content_attributes'] is Map
        ? Map<String, dynamic>.from(json['content_attributes'])
        : <String, dynamic>{};
    final aAttr = json['additional_attributes'] is Map
        ? Map<String, dynamic>.from(json['additional_attributes'])
        : <String, dynamic>{};

    final rawStatus = json['status'];
    String parsedStatus = 'sent';
    if (rawStatus is String) {
      final s = rawStatus.toLowerCase().trim();
      if (s == 'read' || s == 'seen') {
        parsedStatus = 'read';
      } else if (s == 'delivered') {
        parsedStatus = 'delivered';
      } else if (s == 'failed' || s == 'error') {
        parsedStatus = 'failed';
      } else if (s == 'sent' || s == 'progress') {
        parsedStatus = 'sent';
      }
    } else if (rawStatus is int) {
      // Chatwoot status enum: 0 = sent, 1 = delivered, 2 = read, 3 = failed
      if (rawStatus == 2) {
        parsedStatus = 'read';
      } else if (rawStatus == 1) {
        parsedStatus = 'delivered';
      } else if (rawStatus == 3) {
        parsedStatus = 'failed';
      } else {
        parsedStatus = 'sent';
      }
    }

    if (cAttr['external_error'] != null || cAttr['error'] != null || aAttr['error'] != null) {
      parsedStatus = 'failed';
    } else if (cAttr['delivery_status'] != null) {
      final ds = cAttr['delivery_status'].toString().toLowerCase().trim();
      if (ds == 'read' || ds == 'seen') {
        parsedStatus = 'read';
      } else if (ds == 'delivered') {
        parsedStatus = 'delivered';
      } else if (ds == 'failed') {
        parsedStatus = 'failed';
      }
    } else if (cAttr['seen'] == true || cAttr['read_at'] != null) {
      parsedStatus = 'read';
    }

    dynamic findReferralMap(dynamic obj) {
      if (obj == null) return null;
      if (obj is String && obj.trim().startsWith('{')) {
        try {
          final decoded = jsonDecode(obj);
          final res = findReferralMap(decoded);
          if (res != null) return res;
        } catch (_) {}
      }
      if (obj is Map) {
        if (obj['ad_referral'] != null) return findReferralMap(obj['ad_referral']);
        if (obj['referral'] != null) return findReferralMap(obj['referral']);
        if (obj['referral_params'] != null) return findReferralMap(obj['referral_params']);
        if (obj['source_id'] != null || obj['headline'] != null || obj['ctwa_clid'] != null || obj['source_url'] != null) {
          return obj;
        }
        for (final entry in obj.entries) {
          final res = findReferralMap(entry.value);
          if (res != null) return res;
        }
      }
      return null;
    }

    MessageReferral? ref;
    final rawRef = findReferralMap(cAttr) ??
        findReferralMap(aAttr) ??
        findReferralMap(json['meta']) ??
        findReferralMap(json);

    if (rawRef is Map) {
      try {
        final parsedRef = MessageReferral.fromJson(Map<String, dynamic>.from(rawRef));
        if (parsedRef.hasContent) {
          ref = parsedRef;
        }
      } catch (_) {}
    }

    return Message(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      content: json['content']?.toString(),
      conversationId: json['conversation_id'] is int
          ? json['conversation_id']
          : int.tryParse(json['conversation_id']?.toString() ?? ''),
      inboxId: json['inbox_id'] is int
          ? json['inbox_id']
          : int.tryParse(json['inbox_id']?.toString() ?? ''),
      messageType: msgType,
      contentType: json['content_type']?.toString() ?? 'text',
      private: json['private'] == true,
      status: parsedStatus,
      createdAt: dt,
      senderName: sName,
      senderAvatar: sAvatar,
      attachments: attList,
      contentAttributes: cAttr,
      additionalAttributes: aAttr,
      referral: ref,
    );
  }
}
