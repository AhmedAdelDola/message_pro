import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'shorebird_state.dart';

class ShorebirdCubit extends Cubit<ShorebirdState> {
  final ShorebirdUpdater _updater = ShorebirdUpdater();

  ShorebirdCubit() : super(const ShorebirdState()) {
    init();
  }

  Future<void> init() async {
    try {
      if (!_updater.isAvailable) {
        emit(state.copyWith(status: ShorebirdStatus.idle));
        return;
      }

      final patch = await _updater.readCurrentPatch();
      emit(state.copyWith(currentPatch: patch?.number));

      await checkForUpdate();
    } catch (e) {
      debugPrint('Shorebird init error: $e');
    }
  }

  Future<void> checkForUpdate() async {
    if (!_updater.isAvailable) return;

    emit(state.copyWith(status: ShorebirdStatus.checking));
    try {
      final status = await _updater.checkForUpdate();
      if (status == UpdateStatus.outdated) {
        emit(state.copyWith(status: ShorebirdStatus.updateAvailable));
        await downloadUpdate();
      } else {
        emit(state.copyWith(status: ShorebirdStatus.upToDate));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ShorebirdStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> downloadUpdate() async {
    emit(state.copyWith(status: ShorebirdStatus.updating));
    try {
      await _updater.update();
      emit(state.copyWith(status: ShorebirdStatus.updated));
    } catch (e) {
      emit(state.copyWith(
        status: ShorebirdStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
