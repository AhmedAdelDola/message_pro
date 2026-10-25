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
  Future<Either<Failure, User>> getProfile();
  Future<Either<Failure, void>> updateAvailability(String status);
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
      return Left(ServerFailure(e.response?.data?['errors']?[0]?.toString() ?? 'فشل الاتصال بالخادم'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getProfile() async {
    try {
      final response = await _api.get('profile');
      final data = response.data;
      final userData = data['data'] ?? data;
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
  Future<Either<Failure, void>> updateAvailability(String status) async {
    try {
      await _api.post('profile/availability', data: {'availability': status});
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setActiveAccount(int accountId) async {
    try {
      await _storage.saveActiveAccountId(accountId);
      await _api.post('profile/set_active_account', data: {'account_id': accountId});
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
