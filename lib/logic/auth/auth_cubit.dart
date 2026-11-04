import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/network/websocket_client.dart';
import '../../core/services/push_notification_service.dart';
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

        // Register FCM device token
        PushNotificationService.registerDeviceToken();

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

        // Register FCM device token
        PushNotificationService.registerDeviceToken();

        return true;
      },
    );
  }

  Future<bool> loginWithGoogle(String idToken) async {
    emit(const AuthLoading());
    final result = await authRepo.signInWithGoogle(idToken);

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

        // Register FCM device token
        PushNotificationService.registerDeviceToken();

        return true;
      },
    );
  }

  Future<void> switchAccount(int accountId) async {
    final currentAccounts = currentUser?.accounts ?? [];
    await storage.saveActiveAccountId(accountId);

    if (currentUser != null) {
      emit(Authenticated(currentUser!.copyWith(accountId: accountId)));
    }

    final result = await authRepo.setActiveAccount(accountId);
    await result.fold(
      (failure) async {},
      (_) async {
        final profileResult = await authRepo.getProfile();
        await profileResult.fold(
          (_) async {},
          (refreshed) async {
            final finalUser = refreshed.accounts.isEmpty && currentAccounts.isNotEmpty
                ? refreshed.copyWith(accounts: currentAccounts)
                : refreshed;
            emit(Authenticated(finalUser));

            final pubSubToken = finalUser.pubsubToken ?? await storage.getPubSubToken();
            if (pubSubToken != null) {
              ws.disconnect();
              ws.connect(
                pubSubToken: pubSubToken,
                accountId: finalUser.accountId,
                userId: finalUser.id,
              );
            }
          },
        );
      },
    );
  }

  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? displayName,
    String? email,
  }) async {
    final result = await authRepo.updateProfile(
      name: name,
      displayName: displayName,
      email: email,
    );

    return result.fold(
      (failure) => Left(failure),
      (updatedUser) {
        emit(Authenticated(updatedUser));
        return Right(updatedUser);
      },
    );
  }

  Future<Either<Failure, void>> updateAvailability(String availability) async {
    if (state is! Authenticated) {
      return const Left(ServerFailure('المستخدم غير مسجل'));
    }
    final current = (state as Authenticated).user;

    // Immediately update state so UI responds without delay
    emit(Authenticated(current.copyWith(availabilityStatus: availability)));

    // Persist to local storage
    final savedUserMap = await storage.getUserData();
    if (savedUserMap != null) {
      savedUserMap['availability_status'] = availability;
      savedUserMap['availability'] = availability;
      await storage.saveUserData(savedUserMap);
    }

    final result = await authRepo.updateAvailability(availability);
    return result.fold(
      (failure) {
        // Rollback on failure
        emit(Authenticated(current));
        return Left(failure);
      },
      (_) => const Right(null),
    );
  }

  Future<void> logout() async {
    ws.disconnect();
    await PushNotificationService.unregisterDeviceToken();
    await authRepo.signOut();
    emit(const Unauthenticated());
  }
}
