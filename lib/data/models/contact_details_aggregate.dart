import 'contact.dart';

class SectionPaginationInfo {
  final bool hasMore;
  final int? nextPage;
  final int currentPage;
  final int? totalCount;

  const SectionPaginationInfo({
    this.hasMore = false,
    this.nextPage,
    this.currentPage = 1,
    this.totalCount,
  });

  factory SectionPaginationInfo.fromJson(Map<String, dynamic> json) {
    return SectionPaginationInfo(
      hasMore: json['has_more'] == true,
      nextPage: json['next_page'] is int
          ? json['next_page'] as int
          : int.tryParse(json['next_page']?.toString() ?? ''),
      currentPage: json['current_page'] is int
          ? json['current_page'] as int
          : int.tryParse(json['current_page']?.toString() ?? '') ?? 1,
      totalCount: json['total_count'] is int
          ? json['total_count'] as int
          : int.tryParse(json['total_count']?.toString() ?? ''),
    );
  }
}

class ContactAiActivityItem {
  final int id;
  final String title;
  final String? summary;
  final String? status;
  final String? outcome;
  final int? conversationId;
  final DateTime? createdAt;
  final List<String> actions;
  final Map<String, dynamic> raw;

  const ContactAiActivityItem({
    required this.id,
    required this.title,
    this.summary,
    this.status,
    this.outcome,
    this.conversationId,
    this.createdAt,
    this.actions = const [],
    this.raw = const {},
  });

  factory ContactAiActivityItem.fromJson(Map<String, dynamic> json) {
    final rawActions = json['actions'] ?? json['actions_summary'];
    final parsedActions = <String>[];
    if (rawActions is List) {
      for (final a in rawActions) {
        if (a is Map) {
          parsedActions.add((a['name'] ?? a['type'] ?? a['summary'] ?? a.toString()).toString());
        } else if (a != null) {
          parsedActions.add(a.toString());
        }
      }
    }
    return ContactAiActivityItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: (json['title'] ?? json['agent_name'] ?? json['bot_name'] ?? 'AI Run').toString(),
      summary: (json['summary'] ?? json['action_summary'] ?? json['message'])?.toString(),
      status: json['status']?.toString(),
      outcome: json['outcome']?.toString(),
      conversationId: json['conversation_id'] is int
          ? json['conversation_id'] as int
          : int.tryParse(json['conversation_id']?.toString() ?? ''),
      createdAt: _parseDateTime(json['created_at']),
      actions: parsedActions,
      raw: json,
    );
  }
}

class ContactAttachmentItem {
  final int id;
  final int? messageId;
  final int? conversationId;
  final String fileType;
  final String dataUrl;
  final String? thumbUrl;
  final String fileName;
  final int? fileSize;
  final String? extension;
  final String? senderName;
  final String? senderAvatar;
  final DateTime? createdAt;

  const ContactAttachmentItem({
    required this.id,
    this.messageId,
    this.conversationId,
    required this.fileType,
    required this.dataUrl,
    this.thumbUrl,
    required this.fileName,
    this.fileSize,
    this.extension,
    this.senderName,
    this.senderAvatar,
    this.createdAt,
  });

  factory ContactAttachmentItem.fromJson(Map<String, dynamic> json) {
    final url = (json['data_url'] ?? json['url'] ?? '').toString();
    final rawName = (json['file_name'] ?? json['filename'] ?? json['name'])?.toString();
    final derivedName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (url.isNotEmpty ? Uri.tryParse(url)?.pathSegments.lastOrNull ?? 'file' : 'file');
    final ext = json['extension']?.toString() ??
        (derivedName.contains('.') ? derivedName.split('.').last.toUpperCase() : null);

    final sender = json['sender'] is Map ? json['sender'] as Map : null;

    return ContactAttachmentItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      messageId: json['message_id'] is int
          ? json['message_id'] as int
          : int.tryParse(json['message_id']?.toString() ?? ''),
      conversationId: json['conversation_id'] is int
          ? json['conversation_id'] as int
          : int.tryParse(json['conversation_id']?.toString() ?? ''),
      fileType: (json['file_type'] ?? 'file').toString(),
      dataUrl: url,
      thumbUrl: json['thumb_url']?.toString(),
      fileName: derivedName,
      fileSize: json['file_size'] is int
          ? json['file_size'] as int
          : int.tryParse(json['file_size']?.toString() ?? ''),
      extension: ext?.toUpperCase(),
      senderName: (sender?['name'] ?? json['sender_name'])?.toString(),
      senderAvatar: (sender?['avatar_url'] ?? sender?['thumbnail'] ?? json['sender_avatar'])?.toString(),
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  String get formattedSize {
    if (fileSize == null || fileSize! <= 0) return '';
    if (fileSize! < 1024) return '${fileSize!} B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).round()} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ContactActivityItem {
  final int id;
  final String title;
  final String content;
  final String? activityType;
  final int? conversationId;
  final String? actorName;
  final DateTime? createdAt;

  const ContactActivityItem({
    required this.id,
    required this.title,
    required this.content,
    this.activityType,
    this.conversationId,
    this.actorName,
    this.createdAt,
  });

  factory ContactActivityItem.fromJson(Map<String, dynamic> json) {
    final content = (json['content'] ?? json['description'] ?? '').toString();
    final type = (json['activity_type'] ?? json['type'] ?? '').toString();
    String resolvedTitle = (json['title'] ?? '').toString();
    if (resolvedTitle.isEmpty) {
      final lower = content.toLowerCase();
      if (lower.contains('unassigned')) {
        resolvedTitle = 'Unassigned';
      } else if (lower.contains('assigned')) {
        resolvedTitle = 'Assigned';
      } else if (lower.contains('lifecycle')) {
        resolvedTitle = 'Lifecycle';
      } else if (lower.contains('label') || lower.contains('tag')) {
        resolvedTitle = 'Labels';
      } else if (lower.contains('resolved') || lower.contains('reopen')) {
        resolvedTitle = 'Status';
      } else {
        resolvedTitle = type.isNotEmpty ? type : 'Activity';
      }
    }

    return ContactActivityItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: resolvedTitle,
      content: content,
      activityType: type.isNotEmpty ? type : null,
      conversationId: json['conversation_id'] is int
          ? json['conversation_id'] as int
          : int.tryParse(json['conversation_id']?.toString() ?? ''),
      actorName: json['sender'] is Map ? json['sender']['name']?.toString() : null,
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

class ContactNoteItem {
  final int id;
  final String content;
  final int? conversationId;
  final String authorName;
  final String? authorAvatar;
  final DateTime? createdAt;

  const ContactNoteItem({
    required this.id,
    required this.content,
    this.conversationId,
    required this.authorName,
    this.authorAvatar,
    this.createdAt,
  });

  factory ContactNoteItem.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] is Map ? json['sender'] as Map : null;
    final user = json['user'] is Map ? json['user'] as Map : null;
    final author = sender ?? user;
    return ContactNoteItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      content: (json['content'] ?? '').toString(),
      conversationId: json['conversation_id'] is int
          ? json['conversation_id'] as int
          : int.tryParse(json['conversation_id']?.toString() ?? ''),
      authorName: (author?['name'] ?? json['author_name'] ?? 'Team').toString(),
      authorAvatar: (author?['avatar_url'] ?? author?['thumbnail'] ?? json['author_avatar'])?.toString(),
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

class ContactCalendarEvent {
  final int id;
  final String title;
  final String? description;
  final String? status;
  final String? location;
  final String? meetingUrl;
  final DateTime? startAt;
  final DateTime? endAt;

  const ContactCalendarEvent({
    required this.id,
    required this.title,
    this.description,
    this.status,
    this.location,
    this.meetingUrl,
    this.startAt,
    this.endAt,
  });

  factory ContactCalendarEvent.fromJson(Map<String, dynamic> json) {
    return ContactCalendarEvent(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: (json['title'] ?? json['summary'] ?? 'Meeting').toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString(),
      location: json['location']?.toString(),
      meetingUrl: (json['meeting_url'] ?? json['hangout_link'])?.toString(),
      startAt: _parseDateTime(json['start_at'] ?? json['start_time'] ?? json['starts_at']),
      endAt: _parseDateTime(json['end_at'] ?? json['end_time'] ?? json['ends_at']),
    );
  }
}

class EcommerceProviderError {
  final String? code;
  final String message;

  const EcommerceProviderError({this.code, required this.message});

  factory EcommerceProviderError.fromJson(Map<String, dynamic> json) {
    return EcommerceProviderError(
      code: json['code']?.toString(),
      message: (json['message'] ?? json['error'] ?? 'Failed to load store data').toString(),
    );
  }
}

class EcommerceOrder {
  final String id;
  final String orderNumber;
  final String? totalPrice;
  final String? currency;
  final String? financialStatus;
  final String? fulfillmentStatus;
  final String? resourceToken;
  final DateTime? createdAt;
  final int itemsCount;
  final Map<String, dynamic> raw;

  const EcommerceOrder({
    required this.id,
    required this.orderNumber,
    this.totalPrice,
    this.currency,
    this.financialStatus,
    this.fulfillmentStatus,
    this.resourceToken,
    this.createdAt,
    this.itemsCount = 0,
    this.raw = const {},
  });

  factory EcommerceOrder.fromJson(Map<String, dynamic> json) {
    final items = json['line_items'] is List ? (json['line_items'] as List).length : 0;
    return EcommerceOrder(
      id: (json['id'] ?? '').toString(),
      orderNumber: (json['name'] ?? json['order_number'] ?? '#${json['id'] ?? ''}').toString(),
      totalPrice: (json['total_price'] ?? json['current_total_price'])?.toString(),
      currency: json['currency']?.toString(),
      financialStatus: json['financial_status']?.toString(),
      fulfillmentStatus: json['fulfillment_status']?.toString(),
      resourceToken: json['resource_token']?.toString(),
      createdAt: _parseDateTime(json['created_at']),
      itemsCount: json['items_count'] is int ? json['items_count'] as int : items,
      raw: json,
    );
  }
}

class EcommerceStoreData {
  final String connectionId;
  final String storeName;
  final String storeDomain;
  final bool isMatched;
  final Map<String, dynamic>? matchedCustomer;
  final List<EcommerceOrder> orders;
  final bool hasNextPage;
  final String? endCursor;
  final int? nextPage;
  final EcommerceProviderError? error;

  const EcommerceStoreData({
    required this.connectionId,
    required this.storeName,
    required this.storeDomain,
    this.isMatched = false,
    this.matchedCustomer,
    this.orders = const [],
    this.hasNextPage = false,
    this.endCursor,
    this.nextPage,
    this.error,
  });

  factory EcommerceStoreData.fromJson(Map<String, dynamic> json) {
    final conn = json['connection'] is Map ? json['connection'] as Map : const {};
    final match = json['match'] is Map ? json['match'] as Map : const {};
    final pageInfo = json['page_info'] is Map ? json['page_info'] as Map : const {};
    final rawOrders = json['orders'] is List ? json['orders'] as List : const [];
    final rawErr = json['error'];

    return EcommerceStoreData(
      connectionId: (conn['id'] ?? json['connection_id'] ?? '').toString(),
      storeName: (conn['name'] ?? conn['shop_name'] ?? 'Store').toString(),
      storeDomain: (conn['shop_domain'] ?? conn['domain'] ?? '').toString(),
      isMatched: match['matched'] == true || match['customer'] != null,
      matchedCustomer: match['customer'] is Map
          ? Map<String, dynamic>.from(match['customer'] as Map)
          : null,
      orders: rawOrders
          .whereType<Map>()
          .map((o) => EcommerceOrder.fromJson(Map<String, dynamic>.from(o)))
          .toList(),
      hasNextPage: pageInfo['has_next_page'] == true || pageInfo['has_more'] == true,
      endCursor: pageInfo['end_cursor']?.toString(),
      nextPage: pageInfo['next_page'] is int
          ? pageInfo['next_page'] as int
          : int.tryParse(pageInfo['next_page']?.toString() ?? ''),
      error: rawErr is Map
          ? EcommerceProviderError.fromJson(Map<String, dynamic>.from(rawErr))
          : (rawErr != null ? EcommerceProviderError(message: rawErr.toString()) : null),
    );
  }
}

class ContactEcommerceData {
  final bool enabled;
  final List<EcommerceStoreData> stores;

  const ContactEcommerceData({
    this.enabled = false,
    this.stores = const [],
  });

  factory ContactEcommerceData.fromJson(Map<String, dynamic> json) {
    final rawStores = json['stores'] is List ? json['stores'] as List : const [];
    return ContactEcommerceData(
      enabled: json['enabled'] == true,
      stores: rawStores
          .whereType<Map>()
          .map((s) => EcommerceStoreData.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
    );
  }
}

class ContactDetailsAggregate {
  final Contact? contact;
  final List<String> labels;
  final Map<String, dynamic>? assignee;
  final List<Map<String, dynamic>> collaborators;
  final LifecycleStage? lifecycleStage;
  final List<Map<String, dynamic>> teams;
  final List<String> channels;

  final List<dynamic>? calls;
  final List<ContactAiActivityItem>? aiActivity;
  final List<ContactAttachmentItem>? attachments;
  final List<ContactActivityItem>? activities;
  final List<ContactNoteItem>? notes;
  final List<ContactCalendarEvent>? calendar;
  final ContactEcommerceData? ecommerce;

  final Map<String, SectionPaginationInfo> pagination;
  final Set<String> includedSections;

  const ContactDetailsAggregate({
    this.contact,
    this.labels = const [],
    this.assignee,
    this.collaborators = const [],
    this.lifecycleStage,
    this.teams = const [],
    this.channels = const [],
    this.calls,
    this.aiActivity,
    this.attachments,
    this.activities,
    this.notes,
    this.calendar,
    this.ecommerce,
    this.pagination = const {},
    this.includedSections = const {},
  });

  factory ContactDetailsAggregate.fromJson(Map<String, dynamic> json) {
    Contact? parsedContact;
    List<String> parsedLabels = [];
    Map<String, dynamic>? parsedAssignee;
    List<Map<String, dynamic>> parsedCollaborators = [];
    LifecycleStage? parsedStage;
    List<Map<String, dynamic>> parsedTeams = [];
    final List<String> parsedChannels = [];

    if (json['contact'] is Map) {
      final cMap = Map<String, dynamic>.from(json['contact'] as Map);
      parsedContact = Contact.fromJson(cMap);
      if (cMap['labels'] is List) {
        parsedLabels = (cMap['labels'] as List).map((e) => e.toString()).toList();
      }
      if (cMap['assignee'] is Map) {
        parsedAssignee = Map<String, dynamic>.from(cMap['assignee'] as Map);
      }
      if (cMap['collaborators'] is List) {
        parsedCollaborators = (cMap['collaborators'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (cMap['lifecycle_stage'] is Map) {
        parsedStage = LifecycleStage.fromJson(
          Map<String, dynamic>.from(cMap['lifecycle_stage'] as Map),
        );
      }
      if (cMap['teams'] is List) {
        parsedTeams = (cMap['teams'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      final rawInboxes = cMap['contact_inboxes'] ?? cMap['inboxes'] ?? cMap['channels'];
      if (rawInboxes is List) {
        for (final item in rawInboxes) {
          if (item is Map) {
            final inb = item['inbox'] is Map ? item['inbox'] as Map : item;
            final ch = (inb['channel_type'] ?? inb['type'] ?? '').toString();
            if (ch.isNotEmpty) parsedChannels.add(ch);
          } else if (item != null && item.toString().isNotEmpty) {
            parsedChannels.add(item.toString());
          }
        }
      }
    }

    final meta = json['meta'] is Map ? json['meta'] as Map : const {};
    final paginationMap = <String, SectionPaginationInfo>{};
    if (meta['pagination'] is Map) {
      (meta['pagination'] as Map).forEach((key, val) {
        if (val is Map) {
          paginationMap[key.toString()] = SectionPaginationInfo.fromJson(
            Map<String, dynamic>.from(val),
          );
        }
      });
    }

    final included = <String>{};
    if (meta['sections'] is List) {
      for (final s in meta['sections'] as List) {
        included.add(s.toString());
      }
    }

    return ContactDetailsAggregate(
      contact: parsedContact,
      labels: parsedLabels,
      assignee: parsedAssignee,
      collaborators: parsedCollaborators,
      lifecycleStage: parsedStage ?? parsedContact?.lifecycleStage,
      teams: parsedTeams,
      channels: parsedChannels,
      calls: json.containsKey('calls') && json['calls'] is List
          ? List<dynamic>.from(json['calls'] as List)
          : null,
      aiActivity: json.containsKey('ai_activity') && json['ai_activity'] is List
          ? (json['ai_activity'] as List)
              .whereType<Map>()
              .map((e) => ContactAiActivityItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : null,
      attachments: json.containsKey('attachments') && json['attachments'] is List
          ? (json['attachments'] as List)
              .whereType<Map>()
              .map((e) => ContactAttachmentItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : null,
      activities: json.containsKey('activities') && json['activities'] is List
          ? (json['activities'] as List)
              .whereType<Map>()
              .map((e) => ContactActivityItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : null,
      notes: json.containsKey('notes') && json['notes'] is List
          ? (json['notes'] as List)
              .whereType<Map>()
              .map((e) => ContactNoteItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : null,
      calendar: json.containsKey('calendar') && json['calendar'] is List
          ? (json['calendar'] as List)
              .whereType<Map>()
              .map((e) => ContactCalendarEvent.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : null,
      ecommerce: json.containsKey('ecommerce') && json['ecommerce'] is Map
          ? ContactEcommerceData.fromJson(Map<String, dynamic>.from(json['ecommerce'] as Map))
          : null,
      pagination: paginationMap,
      includedSections: included,
    );
  }
}

DateTime? _parseDateTime(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) {
    final val = raw.toInt();
    return DateTime.fromMillisecondsSinceEpoch(val > 1e11 ? val : val * 1000);
  }
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw);
  }
  return null;
}
