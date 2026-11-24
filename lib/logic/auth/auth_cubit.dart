import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/websocket_client.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/conversation_repository.dart';
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
        if (sl.isRegistered<IConversationRepository>()) {
          sl<IConversationRepository>().clearCache();
        }
        await storage.saveActiveAccountId(user.accountId);
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
        if (sl.isRegistered<IConversationRepository>()) {
          sl<IConversationRepository>().clearCache();
        }
        await storage.saveActiveAccountId(user.accountId);
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
    if (sl.isRegistered<IConversationRepository>()) {
      sl<IConversationRepository>().clearCache();
    }

    final result = await authRepo.setActiveAccount(accountId);
    await result.fold(
      (failure) async {
        if (currentUser != null) {
          emit(Authenticated(currentUser!.copyWith(accountId: accountId)));
        }
      },
      (_) async {
        final profileResult = await authRepo.getProfile();
        await profileResult.fold(
          (_) async {
            if (currentUser != null) {
              emit(Authenticated(currentUser!.copyWith(accountId: accountId)));
            }
          },
          (refreshed) async {
            final finalUser = (refreshed.accounts.isEmpty && currentAccounts.isNotEmpty
                ? refreshed.copyWith(accounts: currentAccounts)
                : refreshed).copyWith(accountId: accountId);
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

  Future<Either<Failure, void>> updateAvailability(
    String availability, {
    int? breakDurationMinutes,
  }) async {
    if (state is! Authenticated) {
      return const Left(ServerFailure('المستخدم غير مسجل'));
    }
    final current = (state as Authenticated).user;
    final isBreak = availability == 'break' || availability == 'on_break';
    final apiStatus = isBreak ? 'break' : availability;

    final breakEndsAt = (isBreak && breakDurationMinutes != null)
        ? DateTime.now().add(Duration(minutes: breakDurationMinutes.clamp(1, 120)))
        : null;

    final updatedAccounts = current.accounts.map((a) {
      if (a.id == current.accountId) {
        return a.copyWith(
          breakEndsAt: breakEndsAt,
          availabilityStatus: apiStatus,
        );
      }
      return a;
    }).toList();

    final updatedUser = current.copyWith(
      availabilityStatus: apiStatus,
      accounts: updatedAccounts,
    );

    // Immediately update state so UI responds without delay
    emit(Authenticated(updatedUser));

    // Persist to local storage
    final savedUserMap = await storage.getUserData();
    if (savedUserMap != null) {
      savedUserMap['availability_status'] = apiStatus;
      savedUserMap['availability'] = apiStatus;
      if (breakEndsAt != null) {
        savedUserMap['break_ends_at'] = breakEndsAt.toIso8601String();
      } else {
        savedUserMap.remove('break_ends_at');
      }
      await storage.saveUserData(savedUserMap);
    }

    final result = await authRepo.updateAvailability(
      status: apiStatus,
      breakDurationMinutes: breakDurationMinutes,
      accountId: current.accountId,
    );

    return result.fold(
      (failure) {
        // Rollback on failure
        emit(Authenticated(current));
        return Left(failure);
      },
      (_) async {
        // Silently sync latest from GET /api/v1/profile
        try {
          final pRes = await authRepo.getProfile();
          pRes.fold((_) {}, (freshUser) {
            emit(Authenticated(freshUser));
          });
        } catch (_) {}
        return const Right(null);
      },
    );
  }

  Future<void> endBreakEarly() async {
    await updateAvailability('online');
  }

  Future<void> refreshProfile() async {
    try {
      final pRes = await authRepo.getProfile();
      pRes.fold((_) {}, (freshUser) {
        emit(Authenticated(freshUser));
      });
    } catch (_) {}
  }

  Future<Either<Failure, void>> resetPassword(String email) async {
    return await authRepo.resetPassword(email);
  }

  Future<void> logout() async {
    ws.disconnect();
    await PushNotificationService.unregisterDeviceToken();
    await authRepo.signOut();
    if (sl.isRegistered<IConversationRepository>()) {
      sl<IConversationRepository>().clearCache();
    }
    emit(const Unauthenticated());
  }
}
