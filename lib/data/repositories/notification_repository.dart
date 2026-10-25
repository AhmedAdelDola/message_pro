import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_client.dart';
import '../models/notification_item.dart';

abstract class INotificationRepository {
  Future<Either<Failure, List<NotificationItem>>> getNotifications({int page = 1});
  Future<Either<Failure, void>> markAsRead(int id);
  Future<Either<Failure, void>> markAllAsRead();
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
      await _api.post('notifications/$id/read');
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
}
