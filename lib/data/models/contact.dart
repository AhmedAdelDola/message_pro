class Contact {
  final int id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? identifier;
  final Map<String, dynamic> customAttributes;

  Contact({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.identifier,
    this.customAttributes = const {},
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? 'Unknown Contact',
      email: json['email'],
      phoneNumber: json['phone_number'],
      avatarUrl: json['avatar_url'] ?? json['thumbnail'],
      identifier: json['identifier'],
      customAttributes: json['custom_attributes'] is Map<String, dynamic>
          ? json['custom_attributes']
          : {},
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
