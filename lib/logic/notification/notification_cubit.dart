import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/performance_service.dart';
import '../../data/models/notification_settings.dart';
import '../../data/repositories/notification_repository.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final INotificationRepository repo;

  NotificationCubit({required this.repo})
      : super(const NotificationState()) {
    loadNotifications();
  }

  void reset() {
    emit(const NotificationState());
  }

  Future<void> loadNotifications() async {
    emit(state.copyWith(isLoading: true));
    await PerformanceService.traceAsync(
      'load_notifications',
      () async {
        final result = await repo.getNotifications();
        result.fold(
          (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
          (list) => emit(state.copyWith(notifications: list, isLoading: false, errorMessage: null)),
        );
      },
      onResult: (trace, _) {
        trace.setMetric('notifications_count', state.notifications.length);
      },
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

  Future<void> loadSettings() async {
    emit(state.copyWith(isLoadingSettings: true, errorMessage: null));
    final result = await repo.getNotificationSettings();
    result.fold(
      (failure) => emit(state.copyWith(isLoadingSettings: false, errorMessage: failure.message)),
      (settings) => emit(state.copyWith(isLoadingSettings: false, settings: settings)),
    );
  }

  Future<bool> saveSettings(NotificationSettings newSettings) async {
    emit(state.copyWith(settings: newSettings, isSavingSettings: true));
    final result = await repo.updateNotificationSettings(newSettings);
    return result.fold(
      (failure) {
        emit(state.copyWith(isSavingSettings: false, errorMessage: failure.message));
        return false;
      },
      (savedSettings) {
        emit(state.copyWith(settings: savedSettings, isSavingSettings: false));
        return true;
      },
    );
  }
}
