import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/auth_models.dart';

class AuthRepository {
  AuthRepository(this._client);
  final ApiClient _client;

  Dio get _dio => _client.dio;

  Future<AuthSession> login({required String email, required String password}) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: Options(extra: {'skipAuth': true}),
      );
      return AuthSession.fromJson(resp.data!);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AuthSession> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
          if (phone != null) 'phone': phone,
        },
        options: Options(extra: {'skipAuth': true}),
      );
      return AuthSession.fromJson(resp.data!);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await _dio.post(
        '/auth/forgot-password',
        data: {'email': email},
        options: Options(extra: {'skipAuth': true}),
      );
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String code,
    String purpose = 'RESET_PASSWORD',
  }) async {
    try {
      await _dio.post(
        '/auth/verify-otp',
        data: {'email': email, 'code': code, 'purpose': purpose},
        options: Options(extra: {'skipAuth': true}),
      );
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/auth/reset-password',
        data: {'email': email, 'code': code, 'newPassword': newPassword},
        options: Options(extra: {'skipAuth': true}),
      );
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AuthUser> me() async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>('/auth/me');
      final user = (resp.data!['user']) as Map<String, dynamic>;
      return AuthUser.fromJson(user);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );
    } catch (_) {
      // best-effort
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});
