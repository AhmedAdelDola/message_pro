import '../../core/network/api_client.dart';
import '../models/notification_item.dart';

class NotificationRepository {
  final ApiClient _api = ApiClient();

  Future<List<NotificationItem>> getNotifications({int page = 1}) async {
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
    return list.map((n) => NotificationItem.fromJson(n as Map<String, dynamic>)).toList();
  }

  Future<void> markAsRead(int id) async {
    await _api.post('notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _api.post('notifications/read_all');
  }
}
