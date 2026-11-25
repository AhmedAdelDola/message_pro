import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../models/notification_item.dart';
import '../models/notification_settings.dart';

abstract class INotificationRepository {
  Future<Either<Failure, List<NotificationItem>>> getNotifications({int page = 1, bool includeRead = false, bool includeSnoozed = false});
  Future<Either<Failure, void>> markAsRead(int id);
  Future<Either<Failure, void>> markAsUnread(int id);
  Future<Either<Failure, void>> archiveNotification(int id);
  Future<Either<Failure, void>> markAllAsRead();
  Future<Either<Failure, int>> getUnreadCount();
  Future<Either<Failure, NotificationSettings>> getNotificationSettings();
  Future<Either<Failure, NotificationSettings>> updateNotificationSettings(NotificationSettings settings);
  Future<Either<Failure, void>> registerPushToken(String token, {String deviceName = 'android'});
  Future<Either<Failure, void>> unregisterPushToken(String token);
}

class NotificationRepository implements INotificationRepository {
  final ApiClient _api;

  NotificationRepository({ApiClient? api}) : _api = api ?? ApiClient();

  @override
  Future<Either<Failure, List<NotificationItem>>> getNotifications({
    int page = 1,
    bool includeRead = false,
    bool includeSnoozed = false,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'sort_order': 'desc',
      };
      if (includeRead) query['includes[]'] = 'read';
      if (includeSnoozed) query['includes[]'] = 'snoozed';

      final response = await _api.get(
        'notifications',
        queryParameters: query,
      );
      final data = response.data;
      List list = [];
      if (data is Map && data['data'] != null && data['data']['payload'] != null) {
        list = data['data']['payload'];
      } else if (data is Map && data['payload'] != null) {
        list = data['payload'];
      } else if (data is List) {
        list = data;
      }
      return Right(list.map((n) => NotificationItem.fromJson(n as Map<String, dynamic>)).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل تحميل الإشعارات'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(int id) async {
    try {
      // Per spec: PATCH A/notifications/:id
      await _api.patch('notifications/$id');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsUnread(int id) async {
    try {
      // Per spec: POST A/notifications/:id/unread
      await _api.post('notifications/$id/unread');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> archiveNotification(int id) async {
    try {
      // Per spec: DELETE A/notifications/:id
      await _api.delete('notifications/$id');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      await _api.post('notifications/read_all');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final response = await _api.get('notifications/unread_count');
      if (response.data is int) {
        return Right(response.data as int);
      }
      if (response.data is Map && response.data['count'] != null) {
        return Right(response.data['count'] as int);
      }
      final parsed = int.tryParse(response.data.toString()) ?? 0;
      return Right(parsed);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationSettings>> getNotificationSettings() async {
    try {
      Response? response;
      // 1. Try A/notification_settings
      try {
        response = await _api.get('notification_settings');
      } catch (_) {
        try {
          response = await _api.get('profile/notification_settings');
        } catch (_) {}
      }

      if (response != null && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return Right(NotificationSettings.fromJson(data));
        } else if (data is Map) {
          return Right(NotificationSettings.fromJson(Map<String, dynamic>.from(data)));
        }
      }

      // Check local cache
      final storage = SecureStorageService();
      final cachedStr = await storage.getString('cached_notification_settings');
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final cachedJson = jsonDecode(cachedStr);
        if (cachedJson is Map<String, dynamic>) {
          return Right(NotificationSettings.fromJson(cachedJson));
        }
      }

      return const Right(NotificationSettings());
    } catch (_) {
      return const Right(NotificationSettings());
    }
  }

  @override
  Future<Either<Failure, NotificationSettings>> updateNotificationSettings(NotificationSettings settings) async {
    // 1. Save locally immediately
    try {
      final storage = SecureStorageService();
      await storage.setString('cached_notification_settings', jsonEncode(settings.toJson()));
    } catch (_) {}

    try {
      Response? response;
      final payload = {
        'notification_settings': {
          'selected_email_flags': settings.selectedEmailFlags,
          'selected_push_flags': settings.selectedPushFlags,
          'selected_mobile_push_flags': settings.selectedPushFlags.map((f) {
            if (f.startsWith('mobile_push_')) return f;
            if (f.startsWith('push_')) return f.replaceFirst('push_', 'mobile_push_');
            return 'mobile_push_$f';
          }).toList(),
        },
        ...settings.toUpdatePayload(),
      };

      // 1. Try PUT A/notification_settings (Standard Chatwoot & C:\crm method)
      try {
        response = await _api.put(
          'notification_settings',
          data: payload,
        );
      } catch (_) {
        // 2. Try PATCH A/notification_settings
        try {
          response = await _api.patch(
            'notification_settings',
            data: payload,
          );
        } catch (_) {
          // 3. Fallback to PUT profile/notification_settings
          try {
            response = await _api.put(
              'profile/notification_settings',
              data: payload,
            );
          } catch (_) {}
        }
      }

      if (response != null && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return Right(NotificationSettings.fromJson(data));
        } else if (data is Map) {
          return Right(NotificationSettings.fromJson(Map<String, dynamic>.from(data)));
        }
      }

      return Right(settings);
    } catch (_) {
      // Local save succeeded, avoid 404 crash
      return Right(settings);
    }
  }

  @override
  Future<Either<Failure, void>> registerPushToken(String token, {String deviceName = 'android'}) async {
    try {
      final isIos = defaultTargetPlatform == TargetPlatform.iOS;
      final platform = isIos ? 'ios' : 'android';
      final brand = isIos ? 'Apple' : 'Android';
      final osVersion = isIos ? '17.0' : '34';

      await _api.post(
        'notification_subscriptions',
        data: {
          'subscription_type': 'fcm',
          'subscription_attributes': {
            'deviceName': deviceName,
            'devicePlatform': platform,
            'apiLevel': osVersion,
            'brandName': brand,
            'buildNumber': '10',
            'push_token': token,
            'device_id': '${platform}_$token',
            'device_name': deviceName,
          },
          'push_token': token,
          'fcm_token': token,
          'device_name': deviceName,
        },
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل تسجيل معرف الجهاز للإشعارات'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unregisterPushToken(String token) async {
    try {
      await _api.delete(
        'notification_subscriptions',
        data: {
          'push_token': token,
        },
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل إلغاء تسجيل معرف الجهاز'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

