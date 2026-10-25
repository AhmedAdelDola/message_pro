import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';
import '../core/storage/secure_storage_service.dart';
import '../core/network/websocket_client.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? errorMessage,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo = AuthRepository();
  final SecureStorageService _storage = SecureStorageService();
  final ActionCableClient _ws = ActionCableClient();

  AuthNotifier() : super(const AuthState());

  Future<bool> restoreSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final headers = await _storage.getAuthHeaders();
      final savedUserMap = await _storage.getUserData();

      if (headers != null && savedUserMap != null) {
        final user = User.fromJson(savedUserMap);
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );

        // Connect WebSocket in background
        final pubSubToken = user.pubsubToken ?? await _storage.getPubSubToken();
        if (pubSubToken != null) {
          _ws.connect(
            pubSubToken: pubSubToken,
            accountId: user.accountId,
            userId: user.id,
          );
        }

        // Refresh profile in background
        _repo.getProfile().then((refreshed) {
          if (refreshed != null) {
            state = state.copyWith(user: refreshed);
          }
        });

        return true;
      }
    } catch (_) {}

    state = state.copyWith(isLoading: false, isAuthenticated: false);
    return false;
  }

  Future<bool> login({
    required String email,
    required String password,
    String? baseUrl,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repo.signIn(
        email: email,
        password: password,
        baseUrl: baseUrl,
      );

      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );

      // Connect WebSocket
      final pubSubToken = user.pubsubToken ?? await _storage.getPubSubToken();
      if (pubSubToken != null) {
        _ws.connect(
          pubSubToken: pubSubToken,
          accountId: user.accountId,
          userId: user.id,
        );
      }

      return true;
    } catch (e) {
      String msg = 'Invalid email or password. Please try again.';
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    }
  }

  Future<void> switchAccount(int accountId) async {
    try {
      await _repo.setActiveAccount(accountId);
      final refreshed = await _repo.getProfile();
      if (refreshed != null) {
        state = state.copyWith(user: refreshed);
        final pubSubToken = refreshed.pubsubToken ?? await _storage.getPubSubToken();
        if (pubSubToken != null) {
          _ws.disconnect();
          _ws.connect(
            pubSubToken: pubSubToken,
            accountId: refreshed.accountId,
            userId: refreshed.id,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> updateAvailability(String availability) async {
    if (state.user == null) return;
    try {
      await _repo.updateAvailability(availability);
      state = state.copyWith(
        user: state.user!.copyWith(availabilityStatus: availability),
      );
    } catch (_) {}
  }

  Future<void> logout() async {
    _ws.disconnect();
    await _repo.signOut();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
