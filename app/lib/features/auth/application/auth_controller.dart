import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';
import '../domain/auth_models.dart';

/// Top-level authentication state.
class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.error,
  });

  final AuthStatus status;
  final AuthUser? user;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  AuthState copyWith({AuthStatus? status, AuthUser? user, String? error, bool clearUser = false}) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      error: error,
    );
  }

  static const AuthState initial = AuthState(status: AuthStatus.unknown);
}

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repo;
  late final SecureStorage _storage;
  late final ApiClient _client;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  AuthState build() {
    _repo = ref.read(authRepositoryProvider);
    _storage = ref.read(secureStorageProvider);
    _client = ref.read(apiClientProvider);
    _client.onUnauthorized = _forceLogout;
    return AuthState.initial;
  }

  Future<void> bootstrap() async {
    try {
      final access = await _storage.readAccessToken();
      final userJson = await _storage.readUserJson();
      if (access == null || userJson == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated, clearUser: true);
        return;
      }
      final user = AuthUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      // Refresh in background; ignore failures (interceptor handles them)
      _repo.me().then((u) {
        state = state.copyWith(status: AuthStatus.authenticated, user: u);
        _storage.writeUserJson(jsonEncode(u.toJson()));
      }).catchError((_) {});
    } catch (_) {
      // Storage / parse failures must not leave the UI stuck on splash.
      try {
        await _storage.clearAuth();
      } catch (_) {}
      state = state.copyWith(status: AuthStatus.unauthenticated, clearUser: true);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.unknown, error: null);
    try {
      final session = await _repo.login(email: email, password: password);
      await _persist(session);
      state = AuthState(status: AuthStatus.authenticated, user: session.user);
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: e.toString());
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final session = await _repo.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      await _persist(session);
      state = AuthState(status: AuthStatus.authenticated, user: session.user);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> requestPasswordReset(String email) => _repo.requestPasswordReset(email);

  Future<void> verifyOtp(String email, String code) =>
      _repo.verifyOtp(email: email, code: code);

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) =>
      _repo.resetPassword(email: email, code: code, newPassword: newPassword);

  Future<void> logout() async {
    final refresh = await _storage.readRefreshToken();
    if (refresh != null) await _repo.logout(refresh);
    await _storage.clearAuth();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> isBiometricEnabled() => _storage.isBiometricEnabled();

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.setBiometricEnabled(enabled);

  /// Attempts a biometric login using the previously persisted session.
  /// Returns true on success.
  Future<bool> tryBiometricLogin() async {
    if (!await _storage.isBiometricEnabled()) return false;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;
      final ok = await _localAuth.authenticate(
        localizedReason: 'Sign in to ASMC Workforce',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!ok) return false;
      await bootstrap();
      return state.isAuthenticated;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persist(AuthSession session) async {
    await _storage.writeAccessToken(session.accessToken);
    await _storage.writeRefreshToken(session.refreshToken);
    await _storage.writeUserJson(jsonEncode(session.user.toJson()));
  }

  Future<void> _forceLogout() async {
    await _storage.clearAuth();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
