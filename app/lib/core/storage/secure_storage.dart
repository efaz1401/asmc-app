import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around `flutter_secure_storage` so we can swap it out in tests.
class SecureStorage {
  SecureStorage(this._storage);

  static const _accessKey = 'asmc.access_token';
  static const _refreshKey = 'asmc.refresh_token';
  static const _userKey = 'asmc.current_user';
  static const _biometricKey = 'asmc.biometric_enabled';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);
  Future<void> writeAccessToken(String? token) => token == null
      ? _storage.delete(key: _accessKey)
      : _storage.write(key: _accessKey, value: token);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);
  Future<void> writeRefreshToken(String? token) => token == null
      ? _storage.delete(key: _refreshKey)
      : _storage.write(key: _refreshKey, value: token);

  Future<String?> readUserJson() => _storage.read(key: _userKey);
  Future<void> writeUserJson(String? json) => json == null
      ? _storage.delete(key: _userKey)
      : _storage.write(key: _userKey, value: json);

  Future<bool> isBiometricEnabled() async =>
      (await _storage.read(key: _biometricKey)) == 'true';
  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _biometricKey, value: enabled.toString());

  Future<void> clearAuth() async {
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
      _storage.delete(key: _userKey),
    ]);
  }
}

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage(const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ));
});
