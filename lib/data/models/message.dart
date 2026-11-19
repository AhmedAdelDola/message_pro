import 'dart:convert';
import '../../core/config/app_config.dart';
import 'message_template.dart';
import 'message_template_registry.dart';
import 'user.dart';

class MessageAttachment {
  final int? id;
  final String fileType; // 'image', 'audio', 'video', 'file'
  final String dataUrl;
  final String? thumbUrl;
  final int? fileSize;
  final String? fileName;
  final double? duration;
  final String? transcribedText;

  MessageAttachment({
    this.id,
    required this.fileType,
    required this.dataUrl,
    this.thumbUrl,
    this.fileSize,
    this.fileName,
    this.duration,
    this.transcribedText,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    final rawDuration = json['duration'] ??
        json['metadata']?['duration'] ??
        json['metadata']?['duration_seconds'] ??
        json['metadata']?['audio_duration'] ??
        json['metadata']?['voice_duration'] ??
        json['file_metadata']?['duration'] ??
        json['file_metadata']?['data']?['duration'];

    double? parsedDuration;
    if (rawDuration is num) {
      final val = rawDuration.toDouble();
      parsedDuration = val > 1000 ? (val / 1000.0) : val;
    } else if (rawDuration is String) {
      final val = double.tryParse(rawDuration);
      if (val != null) {
        parsedDuration = val > 1000 ? (val / 1000.0) : val;
      }
    }

    final transcript = json['transcribed_text'] ??
        json['metadata']?['transcribed_text'] ??
        json['transcription'];

    var dataUrl = (json['data_url'] ?? json['file_url'] ?? json['url'])?.toString() ?? '';
    if (dataUrl.isNotEmpty && dataUrl.startsWith('/')) {
      dataUrl = '${AppConfig.defaultBaseUrl}$dataUrl';
    }

    var thumbUrl = (json['thumb_url'] ?? json['thumbnail_url'])?.toString();
    if (thumbUrl != null && thumbUrl.isNotEmpty && thumbUrl.startsWith('/')) {
      thumbUrl = '${AppConfig.defaultBaseUrl}$thumbUrl';
    }

    return MessageAttachment(
      id: json['id'],
      fileType: json['file_type'] ?? 'file',
      dataUrl: dataUrl,
      thumbUrl: thumbUrl,
      fileSize: json['file_size'],
      fileName: json['file_name'] ?? json['filename'] ?? json['name'] ?? json['title'],
      duration: parsedDuration,
      transcribedText: transcript?.toString(),
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
      (sourceUrl != null && sourceUrl!.trim().isNotEmpty) ||
      (imageUrl != null && imageUrl!.trim().isNotEmpty) ||
      (videoUrl != null && videoUrl!.trim().isNotEmpty) ||
      (ctwaClid != null && ctwaClid!.trim().isNotEmpty);

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

class MessageActions {
  final bool canEdit;
  final int? editUntil; // Unix timestamp in seconds
  final bool canReact;

  const MessageActions({
    this.canEdit = false,
    this.editUntil,
    this.canReact = false,
  });

  bool get isEditExpired {
    if (editUntil == null) return false;
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return nowSec > editUntil!;
  }

  Duration? get remainingEditTime {
    if (editUntil == null) return null;
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = editUntil! - nowSec;
    return diff > 0 ? Duration(seconds: diff) : Duration.zero;
  }

  factory MessageActions.fromJson(Map<String, dynamic> json) {
    return MessageActions(
      canEdit: json['edit'] == true,
      editUntil: json['edit_until'] is num
          ? (json['edit_until'] as num).toInt()
          : int.tryParse(json['edit_until']?.toString() ?? ''),
      canReact: json['react'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'edit': canEdit,
    if (editUntil != null) 'edit_until': editUntil,
    'react': canReact,
  };
}

class MessageReaction {
  final String emoji;
  final String? actor; // e.g. "Channel::Whatsapp:1" or "User:12"
  final int? userId;
  final String? userName;

  const MessageReaction({
    required this.emoji,
    this.actor,
    this.userId,
    this.userName,
  });

  factory MessageReaction.fromJson(dynamic json) {
    if (json is String) {
      return MessageReaction(emoji: json);
    }
    if (json is Map) {
      return MessageReaction(
        emoji: json['emoji']?.toString() ?? '',
        actor: json['actor']?.toString() ?? json['channel']?.toString(),
        userId: json['user_id'] is int
            ? json['user_id']
            : int.tryParse(json['user_id']?.toString() ?? ''),
        userName: json['user']?['name']?.toString() ?? json['user_name']?.toString(),
      );
    }
    return const MessageReaction(emoji: '');
  }

  Map<String, dynamic> toJson() => {
    'emoji': emoji,
    if (actor != null) 'actor': actor,
    if (userId != null) 'user_id': userId,
    if (userName != null) 'user_name': userName,
  };
}

class ReactionParticipant {
  final int? id;
  final String name;
  final String? avatarUrl;
  final String? type; // "user", "contact", "channel"
  final String? actor;
  final String? emoji;

  const ReactionParticipant({
    this.id,
    required this.name,
    this.avatarUrl,
    this.type,
    this.actor,
    this.emoji,
  });

  factory ReactionParticipant.fromJson(Map<String, dynamic> json, {String? emoji}) {
    return ReactionParticipant(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString() ?? json['display_name']?.toString() ?? 'مستخدم',
      avatarUrl: (json['avatar_url'] ?? json['thumbnail'])?.toString(),
      type: json['type']?.toString(),
      actor: json['actor']?.toString(),
      emoji: emoji ?? json['emoji']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    if (type != null) 'type': type,
    if (actor != null) 'actor': actor,
    if (emoji != null) 'emoji': emoji,
  };
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
  final DateTime? updatedAt;
  final String? senderName;
  final String? senderAvatar;
  final String? senderType; // 'User', 'AgentBot', 'Contact'
  final List<MessageAttachment> attachments;
  final Map<String, dynamic> contentAttributes;
  final Map<String, dynamic> additionalAttributes;
  final MessageReferral? referral;
  final MessageActions messageActions;
  final List<MessageReaction> reactions;

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
    this.updatedAt,
    this.senderName,
    this.senderAvatar,
    this.senderType,
    this.attachments = const [],
    this.contentAttributes = const {},
    this.additionalAttributes = const {},
    this.referral,
    this.messageActions = const MessageActions(),
    this.reactions = const [],
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
    DateTime? updatedAt,
    String? senderName,
    String? senderAvatar,
    String? senderType,
    List<MessageAttachment>? attachments,
    Map<String, dynamic>? contentAttributes,
    Map<String, dynamic>? additionalAttributes,
    MessageReferral? referral,
    MessageActions? messageActions,
    List<MessageReaction>? reactions,
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
      updatedAt: updatedAt ?? this.updatedAt,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      senderType: senderType ?? this.senderType,
      attachments: attachments ?? this.attachments,
      contentAttributes: contentAttributes ?? this.contentAttributes,
      additionalAttributes: additionalAttributes ?? this.additionalAttributes,
      referral: referral ?? this.referral,
      messageActions: messageActions ?? this.messageActions,
      reactions: reactions ?? this.reactions,
    );
  }

  bool get isPrivateNote => private;
  bool get isIncoming => messageType == 0 && !isPrivateNote && !isActivity;
  bool get isOutgoing => messageType == 1 && !isPrivateNote && !isActivity;
  bool get isActivity {
    // A private note or a direct chat message (incoming/outgoing/template) is NEVER an activity
    if (private) return false;
    if (messageType == 2) return true;
    if (messageType == 0 || messageType == 1 || messageType == 3) return false;

    // Fallback ONLY when messageType is ambiguous (not standard 0, 1, 2, or 3)
    if (content != null && content!.trim().isNotEmpty) {
      final lower = content!.trim().toLowerCase();
      return lower.startsWith('system:') ||
          lower.startsWith('workflow "') ||
          lower.startsWith('conversation was assigned to') ||
          lower.startsWith('contact assigned to');
    }
    return false;
  }
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
  bool get isSending => status == 'sending' || (id < 0 && status != 'failed');

  bool get isBot {
    final st = senderType?.toLowerCase();
    if (st == 'agentbot' || st == 'agent_bot' || st == 'bot') return true;
    final nameLower = (senderName ?? '').toLowerCase().trim();
    if (nameLower.contains('automation') ||
        nameLower.contains('bot') ||
        nameLower.contains('system') ||
        nameLower.contains('sales agent') ||
        nameLower.contains('ai agent')) {
      return true;
    }
    if (contentAttributes['automation'] != null ||
        additionalAttributes['automation'] != null ||
        contentAttributes['ai_agent'] == true ||
        additionalAttributes['ai_agent'] == true) {
      return true;
    }
    return false;
  }

  bool get isSentByAgent {
    if (isBot) return false;
    final st = senderType?.toLowerCase();
    if (st == 'user') return true;
    if (senderAvatar != null && senderAvatar!.isNotEmpty) return true;
    if (senderName != null && senderName!.trim().isNotEmpty) {
      final n = senderName!.toLowerCase().trim();
      if (n == 'whatsapp' ||
          n == 'messenger' ||
          n == 'facebook' ||
          n == 'instagram' ||
          n == 'telegram' ||
          n == 'system' ||
          n == 'platform') {
        return false;
      }
      return true;
    }
    return false;
  }

  bool get isSentFromPlatform {
    if (isBot) return false;
    if (isSentByAgent) return false;
    return true;
  }

  bool canEditBy(User? currentUser) {
    if (!messageActions.canEdit) return false;
    if (messageActions.isEditExpired) return false;
    if (!isOutgoing) return false;
    if (attachments.isNotEmpty) return false;
    if (currentUser == null) return true;
    if (currentUser.isAdmin) return true;
    if (senderName != null &&
        senderName!.trim().toLowerCase() == currentUser.name.trim().toLowerCase()) {
      return true;
    }
    if (isSentByAgent) return true;
    return false;
  }

  bool get canReact => messageActions.canReact;

  bool get isEdited {
    if (contentAttributes['is_edited'] == true ||
        contentAttributes['edited'] == true ||
        additionalAttributes['is_edited'] == true ||
        contentAttributes['edit_history'] != null) {
      return true;
    }
    if (updatedAt != null && updatedAt!.isAfter(createdAt.add(const Duration(seconds: 2)))) {
      return true;
    }
    return false;
  }

  Map<String, int> get reactionsSummary {
    final map = <String, int>{};
    for (final r in reactions) {
      if (r.emoji.isNotEmpty) {
        map[r.emoji] = (map[r.emoji] ?? 0) + 1;
      }
    }
    return map;
  }

  List<String> get uniqueReactionEmojis => reactionsSummary.keys.toList();

  int? get inReplyToId {
    final raw = contentAttributes['in_reply_to'] ??
        additionalAttributes['in_reply_to'] ??
        contentAttributes['in_reply_to_external_id'] ??
        additionalAttributes['in_reply_to_external_id'];
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    if (raw is Map) {
      final id = raw['id'];
      if (id is int) return id;
      if (id is String) return int.tryParse(id);
    }
    return null;
  }

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
    String? sType;
    if (rawSender is Map) {
      sName = rawSender['name']?.toString();
      sAvatar = (rawSender['avatar_url'] ?? rawSender['thumbnail'])?.toString();
      sType = rawSender['type']?.toString();
    }
    sType ??= json['sender_type']?.toString();

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

    DateTime? updatedDt;
    if (json['updated_at'] != null) {
      if (json['updated_at'] is num) {
        final val = (json['updated_at'] as num).toInt();
        updatedDt = DateTime.fromMillisecondsSinceEpoch(val > 1e11 ? val : val * 1000);
      } else if (json['updated_at'] is String) {
        updatedDt = DateTime.tryParse(json['updated_at']);
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

    MessageReferral? ref;
    final wa = cAttr['whatsapp'];
    dynamic rawRef;
    if (wa is Map) {
      rawRef = wa['ad_referral'] ?? wa['referral'];
    }
    rawRef ??= cAttr['ad_referral'] ??
        cAttr['referral'] ??
        cAttr['referral_params'] ??
        aAttr['ad_referral'] ??
        aAttr['referral'];

    if (rawRef is String && rawRef.trim().startsWith('{')) {
      try {
        rawRef = jsonDecode(rawRef);
      } catch (_) {}
    }
    if (rawRef is Map) {
      try {
        final parsedRef = MessageReferral.fromJson(Map<String, dynamic>.from(rawRef));
        if (parsedRef.hasContent) {
          ref = parsedRef;
        }
      } catch (_) {}
    }

    final rawActions = json['message_actions'] ?? cAttr['message_actions'];
    final actions = rawActions is Map
        ? MessageActions.fromJson(Map<String, dynamic>.from(rawActions))
        : const MessageActions();

    final rawReactions = json['reactions'] ?? cAttr['reactions'];
    final parsedReactions = <MessageReaction>[];
    if (rawReactions is List) {
      for (final r in rawReactions) {
        parsedReactions.add(MessageReaction.fromJson(r));
      }
    } else if (rawReactions is Map) {
      if (rawReactions['emoji'] != null) {
        parsedReactions.add(MessageReaction.fromJson(rawReactions));
      } else {
        rawReactions.forEach((key, val) {
          if (val is String && val.isNotEmpty) {
            parsedReactions.add(MessageReaction(emoji: val, actor: key));
          } else if (val is Map) {
            parsedReactions.add(MessageReaction.fromJson(val));
          }
        });
      }
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
      updatedAt: updatedDt,
      senderName: sName,
      senderAvatar: sAvatar,
      senderType: sType,
      attachments: attList,
      contentAttributes: cAttr,
      additionalAttributes: aAttr,
      referral: ref,
      messageActions: actions,
      reactions: parsedReactions,
    );
  }
}
