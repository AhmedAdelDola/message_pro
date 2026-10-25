import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/notification_repository.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final INotificationRepository repo;

  NotificationCubit({required this.repo})
      : super(const NotificationState()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    emit(state.copyWith(isLoading: true));
    final result = await repo.getNotifications();
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (list) => emit(state.copyWith(notifications: list, isLoading: false, errorMessage: null)),
    );
  }

  Future<void> markAsRead(int id) async {
    final result = await repo.markAsRead(id);
    result.fold((_) {}, (_) {
      final updated = state.notifications.map((n) {
        if (n.id == id) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      emit(state.copyWith(notifications: updated));
    });
  }

  Future<void> markAllAsRead() async {
    final result = await repo.markAllAsRead();
    result.fold((_) {}, (_) {
      final updated = state.notifications.map((n) {
        return n.copyWith(isRead: true);
      }).toList();
      emit(state.copyWith(notifications: updated));
    });
  }
}
