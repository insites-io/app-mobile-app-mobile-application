import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around [FlutterSecureStorage] for JWT and email persistence.
class SecureStorageService {
  SecureStorageService();

  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'jwt_token';
  static const _emailKey = 'user_email';
  static const _pendingSignupTokenKey = 'pending_signup_token';
  static const _pendingSignupEmailKey = 'pending_signup_email';

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

  /// Persist the signup JWT alongside the email it was issued for, so a
  /// sign-in retry on an unverified account can still resend the
  /// verification email. Independent of [saveToken] / [saveEmail], which
  /// track the authenticated session.
  Future<void> savePendingSignup({
    required String token,
    required String email,
  }) async {
    await _storage.write(key: _pendingSignupTokenKey, value: token);
    await _storage.write(
      key: _pendingSignupEmailKey,
      value: email.trim().toLowerCase(),
    );
  }

  /// Return the pending signup token only if the stored email matches
  /// [forEmail] (whitespace- and case-insensitive). Guards against
  /// resending a token issued for a different account.
  Future<String?> getPendingSignupToken({required String forEmail}) async {
    final storedEmail = await _storage.read(key: _pendingSignupEmailKey);
    if (storedEmail == null) return null;
    if (storedEmail != forEmail.trim().toLowerCase()) return null;
    return _storage.read(key: _pendingSignupTokenKey);
  }

  /// Remove the pending signup credentials. Called once the account is
  /// verified-and-authenticated, so the leftover token can't shadow a
  /// future signup attempt.
  Future<void> clearPendingSignup() async {
    await _storage.delete(key: _pendingSignupTokenKey);
    await _storage.delete(key: _pendingSignupEmailKey);
  }
}
