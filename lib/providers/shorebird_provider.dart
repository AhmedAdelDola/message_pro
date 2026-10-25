import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

enum ShorebirdStatus { idle, checking, updateAvailable, updating, updated, upToDate, error }

class ShorebirdState {
  final ShorebirdStatus status;
  final int? currentPatch;
  final String? errorMessage;

  const ShorebirdState({
    this.status = ShorebirdStatus.idle,
    this.currentPatch,
    this.errorMessage,
  });

  ShorebirdState copyWith({
    ShorebirdStatus? status,
    int? currentPatch,
    String? errorMessage,
  }) {
    return ShorebirdState(
      status: status ?? this.status,
      currentPatch: currentPatch ?? this.currentPatch,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ShorebirdNotifier extends StateNotifier<ShorebirdState> {
  final ShorebirdUpdater _updater = ShorebirdUpdater();

  ShorebirdNotifier() : super(const ShorebirdState()) {
    init();
  }

  Future<void> init() async {
    try {
      if (!_updater.isAvailable) {
        state = state.copyWith(status: ShorebirdStatus.idle);
        return;
      }

      final patch = await _updater.readCurrentPatch();
      state = state.copyWith(currentPatch: patch?.number);

      // Automatically check for update on start
      await checkForUpdate();
    } catch (e) {
      debugPrint('Shorebird init error: $e');
    }
  }

  Future<void> checkForUpdate() async {
    if (!_updater.isAvailable) return;

    state = state.copyWith(status: ShorebirdStatus.checking);
    try {
      final status = await _updater.checkForUpdate();
      if (status == UpdateStatus.outdated) {
        state = state.copyWith(status: ShorebirdStatus.updateAvailable);
        // Automatically download update in background
        await downloadUpdate();
      } else {
        state = state.copyWith(status: ShorebirdStatus.upToDate);
      }
    } catch (e) {
      state = state.copyWith(
        status: ShorebirdStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> downloadUpdate() async {
    state = state.copyWith(status: ShorebirdStatus.updating);
    try {
      await _updater.update();
      state = state.copyWith(status: ShorebirdStatus.updated);
    } catch (e) {
      state = state.copyWith(
        status: ShorebirdStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final shorebirdProvider = StateNotifierProvider<ShorebirdNotifier, ShorebirdState>((ref) {
  return ShorebirdNotifier();
});
