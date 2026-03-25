import '../../../../core/api/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

/// Orchestrates authentication calls against the IIA backend.
///
/// Manages two persistence layers:
/// - **JWT token** (via [SecureStorageService]) for authenticated requests.
/// - **User email** (via [SecureStorageService]) required by validate-token.
class AuthRepository {
  const AuthRepository({
    required this.apiClient,
    required this.secureStorage,
  });

  final ApiClient apiClient;
  final SecureStorageService secureStorage;

  /// Authenticate with email/password. Stores JWT + email on success.
  Future<User> login(String email, String password) async {
    final response = await apiClient.post(
      '/api/mobile/login',
      data: {'email': email, 'password': password},
    );

    if (response['success'] != true) {
      throw AuthException(
        response['error'] as String? ?? 'Login failed.',
        errorCode: response['error_code'] as String?,
      );
    }

    final user = User.fromJson(response['user'] as Map<String, dynamic>);
    final token = response['token'] as String;

    await secureStorage.saveToken(token);
    await secureStorage.saveEmail(email);

    return user;
  }

  /// End the server session and clear all local credentials.
  Future<void> logout() async {
    try {
      await apiClient.post('/api/mobile/logout');
    } finally {
      await secureStorage.clearAll();
    }
  }

  /// Fetch the current user using the stored JWT token.
  Future<User> getCurrentUser() async {
    final token = await secureStorage.getToken();
    if (token == null) {
      throw AuthException('Not authenticated.');
    }

    final response = await apiClient.post(
      '/api/mobile/me',
      data: {'token': token},
    );

    if (response['success'] != true) {
      throw AuthException(
        response['error'] as String? ?? 'Not authenticated.',
      );
    }

    return User.fromJson(response['user'] as Map<String, dynamic>);
  }

  /// Check whether an email is available for registration.
  Future<bool> checkEmail(String email) async {
    final response = await apiClient.post(
      '/api/mobile/check-email',
      data: {'email': email},
    );

    if (response['success'] != true) {
      throw AuthException(response['error'] as String? ?? 'Check failed.');
    }

    return response['available'] == true;
  }

  /// Register a new user. Returns user and token but does NOT store them
  /// as an authenticated session — email verification is required first.
  Future<({User user, String token})> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await apiClient.post(
      '/api/mobile/signup',
      data: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      },
    );

    if (response['success'] != true) {
      throw AuthException(
        response['error'] as String? ?? 'Signup failed.',
      );
    }

    final user = User.fromJson(response['user'] as Map<String, dynamic>);
    final token = response['token'] as String;

    return (user: user, token: token);
  }

  /// Send a verification email using the JWT token from signup.
  Future<void> sendVerificationEmail(String token) async {
    final response = await apiClient.post(
      '/api/mobile/send-verification-email',
      data: {'token': token},
    );

    if (response['success'] != true) {
      throw AuthException(
        response['error'] as String? ?? 'Failed to send verification email.',
      );
    }
  }

  /// Check whether the stored JWT is still valid.
  Future<bool> validateToken() async {
    final token = await secureStorage.getToken();
    final email = await secureStorage.getEmail();

    if (token == null || email == null) return false;

    final response = await apiClient.post(
      '/api/mobile/validate-token',
      data: {'email': email, 'token': token},
    );

    return response['success'] == true;
  }

  /// Called on app launch: validate stored JWT → fetch user → or clear state.
  Future<User?> tryRestoreSession() async {
    final isValid = await validateToken();
    if (!isValid) {
      await secureStorage.clearAll();
      return null;
    }

    try {
      return await getCurrentUser();
    } catch (_) {
      await secureStorage.clearAll();
      return null;
    }
  }
}

/// Thrown when the API returns `"success": false`.
class AuthException implements Exception {
  const AuthException(this.message, {this.errorCode});

  final String message;

  /// Optional error code from the API (e.g. `"email_not_verified"`).
  final String? errorCode;

  @override
  String toString() => message;
}
