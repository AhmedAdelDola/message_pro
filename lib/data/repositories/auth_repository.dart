import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../models/user.dart';

abstract class IAuthRepository {
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
    String? baseUrl,
  });
  Future<Either<Failure, User>> signInWithGoogle(String idToken);
  Future<Either<Failure, User>> getProfile();
  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? displayName,
    String? email,
  });
  Future<Either<Failure, void>> updateAvailability({
    required String status,
    int? breakDurationMinutes,
    int? accountId,
  });
  Future<Either<Failure, void>> setActiveAccount(int accountId);
  Future<Either<Failure, void>> resetPassword(String email);
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, User>> restoreSession();
}

class AuthRepository implements IAuthRepository {
  final ApiClient _api;
  final SecureStorageService _storage;

  AuthRepository({ApiClient? api, SecureStorageService? storage})
      : _api = api ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  @override
  Future<Either<Failure, User>> restoreSession() async {
    try {
      final headers = await _storage.getAuthHeaders();
      final savedUserMap = await _storage.getUserData();

      if (headers != null && savedUserMap != null) {
        final user = User.fromJson(savedUserMap);
        if (user.accountId > 0) {
          final activeAcc = await _storage.getActiveAccountId();
          if (activeAcc == null || activeAcc == 0) {
            await _storage.saveActiveAccountId(user.accountId);
          }
        }
        return Right(user);
      }
      return const Left(CacheFailure('لا توجد جلسة محفوظة'));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
    String? baseUrl,
  }) async {
    try {
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

      // Devise Token Auth headers
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

      return Right(user);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(AuthFailure('بيانات الدخول غير صحيحة، يرجى التأكد والمحاولة مجدداً'));
      }
      final errList = e.response?.data?['errors'];
      final errText = (errList is List && errList.isNotEmpty)
          ? errList[0]?.toString()
          : (errList is String ? errList : 'فشل الاتصال بالخادم');
      return Left(ServerFailure(errText ?? 'فشل الاتصال بالخادم'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle(String idToken) async {
    try {
      debugPrint('[GoogleAuth] Backend Request: POST https://omni.message-pro.com/api/v1/auth/google');
      debugPrint('[GoogleAuth] Google ID Token present: ${idToken.isNotEmpty} (length: ${idToken.length})');

      // User requirement: POST https://omni.message-pro.com/api/v1/auth/google with {"id_token": "<GOOGLE_ID_TOKEN>"}
      Response response;
      try {
        response = await _api.post(
          'api/v1/auth/google',
          data: {'id_token': idToken},
        );
        debugPrint('[GoogleAuth] Backend HTTP status: ${response.statusCode}');
      } on DioException catch (dioErr) {
        debugPrint('[GoogleAuth] Backend DioException: status=${dioErr.response?.statusCode}');
        if (dioErr.response?.statusCode == 404) {
          debugPrint('[GoogleAuth] Fallback endpoint: auth/google');
          response = await _api.post(
            'auth/google',
            data: {'id_token': idToken},
          );
          debugPrint('[GoogleAuth] Fallback HTTP status: ${response.statusCode}');
        } else {
          rethrow;
        }
      }

      final data = response.data;
      final userData = data is Map ? (data['data'] ?? data) : <String, dynamic>{};
      final user = User.fromJson(Map<String, dynamic>.from(userData));

      // User requirement 4: Save access-token, client, uid from response headers
      final accessToken = response.headers.value('access-token') ??
          (data is Map ? (data['access-token'] ?? data['access_token'] ?? data['auth_token'] ?? '') : '');
      final client = response.headers.value('client') ??
          (data is Map ? (data['client'] ?? data['client_id'] ?? '') : '');
      final uid = response.headers.value('uid') ??
          (data is Map ? (data['uid'] ?? data['email'] ?? '') : '');
      final pubSubToken = userData['pubsub_token'];

      debugPrint('[GoogleAuth] Session Headers received: access-token=${accessToken.isNotEmpty}, client=${client.isNotEmpty}, uid=${uid.isNotEmpty}');

      if (accessToken.isNotEmpty && client.isNotEmpty && uid.isNotEmpty) {
        await _storage.saveAuthCredentials(
          accessToken: accessToken,
          client: client,
          uid: uid,
          pubSubToken: pubSubToken,
        );
      }

      await _storage.saveUserData(userData);
      if (user.accountId > 0) {
        await _storage.saveActiveAccountId(user.accountId);
      }

      return Right(user);
    } on DioException catch (e) {
      debugPrint('[GoogleAuth] Error HTTP status: ${e.response?.statusCode}');
      if (e.response?.statusCode == 401) {
        return const Left(AuthFailure('فشل المصادقة عبر حساب Google'));
      }
      final errList = e.response?.data?['errors'];
      final String? firstError = (errList is List && errList.isNotEmpty)
          ? errList[0]?.toString()
          : (errList is String ? errList : null);
      final msg = e.response?.data?['error'] ??
          firstError ??
          e.response?.data?['message'] ??
          'فشل تسجيل الدخول عبر Google (${e.response?.statusCode ?? 'خطأ'})';
      return Left(ServerFailure(msg.toString()));
    } catch (e) {
      debugPrint('[GoogleAuth] Unexpected error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getProfile() async {
    try {
      final response = await _api.get('profile');
      final data = response.data;
      final userData = data is Map ? Map<String, dynamic>.from(data['data'] ?? data) : <String, dynamic>{};

      // Preserve existing accounts list if profile endpoint doesn't return accounts
      final savedUserMap = await _storage.getUserData();
      if ((userData['accounts'] == null || (userData['accounts'] is List && (userData['accounts'] as List).isEmpty)) &&
          savedUserMap != null &&
          savedUserMap['accounts'] is List &&
          (savedUserMap['accounts'] as List).isNotEmpty) {
        userData['accounts'] = savedUserMap['accounts'];
      }

      final user = User.fromJson(userData);
      await _storage.saveUserData(userData);
      return Right(user);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل في جلب الملف الشخصي'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? displayName,
    String? email,
  }) async {
    try {
      final profilePayload = <String, dynamic>{
        if (name != null) 'name': name.trim(),
        if (displayName != null) 'display_name': displayName.trim(),
        if (email != null) 'email': email.trim(),
      };

      // Match Chatwoot API: supports {"profile": {...}} or top-level fields
      final body = {
        'profile': profilePayload,
        ...profilePayload,
      };

      final response = await _api.put('profile', data: body);

      final data = response.data;
      final rawUserData = data is Map ? Map<String, dynamic>.from(data['data'] ?? data) : <String, dynamic>{};

      // Merge with stored user data to preserve accounts, tokens, and active account id
      final savedUserMap = await _storage.getUserData() ?? <String, dynamic>{};
      final mergedData = Map<String, dynamic>.from(savedUserMap);

      rawUserData.forEach((k, v) {
        if (v != null) mergedData[k] = v;
      });
      if (name != null) mergedData['name'] = name.trim();
      if (displayName != null) mergedData['display_name'] = displayName.trim();
      if (email != null) mergedData['email'] = email.trim();

      if (rawUserData['accounts'] == null ||
          (rawUserData['accounts'] is List && (rawUserData['accounts'] as List).isEmpty)) {
        if (savedUserMap['accounts'] != null) {
          mergedData['accounts'] = savedUserMap['accounts'];
        }
      }

      final updatedUser = User.fromJson(mergedData);
      await _storage.saveUserData(mergedData);

      return Right(updatedUser);
    } on DioException catch (e) {
      final errList = e.response?.data?['errors'];
      final errText = (errList is List && errList.isNotEmpty)
          ? errList[0]?.toString()
          : (errList is String ? errList : e.response?.data?['message'] ?? e.message);
      return Left(ServerFailure(errText ?? 'فشل في تحديث الملف الشخصي'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateAvailability({
    required String status,
    int? breakDurationMinutes,
    int? accountId,
  }) async {
    try {
      final activeAccId = accountId ?? await _storage.getActiveAccountId() ?? 0;
      final isBreak = status == 'break' || status == 'on_break';
      final apiAvailability = isBreak ? 'break' : status;

      final profilePayload = <String, dynamic>{
        if (activeAccId > 0) 'account_id': activeAccId,
        'availability': apiAvailability,
        if (isBreak && breakDurationMinutes != null)
          'break_duration_minutes': breakDurationMinutes.clamp(1, 120),
      };

      final body = {
        'profile': profilePayload,
        'availability': apiAvailability,
        'availability_status': apiAvailability,
        if (activeAccId > 0) 'account_id': activeAccId,
        if (isBreak && breakDurationMinutes != null)
          'break_duration_minutes': breakDurationMinutes.clamp(1, 120),
      };

      try {
        await _api.post('profile/availability', data: body);
      } on DioException catch (dioErr) {
        if (dioErr.response?.statusCode == 404 || dioErr.response?.statusCode == 405) {
          await _api.put(
            'profile',
            data: {
              'profile': profilePayload,
              'availability_status': apiAvailability,
            },
          );
        } else {
          rethrow;
        }
      }

      // Persist in local storage
      final savedUserMap = await _storage.getUserData();
      if (savedUserMap != null) {
        savedUserMap['availability_status'] = apiAvailability;
        savedUserMap['availability'] = apiAvailability;
        if (isBreak && breakDurationMinutes != null) {
          final endsAt = DateTime.now().add(Duration(minutes: breakDurationMinutes.clamp(1, 120)));
          savedUserMap['break_ends_at'] = endsAt.toIso8601String();
        } else {
          savedUserMap.remove('break_ends_at');
        }
        await _storage.saveUserData(savedUserMap);
      }

      return const Right(null);
    } on DioException catch (e) {
      final errList = e.response?.data?['errors'];
      final errText = (errList is List && errList.isNotEmpty)
          ? errList[0]?.toString()
          : (errList is String ? errList : e.response?.data?['message'] ?? e.message);
      return Left(ServerFailure(errText ?? 'فشل في تحديث حالة التواجد'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setActiveAccount(int accountId) async {
    try {
      await _storage.saveActiveAccountId(accountId);
      final response = await _api.put('profile/set_active_account', data: {
        'profile': {'account_id': accountId}
      });

      // Update saved user data with the active account_id and any returned accounts
      final savedUserMap = await _storage.getUserData();
      if (savedUserMap != null) {
        savedUserMap['account_id'] = accountId;
        savedUserMap['current_account_id'] = accountId;
        if (response.data is Map) {
          final resData = response.data['data'] ?? response.data;
          if (resData is Map && resData['accounts'] is List && (resData['accounts'] as List).isNotEmpty) {
            savedUserMap['accounts'] = resData['accounts'];
          }
        }
        await _storage.saveUserData(savedUserMap);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await _api.post('auth/password', data: {'email': email.trim()});
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _api.delete('auth/sign_out');
    } catch (_) {}
    await _storage.clearAll();
    return const Right(null);
  }
}
