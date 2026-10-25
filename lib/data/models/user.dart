class Account {
  final int id;
  final String name;
  final String role;
  final int? status;

  Account({
    required this.id,
    required this.name,
    required this.role,
    this.status,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      role: json['role'] ?? 'agent',
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'status': status,
  };
}

class User {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? pubsubToken;
  final String role;
  final int accountId;
  final String availabilityStatus; // 'online', 'offline', 'busy'
  final List<Account> accounts;

  User({
    required this.id,
    required this.name,
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
    final accountsList = <Account>[];
    if (json['accounts'] != null && json['accounts'] is List) {
      for (final a in json['accounts']) {
        if (a is Map<String, dynamic>) {
          accountsList.add(Account.fromJson(a));
        }
      }
    }

    final rawAccountId = json['account_id'] ??
        json['current_account_id'] ??
        (accountsList.isNotEmpty ? accountsList.first.id : 0);

    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'] ?? json['thumbnail'],
      pubsubToken: json['pubsub_token'],
      role: json['role'] ?? 'agent',
      accountId: rawAccountId is int ? rawAccountId : int.tryParse(rawAccountId.toString()) ?? 0,
      availabilityStatus: json['availability_status'] ?? 'online',
      accounts: accountsList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatar_url': avatarUrl,
    'pubsub_token': pubsubToken,
    'role': role,
    'account_id': accountId,
    'availability_status': availabilityStatus,
    'accounts': accounts.map((a) => a.toJson()).toList(),
  };
}
