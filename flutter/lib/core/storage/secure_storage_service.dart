import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around [FlutterSecureStorage] for JWT and email persistence.
class SecureStorageService {
  SecureStorageService();

  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'jwt_token';
  static const _emailKey = 'user_email';

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveEmail(String email) =>
      _storage.write(key: _emailKey, value: email);

  Future<String?> getEmail() => _storage.read(key: _emailKey);

  Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _emailKey);
  }
}
