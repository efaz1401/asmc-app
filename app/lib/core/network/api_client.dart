import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../env.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';

/// Configures Dio with:
///   - base URL
///   - JWT bearer interceptor
///   - automatic refresh-token retry on 401
///   - normalized error mapping into [ApiException]
class ApiClient {
  ApiClient(this._storage)
      : dio = Dio(BaseOptions(
          baseUrl: AppEnv.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          contentType: 'application/json',
          headers: {'Accept': 'application/json'},
        )) {
    dio.interceptors.add(_authInterceptor());
  }

  final Dio dio;
  final SecureStorage _storage;

  /// External hook used by AuthController to clear session on hard auth failures.
  void Function()? onUnauthorized;

  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.extra['skipAuth'] != true) {
          final token = await _storage.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        // 401 → try refreshing once, then replay the request.
        final response = err.response;
        if (response?.statusCode == 401 &&
            err.requestOptions.extra['retried'] != true &&
            err.requestOptions.path != '/auth/refresh') {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            final req = err.requestOptions;
            req.extra['retried'] = true;
            try {
              final token = await _storage.readAccessToken();
              if (token != null) req.headers['Authorization'] = 'Bearer $token';
              final retried = await dio.fetch(req);
              return handler.resolve(retried);
            } catch (_) {
              // fall through to logout
            }
          }
          await _storage.clearAuth();
          onUnauthorized?.call();
        }
        handler.next(err);
      },
    );
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) return false;
    try {
      final resp = await dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );
      final data = resp.data;
      if (data == null) return false;
      await _storage.writeAccessToken(data['accessToken'] as String?);
      await _storage.writeRefreshToken(data['refreshToken'] as String?);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Convert any thrown [DioException] into a friendly [ApiException].
ApiException mapDioError(Object error) {
  if (error is ApiException) return error;
  if (error is! DioException) {
    return ApiException(message: error.toString());
  }
  final response = error.response;
  if (response != null) {
    final data = response.data;
    String message = 'Request failed (${response.statusCode}).';
    String? code;
    Object? details;
    if (data is Map) {
      final err = data['error'];
      if (err is Map) {
        message = (err['message'] as String?) ?? message;
        code = err['code'] as String?;
        details = err['details'];
      }
    }
    return ApiException(
      message: message,
      statusCode: response.statusCode,
      code: code,
      details: details,
    );
  }
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return ApiException(message: 'Network timeout. Please try again.');
    case DioExceptionType.connectionError:
      return ApiException(message: 'Cannot reach server. Check your connection.');
    default:
      return ApiException(message: error.message ?? 'Network error');
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage);
});
