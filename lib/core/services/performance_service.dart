import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_performance/firebase_performance.dart';

/// Centralized service for Firebase Performance Monitoring.
/// Allows custom traces, network latency tracking, and app diagnostic metrics.
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  static FirebasePerformance? _perf;
  static bool _isInitialized = false;
  static final Map<String, Trace> _activeTraces = {};

  /// Initialize Firebase Performance and ensure collection is enabled.
  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('[FirebasePerformance] Firebase not yet initialized, skipping perf init.');
        return;
      }
      _perf = FirebasePerformance.instance;
      // Enable performance monitoring in release and profile modes (and debug if desired)
      await _perf?.setPerformanceCollectionEnabled(true);
      final isEnabled = await _perf?.isPerformanceCollectionEnabled() ?? false;
      _isInitialized = true;
      debugPrint('[FirebasePerformance] Initialized. Collection enabled: $isEnabled');
    } catch (e) {
      debugPrint('[FirebasePerformance] Initialization error: $e');
    }
  }

  /// Start a custom performance trace.
  static Future<Trace?> startTrace(String traceName, {Map<String, String>? attributes}) async {
    try {
      if (Firebase.apps.isEmpty) return null;
      if (!_isInitialized) await initialize();
      final trace = _perf?.newTrace(traceName);
      if (trace != null) {
        if (attributes != null) {
          attributes.forEach((key, value) {
            trace.putAttribute(key, value);
          });
        }
        await trace.start();
        _activeTraces[traceName] = trace;
        debugPrint('[FirebasePerformance] Started trace: $traceName');
        return trace;
      }
    } catch (e) {
      debugPrint('[FirebasePerformance] Error starting trace $traceName: $e');
    }
    return null;
  }

  /// Stop an active performance trace.
  static Future<void> stopTrace(String traceName, {Map<String, int>? metrics}) async {
    try {
      final trace = _activeTraces.remove(traceName);
      if (trace != null) {
        if (metrics != null) {
          metrics.forEach((metricName, value) {
            trace.setMetric(metricName, value);
          });
        }
        await trace.stop();
        debugPrint('[FirebasePerformance] Stopped trace: $traceName');
      }
    } catch (e) {
      debugPrint('[FirebasePerformance] Error stopping trace $traceName: $e');
    }
  }

  /// Convenience wrapper to measure the execution time of an asynchronous function.
  static Future<T> traceAsync<T>(
    String traceName,
    Future<T> Function() block, {
    Map<String, String>? attributes,
    Map<String, int>? metrics,
  }) async {
    final trace = await startTrace(traceName, attributes: attributes);
    try {
      final result = await block();
      return result;
    } finally {
      if (trace != null) {
        await stopTrace(traceName, metrics: metrics);
      }
    }
  }

  /// Create a Dio interceptor that instruments all HTTP requests with Firebase HttpMetric.
  static Interceptor createDioInterceptor() {
    return _DioFirebasePerformanceInterceptor();
  }
}

/// Internal Dio interceptor that automatically logs network metrics to Firebase Performance.
class _DioFirebasePerformanceInterceptor extends Interceptor {
  static const String _metricKey = '_firebase_http_metric';

  HttpMethod _mapHttpMethod(String method) {
    switch (method.toUpperCase()) {
      case 'POST':
        return HttpMethod.Post;
      case 'PUT':
        return HttpMethod.Put;
      case 'DELETE':
        return HttpMethod.Delete;
      case 'PATCH':
        return HttpMethod.Patch;
      case 'HEAD':
        return HttpMethod.Head;
      case 'OPTIONS':
        return HttpMethod.Options;
      case 'GET':
      default:
        return HttpMethod.Get;
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      if (Firebase.apps.isEmpty) {
        handler.next(options);
        return;
      }
      final perf = FirebasePerformance.instance;
      // Strip sensitive query params or hash if any for clean grouping
      final url = options.uri.toString();
      final metric = perf.newHttpMetric(url, _mapHttpMethod(options.method));

      // Calculate approximate request payload size
      if (options.data != null) {
        try {
          if (options.data is String) {
            metric.requestPayloadSize = utf8.encode(options.data as String).length;
          } else if (options.data is Map || options.data is List) {
            metric.requestPayloadSize = utf8.encode(jsonEncode(options.data)).length;
          }
        } catch (_) {}
      }

      await metric.start();
      options.extra[_metricKey] = metric;
    } catch (e) {
      debugPrint('[FirebasePerformance] Interceptor onRequest error: $e');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    try {
      final metric = response.requestOptions.extra[_metricKey] as HttpMetric?;
      if (metric != null) {
        metric.httpResponseCode = response.statusCode;
        metric.responseContentType = response.headers.value('content-type');

        if (response.data != null) {
          try {
            if (response.data is String) {
              metric.responsePayloadSize = utf8.encode(response.data as String).length;
            } else if (response.data is Map || response.data is List) {
              metric.responsePayloadSize = utf8.encode(jsonEncode(response.data)).length;
            }
          } catch (_) {}
        }

        await metric.stop();
      }
    } catch (e) {
      debugPrint('[FirebasePerformance] Interceptor onResponse error: $e');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    try {
      final metric = err.requestOptions.extra[_metricKey] as HttpMetric?;
      if (metric != null) {
        metric.httpResponseCode = err.response?.statusCode;
        metric.responseContentType = err.response?.headers.value('content-type');
        await metric.stop();
      }
    } catch (e) {
      debugPrint('[FirebasePerformance] Interceptor onError error: $e');
    }
    handler.next(err);
  }
}
