import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification_item.dart';

class CallsState {
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
}

class CallsNotifier extends StateNotifier<CallsState> {
  CallsNotifier() : super(const CallsState()) {
    loadCalls();
  }

  void loadCalls() {
    state = state.copyWith(isLoading: true);
    // Standard mock/synced call log for customer conversations
    final sampleCalls = [
      CallItem(
        id: '1',
        contactName: 'Mohamed Ahmed',
        contactPhone: '+20 100 123 4567',
        callType: 'incoming',
        duration: '04:12',
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      CallItem(
        id: '2',
        contactName: 'Sara Hassan',
        contactPhone: '+20 111 987 6543',
        callType: 'missed',
        duration: '00:00',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      CallItem(
        id: '3',
        contactName: 'Omar Khaled',
        contactPhone: '+966 50 123 4567',
        callType: 'outgoing',
        duration: '02:45',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      CallItem(
        id: '4',
        contactName: 'Nour El-Din',
        contactPhone: '+20 122 334 4556',
        callType: 'incoming',
        duration: '08:30',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
    state = state.copyWith(calls: sampleCalls, isLoading: false);
  }
}

final callsProvider = StateNotifierProvider<CallsNotifier, CallsState>((ref) {
  return CallsNotifier();
});
