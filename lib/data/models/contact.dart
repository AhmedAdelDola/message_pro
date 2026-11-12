import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';

class Contact {
  final int id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? identifier;
  final Map<String, dynamic> customAttributes;
  final List<Collaborator> collaborators;
  final bool canManageCollaborators;
  final LifecycleStage? lifecycleStage;
  final int? lifecycleStageId;

  Contact({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.identifier,
    this.customAttributes = const {},
    this.collaborators = const [],
    this.canManageCollaborators = false,
    this.lifecycleStage,
    this.lifecycleStageId,
  });

  Contact copyWith({
    int? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
    String? identifier,
    Map<String, dynamic>? customAttributes,
    List<Collaborator>? collaborators,
    bool? canManageCollaborators,
    LifecycleStage? lifecycleStage,
    int? lifecycleStageId,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      identifier: identifier ?? this.identifier,
      customAttributes: customAttributes ?? this.customAttributes,
      collaborators: collaborators ?? this.collaborators,
      canManageCollaborators: canManageCollaborators ?? this.canManageCollaborators,
      lifecycleStage: lifecycleStage ?? this.lifecycleStage,
      lifecycleStageId: lifecycleStageId ?? this.lifecycleStageId,
    );
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString().trim();
    final rawPhone = json['phone_number']?.toString().trim();
    final rawEmail = json['email']?.toString().trim();
    final rawIdentifier = json['identifier']?.toString().trim();
    final rawId = json['id'];
    final int contactId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    String displayName;
    final isGeneric = rawName != null &&
        (rawName.toLowerCase() == 'customer' ||
            rawName.toLowerCase() == 'عميل' ||
            rawName.toLowerCase() == 'visitor' ||
            rawName.toLowerCase() == 'null');

    if (rawName != null && rawName.isNotEmpty && !isGeneric) {
      displayName = rawName;
    } else if (rawPhone != null && rawPhone.isNotEmpty) {
      displayName = rawPhone;
    } else if (rawEmail != null && rawEmail.isNotEmpty) {
      displayName = rawEmail;
    } else if (rawIdentifier != null && rawIdentifier.isNotEmpty) {
      displayName = rawIdentifier;
    } else if (contactId > 0) {
      displayName = 'عميل #$contactId';
    } else {
      displayName = 'عميل جديد';
    }

    String? avatar = (json['avatar_url'] ?? json['thumbnail'])?.toString();
    if (avatar != null && avatar.isNotEmpty) {
      if (avatar.startsWith('/')) {
        avatar = '${AppConfig.defaultBaseUrl}$avatar';
      }
    }

    final rawCollabs = json['collaborators'];
    final collabsList = <Collaborator>[];
    if (rawCollabs is List) {
      for (final c in rawCollabs) {
        if (c is Map) {
          collabsList.add(Collaborator.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }

    final rawStageId = json['lifecycle_stage_id'];
    final stageId = rawStageId is int
        ? rawStageId
        : int.tryParse(rawStageId?.toString() ?? '');

    // Lifecycle stage resolution
    LifecycleStage? stage;
    final rawStage = json['lifecycle_stage'] ??
        json['custom_attributes']?['lifecycle_stage'] ??
        json['custom_attributes']?['lead_status'] ??
        json['stage'];

    if (rawStage is Map) {
      try {
        stage = LifecycleStage.fromJson(Map<String, dynamic>.from(rawStage));
      } catch (_) {}
    } else if (rawStage is String && rawStage.trim().isNotEmpty) {
      stage = LifecycleStage.fromString(rawStage);
    }

    if (stage != null && stageId != null && stage.id != stageId) {
      stage = stage.copyWith(id: stageId);
    }

    return Contact(
      id: contactId,
      name: displayName,
      email: rawEmail,
      phoneNumber: rawPhone,
      avatarUrl: avatar,
      identifier: rawIdentifier,
      customAttributes: json['custom_attributes'] is Map<String, dynamic>
          ? json['custom_attributes']
          : {},
      collaborators: collabsList,
      canManageCollaborators: json['can_manage_collaborators'] == true,
      lifecycleStage: stage,
      lifecycleStageId: stageId ?? stage?.id,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone_number': phoneNumber,
    'avatar_url': avatarUrl,
    'identifier': identifier,
    'custom_attributes': customAttributes,
    'collaborators': collaborators.map((c) => c.toJson()).toList(),
    'can_manage_collaborators': canManageCollaborators,
    'lifecycle_stage_id': lifecycleStageId,
  };
}

class Collaborator {
  final int id;
  final String name;
  final String type;
  final String? avatarUrl;
  final String? thumbnail;

  Collaborator({
    required this.id,
    required this.name,
    this.type = 'user',
    this.avatarUrl,
    this.thumbnail,
  });

  factory Collaborator.fromJson(Map<String, dynamic> json) {
    return Collaborator(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'user',
      avatarUrl: (json['avatar_url'] ?? json['thumbnail'])?.toString(),
      thumbnail: json['thumbnail']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    if (thumbnail != null) 'thumbnail': thumbnail,
  };
}


class Inbox {
  final int id;
  final String name;
  final String channelType;
  final String? avatarUrl;

  Inbox({
    required this.id,
    required this.name,
    required this.channelType,
    this.avatarUrl,
  });

  factory Inbox.fromJson(Map<String, dynamic> json) {
    return Inbox(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      channelType: json['channel_type'] ?? 'Channel::WebWidget',
      avatarUrl: json['avatar_url'],
    );
  }
}

class Label {
  final int id;
  final String title;
  final String color;
  final String? description;

  Label({
    required this.id,
    required this.title,
    required this.color,
    this.description,
  });

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      color: json['color'] ?? '#3B82F6',
      description: json['description'],
    );
  }
}

class LifecycleStage {
  final int id;
  final String name;
  final String color;
  final String? icon;

  LifecycleStage({
    required this.id,
    required this.name,
    this.color = '#4162E3',
    this.icon,
  });

  LifecycleStage copyWith({
    int? id,
    String? name,
    String? color,
    String? icon,
  }) {
    return LifecycleStage(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }

  factory LifecycleStage.fromJson(Map<String, dynamic> json) {
    final rawName = (json['name'] ?? json['title'] ?? '').toString();
    final rawIcon = json['icon'] ?? json['emoji'] ?? json['symbol'] ?? json['shape'];
    final iconStr = (rawIcon != null && rawIcon.toString().isNotEmpty)
        ? rawIcon.toString()
        : getEmojiForStage(rawName);

    return LifecycleStage(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: rawName,
      color: json['color'] ?? getColorForStage(rawName),
      icon: iconStr,
    );
  }

  factory LifecycleStage.fromString(String raw) {
    final trimmed = raw.trim();
    final emoji = getEmojiForStage(trimmed);
    String cleanName = trimmed;
    if (cleanName.startsWith(emoji)) {
      cleanName = cleanName.substring(emoji.length).trim();
    }
    return LifecycleStage(
      id: 0,
      name: cleanName.isNotEmpty ? cleanName : trimmed,
      color: getColorForStage(trimmed),
      icon: emoji,
    );
  }

  static String getEmojiForStage(String stageName) {
    final trimmed = stageName.trim();
    if (trimmed.isEmpty) return '🌱';

    // If string already begins with an emoji / non-ASCII symbol
    final firstRune = trimmed.runes.firstOrNull;
    if (firstRune != null && (firstRune > 127 || firstRune == 0x2B50 || firstRune == 0x203C || firstRune == 0x21A9)) {
      final chars = trimmed.characters;
      return chars.first;
    }

    final lower = trimmed.toLowerCase();
    if (lower.contains('prospect')) return '⭐';
    if (lower.contains('new') || lower.contains('lead')) return '🆕';
    if (lower.contains('outbound')) return '⭐';
    if (lower.contains('engage') || lower.contains('active')) return '🔥';
    if (lower.contains('call')) return '📞';
    if (lower.contains('demo')) return '💻';
    if (lower.contains('trial')) return '⏳';
    if (lower.contains('payment') || lower.contains('pending')) return '😇';
    if (lower.contains('qualif')) return '💰';
    if (lower.contains('sale') || lower.contains('assign')) return '🤩';
    if (lower.contains('negotia')) return '🙄';
    if (lower.contains('customer') || lower.contains('won')) return '👑';
    if (lower.contains('lost')) return '😔';
    return '🌱';
  }

  static String getColorForStage(String stageName) {
    final lower = stageName.toLowerCase();
    if (lower.contains('customer') || lower.contains('won')) return '#10B981';
    if (lower.contains('lost')) return '#EF4444';
    if (lower.contains('engage') || lower.contains('fire')) return '#F97316';
    if (lower.contains('qualif') || lower.contains('payment')) return '#F59E0B';
    if (lower.contains('prospect') || lower.contains('lead')) return '#3B82F6';
    return '#4162E3';
  }
}

class Team {
  final int id;
  final String name;
  final String? description;

  Team({
    required this.id,
    required this.name,
    this.description,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
    );
  }
}
