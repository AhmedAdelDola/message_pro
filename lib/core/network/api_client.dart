import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;
  final SecureStorageService _storage = SecureStorageService();

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.defaultBaseUrl,
        connectTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 25),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: true,
        error: true,
        compact: false,
        maxWidth: 120,
        logPrint: (object) => debugPrint('$object'),
      ),
    );
    _initBaseUrl();
  }

  Dio get dio => _dio;

  Future<void> _initBaseUrl() async {
    final base = await _storage.getBaseUrl();
    _dio.options.baseUrl = base.endsWith('/') ? base : '$base/';
  }

  void updateBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl.endsWith('/') ? newUrl : '$newUrl/';
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.patch<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
  }
}
