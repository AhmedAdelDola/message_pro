import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyAccessToken = 'mp_access_token';
  static const _keyClient = 'mp_client';
  static const _keyUid = 'mp_uid';
  static const _keyPubSubToken = 'mp_pubsub_token';
  static const _keyUserData = 'mp_user_data';
  static const _keyAccountId = 'mp_account_id';
  static const _keyBaseUrl = 'mp_base_url';

  // In-memory caching for sub-millisecond retrieval (avoids repeated KeyStore platform-channel latency)
  Map<String, String>? _cachedAuthHeaders;
  String? _cachedPubSubToken;
  Map<String, dynamic>? _cachedUserData;

  Future<void> saveAuthCredentials({
    required String accessToken,
    required String client,
    required String uid,
    String? pubSubToken,
  }) async {
    _cachedAuthHeaders = {
      'access-token': accessToken,
      'client': client,
      'uid': uid,
    };
    if (pubSubToken != null) {
      _cachedPubSubToken = pubSubToken;
    }
    await _secureStorage.write(key: _keyAccessToken, value: accessToken);
    await _secureStorage.write(key: _keyClient, value: client);
    await _secureStorage.write(key: _keyUid, value: uid);
    if (pubSubToken != null) {
      await _secureStorage.write(key: _keyPubSubToken, value: pubSubToken);
    }
  }

  Future<Map<String, String>?> getAuthHeaders() async {
    if (_cachedAuthHeaders != null) {
      return _cachedAuthHeaders;
    }
    final token = await _secureStorage.read(key: _keyAccessToken);
    final client = await _secureStorage.read(key: _keyClient);
    final uid = await _secureStorage.read(key: _keyUid);

    if (token != null && client != null && uid != null) {
      _cachedAuthHeaders = {'access-token': token, 'client': client, 'uid': uid};
      return _cachedAuthHeaders;
    }
    return null;
  }

  Future<String?> getPubSubToken() async {
    if (_cachedPubSubToken != null) return _cachedPubSubToken;
    _cachedPubSubToken = await _secureStorage.read(key: _keyPubSubToken);
    return _cachedPubSubToken;
  }

  Future<void> saveUserData(Map<String, dynamic> userMap) async {
    _cachedUserData = Map<String, dynamic>.from(userMap);
    await _secureStorage.write(key: _keyUserData, value: jsonEncode(userMap));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    if (_cachedUserData != null) return _cachedUserData;
    final raw = await _secureStorage.read(key: _keyUserData);
    if (raw != null) {
      try {
        _cachedUserData = jsonDecode(raw) as Map<String, dynamic>;
        return _cachedUserData;
      } catch (_) {}
    }
    return null;
  }

  int? _cachedAccountId;

  Future<void> saveActiveAccountId(int accountId) async {
    _cachedAccountId = accountId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyAccountId, accountId);
    } catch (_) {}
  }

  Future<int?> getActiveAccountId() async {
    if (_cachedAccountId != null) return _cachedAccountId;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedAccountId = prefs.getInt(_keyAccountId);
      return _cachedAccountId;
    } catch (_) {
      return null;
    }
  }

  int? get activeAccountId => _cachedAccountId;

  Future<void> saveBaseUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyBaseUrl, url);
    } catch (_) {}
  }

  Future<String> getBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyBaseUrl) ?? AppConfig.defaultBaseUrl;
    } catch (_) {
      return AppConfig.defaultBaseUrl;
    }
  }

  Future<void> setString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }

  Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    _cachedAccountId = null;
    _cachedAuthHeaders = null;
    _cachedPubSubToken = null;
    _cachedUserData = null;
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAccountId);
    } catch (_) {}
  }
}
