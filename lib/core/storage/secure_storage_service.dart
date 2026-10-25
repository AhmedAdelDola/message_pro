import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
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

  Future<void> saveAuthCredentials({
    required String accessToken,
    required String client,
    required String uid,
    String? pubSubToken,
  }) async {
    await _secureStorage.write(key: _keyAccessToken, value: accessToken);
    await _secureStorage.write(key: _keyClient, value: client);
    await _secureStorage.write(key: _keyUid, value: uid);
    if (pubSubToken != null) {
      await _secureStorage.write(key: _keyPubSubToken, value: pubSubToken);
    }
  }

  Future<Map<String, String>?> getAuthHeaders() async {
    final token = await _secureStorage.read(key: _keyAccessToken);
    final client = await _secureStorage.read(key: _keyClient);
    final uid = await _secureStorage.read(key: _keyUid);

    if (token != null && client != null && uid != null) {
      return {
        'access-token': token,
        'client': client,
        'uid': uid,
      };
    }
    return null;
  }

  Future<String?> getPubSubToken() async {
    return await _secureStorage.read(key: _keyPubSubToken);
  }

  Future<void> saveUserData(Map<String, dynamic> userMap) async {
    await _secureStorage.write(key: _keyUserData, value: jsonEncode(userMap));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final raw = await _secureStorage.read(key: _keyUserData);
    if (raw != null) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  Future<void> saveActiveAccountId(int accountId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAccountId, accountId);
  }

  Future<int?> getActiveAccountId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAccountId);
  }

  Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, url);
  }

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseUrl) ?? AppConfig.defaultBaseUrl;
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccountId);
  }
}
