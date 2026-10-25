import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification_item.dart';
import '../data/repositories/notification_repository.dart';

class NotificationState {
  final List<NotificationItem> notifications;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repo = NotificationRepository();

  NotificationNotifier() : super(const NotificationState()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repo.getNotifications();
      state = state.copyWith(notifications: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _repo.markAsRead(id);
      final updated = state.notifications.map((n) {
        if (n.id == id) {
          return NotificationItem(
            id: n.id,
            notificationType: n.notificationType,
            primaryActorId: n.primaryActorId,
            primaryActorType: n.primaryActorType,
            title: n.title,
            message: n.message,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      state = state.copyWith(notifications: updated);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _repo.markAllAsRead();
      final updated = state.notifications.map((n) {
        return NotificationItem(
          id: n.id,
          notificationType: n.notificationType,
          primaryActorId: n.primaryActorId,
          primaryActorType: n.primaryActorType,
          title: n.title,
          message: n.message,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();
      state = state.copyWith(notifications: updated);
    } catch (_) {}
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
