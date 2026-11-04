import 'package:flutter_bloc/flutter_bloc.dart';
import 'calls_state.dart';

class CallsCubit extends Cubit<CallsState> {
  CallsCubit() : super(const CallsState()) {
    loadCalls();
  }

  Future<void> loadCalls() async {
    emit(state.copyWith(isLoading: true));
    // As per specification, mobile calls feature is Coming Soon
    emit(state.copyWith(calls: const [], isLoading: false));
  }
}
