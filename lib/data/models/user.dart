import '../../core/config/app_config.dart';

class Account {
  final int id;
  final String name;
  final String role;
  final String? status;
  final String? organizationName;
  final int? organizationId;
  final String? organizationLogo;

  Account({
    required this.id,
    required this.name,
    required this.role,
    this.status,
    this.organizationName,
    this.organizationId,
    this.organizationLogo,
  });

  Account copyWith({
    int? id,
    String? name,
    String? role,
    String? status,
    String? organizationName,
    int? organizationId,
    String? organizationLogo,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      organizationName: organizationName ?? this.organizationName,
      organizationId: organizationId ?? this.organizationId,
      organizationLogo: organizationLogo ?? this.organizationLogo,
    );
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    String? orgName;
    int? orgId;
    String? orgLogo;

    final rawOrg = json['organization'] ?? json['org'] ?? json['enterprise']?['organization'];
    if (rawOrg is Map) {
      orgName = (rawOrg['name'] ?? rawOrg['title'])?.toString();
      orgId = rawOrg['id'] is int ? rawOrg['id'] : int.tryParse(rawOrg['id']?.toString() ?? '');
      orgLogo = (rawOrg['logo'] ?? rawOrg['avatar_url'] ?? rawOrg['thumbnail'])?.toString();
    } else if (rawOrg is String && rawOrg.trim().isNotEmpty) {
      orgName = rawOrg.trim();
    }

    if (orgName == null || orgName.isEmpty) {
      orgName = json['organization_name']?.toString() ??
          json['org_name']?.toString() ??
          json['company']?.toString() ??
          json['company_name']?.toString() ??
          json['custom_attributes']?['organization']?.toString() ??
          json['custom_attributes']?['organization_name']?.toString();
    }

    if (orgId == null) {
      final rawOrgId = json['organization_id'] ?? json['org_id'];
      if (rawOrgId != null) {
        orgId = rawOrgId is int ? rawOrgId : int.tryParse(rawOrgId.toString());
      }
    }

    return Account(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'agent',
      status: json['status']?.toString(),
      organizationName: orgName,
      organizationId: orgId,
      organizationLogo: orgLogo,
    );
  }

  String getEffectiveOrgName(String defaultFallback) {
    if (organizationName != null && organizationName!.trim().isNotEmpty) {
      return organizationName!.trim();
    }
    for (final sep in [' - ', ' | ', ' / ', ' : ', ' — ']) {
      if (name.contains(sep)) {
        final prefix = name.split(sep).first.trim();
        if (prefix.isNotEmpty && prefix.length > 2) {
          return prefix;
        }
      }
    }
    return defaultFallback;
  }

  String getDisplayNameInOrg(String orgName) {
    for (final sep in [' - ', ' | ', ' / ', ' : ', ' — ']) {
      if (name.contains(sep)) {
        final parts = name.split(sep);
        if (parts.first.trim().toLowerCase() == orgName.trim().toLowerCase() && parts.length > 1) {
          final sub = parts.sublist(1).join(sep).trim();
          if (sub.isNotEmpty) return sub;
        }
      }
    }
    return name;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'status': status,
    if (organizationName != null) 'organization_name': organizationName,
    if (organizationId != null) 'organization_id': organizationId,
    if (organizationLogo != null) 'organization_logo': organizationLogo,
  };
}

class User {
  final int id;
  final String name;
  final String? displayName;
  final String email;
  final String? avatarUrl;
  final String? pubsubToken;
  final String role;
  final int accountId;
  final String availabilityStatus; // 'online', 'offline', 'busy'
  final List<Account> accounts;

  String? get thumbnail => avatarUrl;

  User({
    required this.id,
    required this.name,
    this.displayName,
    required this.email,
    this.avatarUrl,
    this.pubsubToken,
    this.role = 'agent',
    required this.accountId,
    this.availabilityStatus = 'online',
    this.accounts = const [],
  });

  User copyWith({
    int? id,
    String? name,
    String? displayName,
    String? email,
    String? avatarUrl,
    String? pubsubToken,
    String? role,
    int? accountId,
    String? availabilityStatus,
    List<Account>? accounts,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      pubsubToken: pubsubToken ?? this.pubsubToken,
      role: role ?? this.role,
      accountId: accountId ?? this.accountId,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      accounts: accounts ?? this.accounts,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Map account ID to organization name if organizations list is provided at root
    final accountOrgMap = <int, String>{};
    final accountOrgIdMap = <int, int>{};

    if (json['organizations'] is List) {
      for (final org in json['organizations']) {
        if (org is Map) {
          final orgName = (org['name'] ?? org['title'])?.toString();
          final orgId = org['id'] is int ? org['id'] : int.tryParse(org['id']?.toString() ?? '');
          final accList = org['accounts'] ?? org['account_ids'] ?? org['workspaces'];
          if (accList is List && orgName != null && orgName.isNotEmpty) {
            for (final acc in accList) {
              final id = acc is Map ? acc['id'] : acc;
              final accId = id is int ? id : int.tryParse(id?.toString() ?? '');
              if (accId != null) {
                accountOrgMap[accId] = orgName;
                if (orgId != null) accountOrgIdMap[accId] = orgId;
              }
            }
          }
        }
      }
    }

    final rawUserOrg = json['organization'] ?? json['company'] ?? json['enterprise'];
    String? userDefaultOrg;
    if (rawUserOrg is Map) {
      userDefaultOrg = (rawUserOrg['name'] ?? rawUserOrg['title'])?.toString();
    } else if (rawUserOrg is String && rawUserOrg.trim().isNotEmpty) {
      userDefaultOrg = rawUserOrg.trim();
    } else if (json['organization_name'] != null) {
      userDefaultOrg = json['organization_name'].toString();
    }

    final accountsList = <Account>[];
    if (json['accounts'] != null && json['accounts'] is List) {
      for (final a in json['accounts']) {
        if (a is Map) {
          var account = Account.fromJson(Map<String, dynamic>.from(a));
          if (account.organizationName == null || account.organizationName!.isEmpty) {
            if (accountOrgMap.containsKey(account.id)) {
              account = account.copyWith(
                organizationName: accountOrgMap[account.id],
                organizationId: accountOrgIdMap[account.id],
              );
            } else if (userDefaultOrg != null && userDefaultOrg.isNotEmpty) {
              account = account.copyWith(organizationName: userDefaultOrg);
            }
          }
          accountsList.add(account);
        }
      }
    }

    final rawAccountId = json['account_id'] ??
        json['current_account_id'] ??
        (accountsList.isNotEmpty ? accountsList.first.id : 0);

    String? avatar = (json['avatar_url'] ?? json['thumbnail'])?.toString();
    if (avatar != null && avatar.isNotEmpty) {
      if (avatar.startsWith('/')) {
        avatar = '${AppConfig.defaultBaseUrl}$avatar';
      }
    }

    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? json['displayName']?.toString(),
      email: json['email']?.toString() ?? '',
      avatarUrl: avatar,
      pubsubToken: json['pubsub_token']?.toString(),
      role: json['role']?.toString() ?? 'agent',
      accountId: rawAccountId is int ? rawAccountId : int.tryParse(rawAccountId?.toString() ?? '') ?? 0,
      availabilityStatus: json['availability_status']?.toString() ?? 'online',
      accounts: accountsList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (displayName != null) 'display_name': displayName,
    'email': email,
    'avatar_url': avatarUrl,
    'pubsub_token': pubsubToken,
    'role': role,
    'account_id': accountId,
    'availability_status': availabilityStatus,
    'accounts': accounts.map((a) => a.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          displayName == other.displayName &&
          email == other.email &&
          avatarUrl == other.avatarUrl &&
          pubsubToken == other.pubsubToken &&
          role == other.role &&
          accountId == other.accountId &&
          availabilityStatus == other.availabilityStatus;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      (displayName?.hashCode ?? 0) ^
      email.hashCode ^
      (avatarUrl?.hashCode ?? 0) ^
      role.hashCode ^
      accountId.hashCode ^
      availabilityStatus.hashCode;
}
