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
  });

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

  factory LifecycleStage.fromJson(Map<String, dynamic> json) {
    return LifecycleStage(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      color: json['color'] ?? '#4162E3',
      icon: json['icon'],
    );
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
