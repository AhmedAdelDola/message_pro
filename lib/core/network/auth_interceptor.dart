import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage = SecureStorageService();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 1. Add device headers
    options.headers['X-Chatwoot-Client-Name'] = AppConfig.clientName;
    options.headers['X-Chatwoot-Client-Version'] = AppConfig.appVersion;
    options.headers['User-Agent'] = '${AppConfig.clientName}/${AppConfig.appVersion} (mobile)';

    // 2. Add auth tokens if available
    final authHeaders = await _storage.getAuthHeaders();
    if (authHeaders != null) {
      options.headers['access-token'] = authHeaders['access-token'];
      options.headers['client'] = authHeaders['client'];
      options.headers['uid'] = authHeaders['uid'];
    }

    // 3. Resolve path with account_id if needed
    final rawPath = options.path;
    final isAuth = AppConfig.authRoutes.any((r) => rawPath.startsWith(r)) || rawPath.startsWith('auth/');
    final isNonAccount = AppConfig.nonAccountRoutes.any((r) => rawPath.startsWith(r));

    if (!rawPath.startsWith('http://') && !rawPath.startsWith('https://')) {
      if (rawPath.startsWith('api/v1/') || rawPath.startsWith('api/v2/') || isAuth) {
        // Keep as-is
      } else if (isNonAccount) {
        options.path = 'api/v1/$rawPath';
      } else {
        var accountId = await _storage.getActiveAccountId();
        if (accountId == null || accountId <= 0) {
          final userData = await _storage.getUserData();
          final userAcc = userData?['account_id'] ?? userData?['current_account_id'];
          if (userAcc is int && userAcc > 0) {
            accountId = userAcc;
            await _storage.saveActiveAccountId(userAcc);
          }
        }
        if (accountId != null && accountId > 0) {
          options.path = 'api/v1/accounts/$accountId/$rawPath';
        } else {
          options.path = 'api/v1/$rawPath';
        }
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Rotate tokens from Devise Token Auth response headers
    final newAccessToken = response.headers.value('access-token');
    final newClient = response.headers.value('client');
    final newUid = response.headers.value('uid');

    if (newAccessToken != null && newClient != null && newUid != null && newAccessToken.isNotEmpty) {
      await _storage.saveAuthCredentials(
        accessToken: newAccessToken,
        client: newClient,
        uid: newUid,
      );
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired or invalid
    }
    handler.next(err);
  }
}
