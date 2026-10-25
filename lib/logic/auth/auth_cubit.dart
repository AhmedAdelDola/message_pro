import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/websocket_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final IAuthRepository authRepo;
  final SecureStorageService storage;
  final ActionCableClient ws;

  AuthCubit({
    required this.authRepo,
    required this.storage,
    required this.ws,
  }) : super(const AuthInitial());

  User? get currentUser {
    if (state is Authenticated) {
      return (state as Authenticated).user;
    }
    return null;
  }

  Future<bool> restoreSession() async {
    emit(const AuthLoading());
    final result = await authRepo.restoreSession();

    return result.fold(
      (failure) {
        emit(const Unauthenticated());
        return false;
      },
      (user) async {
        emit(Authenticated(user));

        // Connect WebSocket
        final pubSubToken = user.pubsubToken ?? await storage.getPubSubToken();
        if (pubSubToken != null) {
          ws.connect(
            pubSubToken: pubSubToken,
            accountId: user.accountId,
            userId: user.id,
          );
        }

        // Refresh profile silently
        authRepo.getProfile().then((profileResult) {
          profileResult.fold((_) {}, (refreshed) {
            emit(Authenticated(refreshed));
          });
        });

        return true;
      },
    );
  }

  Future<bool> login({
    required String email,
    required String password,
    String? baseUrl,
  }) async {
    emit(const AuthLoading());
    final result = await authRepo.signIn(
      email: email,
      password: password,
      baseUrl: baseUrl,
    );

    return result.fold(
      (failure) {
        emit(AuthError(failure.message));
        return false;
      },
      (user) async {
        emit(Authenticated(user));

        final pubSubToken = user.pubsubToken ?? await storage.getPubSubToken();
        if (pubSubToken != null) {
          ws.connect(
            pubSubToken: pubSubToken,
            accountId: user.accountId,
            userId: user.id,
          );
        }

        return true;
      },
    );
  }

  Future<void> switchAccount(int accountId) async {
    final result = await authRepo.setActiveAccount(accountId);
    result.fold((_) {}, (_) async {
      final profileResult = await authRepo.getProfile();
      profileResult.fold((_) {}, (refreshed) async {
        emit(Authenticated(refreshed));
        final pubSubToken = refreshed.pubsubToken ?? await storage.getPubSubToken();
        if (pubSubToken != null) {
          ws.disconnect();
          ws.connect(
            pubSubToken: pubSubToken,
            accountId: refreshed.accountId,
            userId: refreshed.id,
          );
        }
      });
    });
  }

  Future<void> updateAvailability(String availability) async {
    if (state is! Authenticated) return;
    final current = (state as Authenticated).user;

    final result = await authRepo.updateAvailability(availability);
    result.fold((_) {}, (_) {
      emit(Authenticated(current.copyWith(availabilityStatus: availability)));
    });
  }

  Future<void> logout() async {
    ws.disconnect();
    await authRepo.signOut();
    emit(const Unauthenticated());
  }
}
