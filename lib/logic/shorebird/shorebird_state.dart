import 'package:equatable/equatable.dart';

enum ShorebirdStatus { idle, checking, updateAvailable, updating, updated, upToDate, error }

class ShorebirdState extends Equatable {
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

  @override
  List<Object?> get props => [status, currentPatch, errorMessage];
}
