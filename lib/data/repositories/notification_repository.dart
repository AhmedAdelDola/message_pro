import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_client.dart';
import '../models/notification_item.dart';
import '../models/notification_settings.dart';

abstract class INotificationRepository {
  Future<Either<Failure, List<NotificationItem>>> getNotifications({int page = 1});
  Future<Either<Failure, void>> markAsRead(int id);
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
  Future<Either<Failure, List<NotificationItem>>> getNotifications({int page = 1}) async {
    try {
      final response = await _api.get(
        'notifications',
        queryParameters: {'page': page},
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
      final response = await _api.get('profile/notification_settings');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Right(NotificationSettings.fromJson(data));
      } else if (data is Map) {
        return Right(NotificationSettings.fromJson(Map<String, dynamic>.from(data)));
      }
      return const Right(NotificationSettings());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل جلب إعدادات الإشعارات'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationSettings>> updateNotificationSettings(NotificationSettings settings) async {
    try {
      final response = await _api.put(
        'profile/notification_settings',
        data: settings.toUpdatePayload(),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Right(NotificationSettings.fromJson(data));
      } else if (data is Map) {
        return Right(NotificationSettings.fromJson(Map<String, dynamic>.from(data)));
      }
      return Right(settings);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل تحديث إعدادات الإشعارات'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> registerPushToken(String token, {String deviceName = 'android'}) async {
    try {
      await _api.post(
        'notification_subscriptions',
        data: {
          'subscription_type': 'fcm',
          'subscription_attributes': {
            'push_token': token,
            'device_name': deviceName,
          },
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

