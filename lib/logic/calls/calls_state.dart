import 'package:equatable/equatable.dart';
import '../../data/models/notification_item.dart';

class CallsState extends Equatable {
  final List<CallItem> calls;
  final bool isLoading;

  const CallsState({
    this.calls = const [],
    this.isLoading = false,
  });

  CallsState copyWith({
    List<CallItem>? calls,
    bool? isLoading,
  }) {
    return CallsState(
      calls: calls ?? this.calls,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [calls, isLoading];
}
