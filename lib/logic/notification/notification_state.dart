import 'package:equatable/equatable.dart';
import '../../data/models/notification_item.dart';
import '../../data/models/notification_settings.dart';

class NotificationState extends Equatable {
  final List<NotificationItem> notifications;
  final bool isLoading;
  final String? errorMessage;
  final NotificationSettings settings;
  final bool isLoadingSettings;
  final bool isSavingSettings;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.errorMessage,
    this.settings = const NotificationSettings(),
    this.isLoadingSettings = false,
    this.isSavingSettings = false,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    bool? isLoading,
    String? errorMessage,
    NotificationSettings? settings,
    bool? isLoadingSettings,
    bool? isSavingSettings,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      settings: settings ?? this.settings,
      isLoadingSettings: isLoadingSettings ?? this.isLoadingSettings,
      isSavingSettings: isSavingSettings ?? this.isSavingSettings,
    );
  }

  @override
  List<Object?> get props => [
        notifications,
        isLoading,
        errorMessage,
        settings,
        isLoadingSettings,
        isSavingSettings,
      ];
}
