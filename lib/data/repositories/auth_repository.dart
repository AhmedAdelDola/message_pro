import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../models/user.dart';

class AuthRepository {
  final ApiClient _api = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

  Future<User> signIn({
    required String email,
    required String password,
    String? baseUrl,
  }) async {
    if (baseUrl != null && baseUrl.isNotEmpty) {
      await _storage.saveBaseUrl(baseUrl);
      _api.updateBaseUrl(baseUrl);
    }

    final response = await _api.post(
      'auth/sign_in',
      data: {'email': email.trim(), 'password': password},
    );

    final data = response.data;
    final userData = data['data'] ?? data;
    final user = User.fromJson(userData);

    // Save tokens from Devise Token Auth headers
    final accessToken = response.headers.value('access-token') ?? '';
    final client = response.headers.value('client') ?? '';
    final uid = response.headers.value('uid') ?? '';
    final pubSubToken = userData['pubsub_token'];

    if (accessToken.isNotEmpty && client.isNotEmpty && uid.isNotEmpty) {
      await _storage.saveAuthCredentials(
        accessToken: accessToken,
        client: client,
        uid: uid,
        pubSubToken: pubSubToken,
      );
    }

    await _storage.saveUserData(userData);
    await _storage.saveActiveAccountId(user.accountId);

    return user;
  }

  Future<User?> getProfile() async {
    try {
      final response = await _api.get('profile');
      final data = response.data;
      final userData = data['data'] ?? data;
      final user = User.fromJson(userData);
      await _storage.saveUserData(userData);
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateAvailability(String status) async {
    await _api.post('profile/availability', data: {'availability': status});
  }

  Future<void> setActiveAccount(int accountId) async {
    await _storage.saveActiveAccountId(accountId);
    await _api.post('profile/set_active_account', data: {'account_id': accountId});
  }

  Future<void> resetPassword(String email) async {
    await _api.post('auth/password', data: {'email': email.trim()});
  }

  Future<void> signOut() async {
    try {
      await _api.delete('auth/sign_out');
    } catch (_) {}
    await _storage.clearAll();
  }
}
