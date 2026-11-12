import '../../core/config/app_config.dart';

class Account {
  final int id;
  final String name;
  final String role;
  final String? status;
  final String? organizationName;
  final int? organizationId;
  final String? organizationLogo;
  final DateTime? breakEndsAt;
  final String? availabilityStatus;

  Account({
    required this.id,
    required this.name,
    required this.role,
    this.status,
    this.organizationName,
    this.organizationId,
    this.organizationLogo,
    this.breakEndsAt,
    this.availabilityStatus,
  });

  Account copyWith({
    int? id,
    String? name,
    String? role,
    String? status,
    String? organizationName,
    int? organizationId,
    String? organizationLogo,
    DateTime? breakEndsAt,
    String? availabilityStatus,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      organizationName: organizationName ?? this.organizationName,
      organizationId: organizationId ?? this.organizationId,
      organizationLogo: organizationLogo ?? this.organizationLogo,
      breakEndsAt: breakEndsAt ?? this.breakEndsAt,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
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

    DateTime? bEndsAt;
    final rawBreak = json['break_ends_at'];
    if (rawBreak != null) {
      if (rawBreak is String) {
        bEndsAt = DateTime.tryParse(rawBreak);
      } else if (rawBreak is num) {
        final val = rawBreak.toInt();
        bEndsAt = DateTime.fromMillisecondsSinceEpoch(val > 1e11 ? val : val * 1000);
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
      breakEndsAt: bEndsAt,
      availabilityStatus: json['availability_status']?.toString() ?? json['availability']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    if (status != null) 'status': status,
    if (organizationName != null) 'organization_name': organizationName,
    if (organizationId != null) 'organization_id': organizationId,
    if (organizationLogo != null) 'organization_logo': organizationLogo,
    if (breakEndsAt != null) 'break_ends_at': breakEndsAt!.toIso8601String(),
    if (availabilityStatus != null) 'availability_status': availabilityStatus,
  };

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
}

class User {
  final int id;
  final String name;
  final String? displayName;
  final String email;
  final String? avatarUrl;
  final String? pubsubToken;
  final String role;
  final String? type;
  final int accountId;
  final String availabilityStatus; // 'online', 'offline', 'busy'
  final List<Account> accounts;

  String? get thumbnail => avatarUrl;
  Account? get activeAccount => accounts.where((a) => a.id == accountId).firstOrNull ?? (accounts.isNotEmpty ? accounts.first : null);
  DateTime? get activeBreakEndsAt => activeAccount?.breakEndsAt;
  bool get isOnBreak {
    final status = availabilityStatus.toLowerCase();
    if (status != 'break' && status != 'on_break') return false;
    if (activeBreakEndsAt == null) return true;
    return activeBreakEndsAt!.isAfter(DateTime.now());
  }

  bool get isBot {
    final t = (type ?? '').toLowerCase();
    final r = role.toLowerCase();
    final n = name.toLowerCase();
    final dn = (displayName ?? '').toLowerCase();
    final em = email.toLowerCase();
    return t == 'agent_bot' ||
        t == 'bot' ||
        r == 'bot' ||
        r == 'agent_bot' ||
        n.contains('agent') ||
        n.contains('bot') ||
        n.contains('🤖') ||
        dn.contains('agent') ||
        dn.contains('bot') ||
        dn.contains('🤖') ||
        em.contains('bot') ||
        em.contains('agent');
  }

  User({
    required this.id,
    required this.name,
    this.displayName,
    required this.email,
    this.avatarUrl,
    this.pubsubToken,
    this.role = 'agent',
    this.type,
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
    String? type,
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
      type: type ?? this.type,
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

    final parsedAccountId = rawAccountId is int ? rawAccountId : int.tryParse(rawAccountId?.toString() ?? '') ?? 0;
    final activeAcc = accountsList.where((a) => a.id == parsedAccountId).firstOrNull;
    var userAvail = json['availability_status']?.toString() ?? json['availability']?.toString();
    if (userAvail == null || userAvail == 'online') {
      if (activeAcc?.availabilityStatus != null && activeAcc!.availabilityStatus!.isNotEmpty) {
        userAvail = activeAcc.availabilityStatus;
      }
    }
    if (activeAcc?.breakEndsAt != null && activeAcc!.breakEndsAt!.isAfter(DateTime.now())) {
      userAvail = 'break';
    }

    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? json['displayName']?.toString(),
      email: json['email']?.toString() ?? '',
      avatarUrl: avatar,
      pubsubToken: json['pubsub_token']?.toString(),
      role: json['role']?.toString() ?? 'agent',
      type: json['type']?.toString() ?? json['user_type']?.toString(),
      accountId: parsedAccountId,
      availabilityStatus: userAvail ?? 'online',
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
    if (type != null) 'type': type,
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
