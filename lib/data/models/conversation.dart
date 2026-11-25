import 'dart:convert';
import 'contact.dart';
import 'message.dart';
import 'user.dart';

class Conversation {
  final int id;
  final int? recordId;
  final int accountId;
  final int inboxId;
  final String? inboxName;
  final Inbox? inbox;
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
  final bool canReply;
  final DateTime? snoozedUntil;
  final DateTime? contactLastSeenAt;
  final String? replyBlockReason;
  final bool muted;
  final bool isPinned;
  final Map<String, dynamic> customAttributes;
  final Map<String, dynamic> additionalAttributes;
  final MessageReferral? referral;

  bool get isAiAgentHandling {
    if (status.toLowerCase() == 'bot') return true;
    if (assignee != null && assignee!.isBot) return true;
    final ca = customAttributes;
    final aa = additionalAttributes;
    if (ca['ai_agent'] == true ||
        ca['bot'] == true ||
        ca['ai_active'] == true ||
        aa['ai_agent'] == true ||
        aa['bot'] == true ||
        ca['handling_agent_type'] == 'bot' ||
        aa['handling_agent_type'] == 'bot') {
      return true;
    }
    return false;
  }

  LifecycleStage? get effectiveLifecycleStage {
    if (lifecycleStage != null) return lifecycleStage;
    if (contact.lifecycleStage != null) return contact.lifecycleStage;
    final ca = customAttributes;
    final raw = ca['lifecycle_stage'] ??
        ca['lead_status'] ??
        contact.customAttributes['lifecycle_stage'] ??
        contact.customAttributes['lead_status'];
    if (raw is Map) {
      try {
        return LifecycleStage.fromJson(Map<String, dynamic>.from(raw));
      } catch (_) {}
    } else if (raw is String && raw.trim().isNotEmpty) {
      return LifecycleStage.fromString(raw);
    }
    return null;
  }

  String get channelType {
    if (inbox != null && inbox!.channelType.isNotEmpty && inbox!.channelType != 'Channel::WebWidget') {
      return inbox!.channelType;
    }
    if (channel.isNotEmpty && channel != 'web') {
      return channel;
    }
    return inbox?.channelType ?? channel;
  }

  Conversation({
    required this.id,
    this.recordId,
    required this.accountId,
    required this.inboxId,
    this.inboxName,
    this.inbox,
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
    this.canReply = true,
    this.snoozedUntil,
    this.contactLastSeenAt,
    this.replyBlockReason,
    this.muted = false,
    this.isPinned = false,
    this.customAttributes = const {},
    this.additionalAttributes = const {},
    this.referral,
  });

  Conversation copyWith({
    int? id,
    int? recordId,
    int? accountId,
    int? inboxId,
    String? inboxName,
    Inbox? inbox,
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
    bool? canReply,
    DateTime? snoozedUntil,
    DateTime? contactLastSeenAt,
    String? replyBlockReason,
    bool? muted,
    bool? isPinned,
    Map<String, dynamic>? customAttributes,
    Map<String, dynamic>? additionalAttributes,
    MessageReferral? referral,
  }) {
    return Conversation(
      id: id ?? this.id,
      recordId: recordId ?? this.recordId,
      accountId: accountId ?? this.accountId,
      inboxId: inboxId ?? this.inboxId,
      inboxName: inboxName ?? this.inboxName,
      inbox: inbox ?? this.inbox,
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
      canReply: canReply ?? this.canReply,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      contactLastSeenAt: contactLastSeenAt ?? this.contactLastSeenAt,
      replyBlockReason: replyBlockReason ?? this.replyBlockReason,
      muted: muted ?? this.muted,
      isPinned: isPinned ?? this.isPinned,
      customAttributes: customAttributes ?? this.customAttributes,
      additionalAttributes: additionalAttributes ?? this.additionalAttributes,
      referral: referral ?? this.referral,
    );
  }

  String get displayContactName {
    final cName = contact.displayNameOrPhone;
    final lower = cName.toLowerCase();
    final isGeneric = lower.isEmpty ||
        lower == 'customer' ||
        lower == 'عميل' ||
        lower == 'عميل جديد' ||
        lower == 'new visitor' ||
        lower == 'null' ||
        lower.startsWith('عميل #') ||
        lower.startsWith('contact #');

    if (isGeneric) {
      final addPhone = (additionalAttributes['sender_phone_number'] ??
              additionalAttributes['phone_number'] ??
              additionalAttributes['wa_id'])
          ?.toString()
          .trim();
      if (addPhone != null && addPhone.isNotEmpty) {
        return addPhone;
      }
    }
    return cName;
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ??
        json['conversation_id'] ??
        json['display_id'] ??
        (json['conversation'] is Map ? (json['conversation']['id'] ?? json['conversation']['conversation_id'] ?? json['conversation']['display_id']) : null);
    final int convId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    // Contact extraction (Check all possible Chatwoot sender/contact locations)
    final convObj = json['conversation'] is Map ? json['conversation'] as Map : null;
    final dynamic rawContactData = json['meta']?['sender'] ??
        convObj?['meta']?['sender'] ??
        json['contact_inbox']?['contact'] ??
        convObj?['contact_inbox']?['contact'] ??
        json['contact'] ??
        convObj?['contact'] ??
        json['sender'] ??
        convObj?['sender'];

    Contact parsedContact;
    if (rawContactData is Map) {
      parsedContact = Contact.fromJson(Map<String, dynamic>.from(rawContactData));
    } else {
      parsedContact = Contact(
        id: 0,
        name: convId > 0 ? 'عميل #$convId' : 'عميل جديد',
      );
    }

    // Fallback phone resolution from additional_attributes / source_id
    final addAttrs = (json['additional_attributes'] is Map ? json['additional_attributes'] as Map : null) ??
        (convObj?['additional_attributes'] is Map ? convObj!['additional_attributes'] as Map : null);

    final rawFallbackPhone = (addAttrs?['sender_phone_number'] ??
        addAttrs?['phone_number'] ??
        addAttrs?['wa_id'] ??
        json['source_id'] ??
        convObj?['source_id'] ??
        json['contact_inbox']?['source_id'] ??
        convObj?['contact_inbox']?['source_id'])?.toString().trim();

    if (rawFallbackPhone != null && rawFallbackPhone.isNotEmpty) {
      if (parsedContact.phoneNumber == null || parsedContact.phoneNumber!.isEmpty) {
        parsedContact = parsedContact.copyWith(phoneNumber: rawFallbackPhone);
      }
      final lowerName = parsedContact.name.toLowerCase();
      final isGeneric = lowerName.isEmpty ||
          lowerName == 'customer' ||
          lowerName == 'عميل' ||
          lowerName == 'عميل جديد' ||
          lowerName == 'null' ||
          lowerName.startsWith('عميل #') ||
          lowerName.startsWith('contact #');
      if (isGeneric) {
        parsedContact = parsedContact.copyWith(name: rawFallbackPhone);
      }
    }

    // Last message
    Message? lastMsg;
    dynamic rawLast = json['last_non_activity_message'];
    if (rawLast == null && json['messages'] is List && (json['messages'] as List).isNotEmpty) {
      rawLast = (json['messages'] as List).last;
    }
    if (rawLast is Map) {
      try {
        lastMsg = Message.fromJson(Map<String, dynamic>.from(rawLast));
      } catch (_) {}
    }

    // Assignee
    User? parsedAssignee;
    final rawAssignee = json['meta']?['assignee'] ?? json['assignee'];
    if (rawAssignee is Map) {
      try {
        final map = Map<String, dynamic>.from(rawAssignee);
        if (json['meta']?['assignee_type'] != null && map['assignee_type'] == null) {
          map['assignee_type'] = json['meta']['assignee_type'];
        }
        parsedAssignee = User.fromJson(map);
      } catch (_) {}
    }

    // Team
    Team? parsedTeam;
    final rawTeam = json['meta']?['team'] ?? json['team'];
    if (rawTeam is Map) {
      try {
        parsedTeam = Team.fromJson(Map<String, dynamic>.from(rawTeam));
      } catch (_) {}
    }

    // Inbox parsing
    Inbox? parsedInbox;
    final rawInbox = json['inbox'];
    if (rawInbox is Map) {
      try {
        parsedInbox = Inbox.fromJson(Map<String, dynamic>.from(rawInbox));
      } catch (_) {}
    }

    // Channel detection
    String ch = 'web';
    final rawChannel = json['meta']?['channel'] ??
        json['channel'] ??
        json['channel_type'] ??
        (parsedInbox != null && parsedInbox.channelType.isNotEmpty && parsedInbox.channelType != 'Channel::WebWidget' ? parsedInbox.channelType : null) ??
        json['inbox']?['channel_type'] ??
        parsedInbox?.channelType;
    if (rawChannel is String) {
      final lower = rawChannel.toLowerCase();
      if (lower.contains('whatsapp')) {
        ch = 'whatsapp';
      } else if (lower.contains('instagram')) {
        ch = 'instagram';
      } else if (lower.contains('facebook') || lower.contains('messenger')) {
        ch = 'facebook';
      } else if (lower.contains('email')) {
        ch = 'email';
      } else if (lower.contains('telegram')) {
        ch = 'telegram';
      } else if (lower.contains('sms')) {
        ch = 'sms';
      } else if (lower.contains('api')) {
        ch = 'api';
      } else if (lower.contains('line')) {
        ch = 'line';
      } else if (lower.contains('web') || lower.contains('widget')) {
        ch = 'web';
      }
    }

    if (ch == 'web') {
      final cPhone = parsedContact.phoneNumber ?? '';
      final cName = parsedContact.name.toLowerCase();
      final inbName = (parsedInbox?.name ?? json['inbox']?['name']?.toString() ?? json['meta']?['inbox']?['name']?.toString() ?? '').toLowerCase();
      if (cPhone.isNotEmpty || cName.contains('@c.us') || inbName.contains('whatsapp')) {
        ch = 'whatsapp';
      } else if (inbName.contains('instagram')) {
        ch = 'instagram';
      } else if (inbName.contains('facebook') || inbName.contains('messenger')) {
        ch = 'facebook';
      } else if (inbName.contains('email')) {
        ch = 'email';
      } else if (inbName.contains('telegram')) {
        ch = 'telegram';
      }
    }

    // Labels / Tags
    final labelsList = <String>[];
    final rawLabels = json['labels'] ??
        json['tags'] ??
        json['cached_labels'] ??
        json['applied_labels'] ??
        json['meta']?['labels'] ??
        json['meta']?['sender']?['labels'] ??
        json['contact']?['labels'];

    if (rawLabels is List) {
      for (final l in rawLabels) {
        if (l is String) {
          final s = l.trim();
          if (s.isNotEmpty && !labelsList.contains(s)) labelsList.add(s);
        } else if (l is Map) {
          final t = (l['title'] ?? l['name'] ?? l['label'] ?? l['id'])?.toString().trim();
          if (t != null && t.isNotEmpty && !labelsList.contains(t)) labelsList.add(t);
        }
      }
    } else if (rawLabels is String && rawLabels.trim().isNotEmpty) {
      for (final part in rawLabels.split(RegExp(r'[,;\n]'))) {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty && !labelsList.contains(trimmed)) labelsList.add(trimmed);
      }
    }

    // Also check custom_attributes for tag or labels
    final caTag = json['custom_attributes']?['tag'] ??
        json['custom_attributes']?['tags'] ??
        json['custom_attributes']?['labels'] ??
        json['meta']?['sender']?['custom_attributes']?['tag'] ??
        json['contact']?['custom_attributes']?['tag'];
    if (caTag is String && caTag.trim().isNotEmpty && !labelsList.contains(caTag.trim())) {
      labelsList.add(caTag.trim());
    } else if (caTag is List) {
      for (final item in caTag) {
        final s = item.toString().trim();
        if (s.isNotEmpty && !labelsList.contains(s)) labelsList.add(s);
      }
    }

    // Lifecycle stage
    LifecycleStage? stage;
    final rawStage = json['lifecycle_stage'] ??
        json['meta']?['sender']?['lifecycle_stage'] ??
        json['contact']?['lifecycle_stage'] ??
        json['custom_attributes']?['lifecycle_stage'] ??
        json['custom_attributes']?['lead_status'] ??
        json['meta']?['sender']?['custom_attributes']?['lifecycle_stage'] ??
        json['meta']?['sender']?['custom_attributes']?['lead_status'] ??
        json['contact']?['custom_attributes']?['lifecycle_stage'] ??
        json['contact']?['custom_attributes']?['lead_status'] ??
        json['meta']?['sender']?['stage'] ??
        json['contact']?['stage'];

    if (rawStage is Map) {
      try {
        stage = LifecycleStage.fromJson(Map<String, dynamic>.from(rawStage));
      } catch (_) {}
    } else if (rawStage is String && rawStage.trim().isNotEmpty) {
      stage = LifecycleStage.fromString(rawStage);
    }

    DateTime dtCreated = DateTime.fromMillisecondsSinceEpoch(0);
    final rawCreated = json['created_at'];
    if (rawCreated != null) {
      if (rawCreated is num) {
        final val = rawCreated.toInt();
        dtCreated = DateTime.fromMillisecondsSinceEpoch(val > 1e11 ? val : val * 1000);
      } else if (rawCreated is String) {
        dtCreated = DateTime.tryParse(rawCreated) ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    DateTime dtUpdated = dtCreated;
    final rawUpdated = json['last_activity_at'] ?? json['updated_at'] ?? json['timestamp'];
    if (rawUpdated != null) {
      if (rawUpdated is num) {
        final val = rawUpdated.toInt();
        dtUpdated = DateTime.fromMillisecondsSinceEpoch(val > 1e11 ? val : val * 1000);
      } else if (rawUpdated is String) {
        dtUpdated = DateTime.tryParse(rawUpdated) ?? dtCreated;
      }
    }

    final rawInboxId = json['inbox_id'] ?? json['inbox']?['id'];
    final int inbId = rawInboxId is int ? rawInboxId : int.tryParse(rawInboxId?.toString() ?? '') ?? 0;
    final String? inbName = json['inbox']?['name']?.toString() ?? json['meta']?['inbox']?['name']?.toString();

    final rawAccountId = json['account_id'] ?? json['account']?['id'];
    final int accId = rawAccountId is int ? rawAccountId : int.tryParse(rawAccountId?.toString() ?? '') ?? 0;

    String cStatus = 'open';
    final rawStatus = json['status'];
    if (rawStatus is int) {
      if (rawStatus == 1) {
        cStatus = 'resolved';
      } else if (rawStatus == 2) {
        cStatus = 'pending';
      } else if (rawStatus == 3) {
        cStatus = 'snoozed';
      } else {
        cStatus = 'open';
      }
    } else if (rawStatus != null) {
      cStatus = rawStatus.toString();
    }

    final rawUnread = json['unread_count'];
    final int unread = rawUnread is int ? rawUnread : (int.tryParse(rawUnread?.toString() ?? '0') ?? 0);

    final rawReplyBlockReason = json['reply_block_reason']?.toString() ?? json['meta']?['reply_block_reason']?.toString();
    final bool rawCanReply = json['can_reply'] ?? json['meta']?['can_reply'] ?? true;
    final bool canReply = rawCanReply && rawReplyBlockReason == null;

    DateTime? dtContactLastSeen;
    final rawContactSeen = json['contact_last_seen_at'] ?? json['meta']?['contact_last_seen_at'];
    if (rawContactSeen != null) {
      if (rawContactSeen is num && rawContactSeen > 0) {
        final val = rawContactSeen.toInt();
        dtContactLastSeen = DateTime.fromMillisecondsSinceEpoch(val > 1e11 ? val : val * 1000);
      } else if (rawContactSeen is String) {
        dtContactLastSeen = DateTime.tryParse(rawContactSeen);
      }
    }

    DateTime? dtSnoozed;
    final rawSnoozed = json['snoozed_until'];
    if (rawSnoozed != null) {
      if (rawSnoozed is num) {
        final val = rawSnoozed.toInt();
        dtSnoozed = DateTime.fromMillisecondsSinceEpoch(val > 1e11 ? val : val * 1000);
      } else if (rawSnoozed is String) {
        dtSnoozed = DateTime.tryParse(rawSnoozed);
      }
    }

    bool isMuted = false;
    final rawMuted = json['muted'] ?? json['meta']?['muted'];
    if (rawMuted is bool) {
      isMuted = rawMuted;
    } else if (rawMuted == 'true' || rawMuted == 1) {
      isMuted = true;
    } else if (rawMuted == 'false' || rawMuted == 0) {
      isMuted = false;
    } else if (json['muted_at'] != null &&
        json['muted_at'] != false &&
        json['muted_at'] != 0 &&
        json['muted_at'].toString().trim().isNotEmpty) {
      isMuted = true;
    }

    final Map<String, dynamic> cAttrs = json['custom_attributes'] is Map
        ? Map<String, dynamic>.from(json['custom_attributes'])
        : {};
    final Map<String, dynamic> aAttrs = json['additional_attributes'] is Map
        ? Map<String, dynamic>.from(json['additional_attributes'])
        : {};

    final bool isPinned = json['isPinned'] == true ||
        json['is_pinned'] == true ||
        json['pinned'] == true ||
        json['pinned_at'] != null ||
        json['conversation_pin'] != null ||
        json['meta']?['isPinned'] == true ||
        json['meta']?['pinned'] == true ||
        json['meta']?['is_pinned'] == true ||
        json['meta']?['conversation_pin'] != null ||
        cAttrs['isPinned'] == true ||
        cAttrs['is_pinned'] == true ||
        cAttrs['pinned'] == true ||
        aAttrs['isPinned'] == true ||
        aAttrs['is_pinned'] == true ||
        aAttrs['pinned'] == true;

    MessageReferral? convReferral;
    final wa = cAttrs['whatsapp'] ?? aAttrs['whatsapp'];
    dynamic rawConvRef;
    if (wa is Map) {
      rawConvRef = wa['ad_referral'] ?? wa['referral'];
    }
    rawConvRef ??= aAttrs['ad_referral'] ??
        aAttrs['referral'] ??
        cAttrs['ad_referral'] ??
        cAttrs['referral'];

    if (rawConvRef is String && rawConvRef.trim().startsWith('{')) {
      try {
        rawConvRef = jsonDecode(rawConvRef);
      } catch (_) {}
    }
    if (rawConvRef is Map) {
      try {
        final parsed = MessageReferral.fromJson(Map<String, dynamic>.from(rawConvRef));
        if (parsed.hasContent) convReferral = parsed;
      } catch (_) {}
    }

    return Conversation(
      id: convId > 0 ? convId : (json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0),
      recordId: json['record_id'] is int ? json['record_id'] : int.tryParse(json['record_id']?.toString() ?? ''),
      accountId: accId,
      inboxId: inbId,
      inboxName: inbName,
      inbox: parsedInbox,
      status: cStatus,
      unreadCount: unread,
      priority: json['priority']?.toString(),
      channel: ch,
      contact: parsedContact,
      lastMessage: lastMsg,
      assignee: parsedAssignee,
      team: parsedTeam,
      labels: labelsList,
      lifecycleStage: stage,
      updatedAt: dtUpdated,
      createdAt: dtCreated,
      canReply: canReply,
      snoozedUntil: dtSnoozed,
      contactLastSeenAt: dtContactLastSeen,
      replyBlockReason: rawReplyBlockReason,
      muted: isMuted,
      isPinned: isPinned,
      customAttributes: cAttrs,
      additionalAttributes: aAttrs,
      referral: convReferral,
    );
  }
}
