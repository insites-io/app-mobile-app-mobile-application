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
    // The account is now verified-and-authenticated; any signup token
    // stashed for the resend-verification recovery flow is dead weight.
    await secureStorage.clearPendingSignup();

    // Fetch full profile from /me to get all fields (e.g. profile_picture_url)
    // that the login response may not include.
    try {
      return await getCurrentUser();
    } catch (_) {
      return user;
    }
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

    // Stash the signup JWT so a later sign-in retry on the same
    // unverified account can resurrect it for resend-verification,
    // even if the user has killed the app in between.
    await secureStorage.savePendingSignup(token: token, email: email);

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

  /// Update the current user's profile. Only sends fields that have values.
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? profilePictureUrl,
  }) async {
    final token = await secureStorage.getToken();
    if (token == null) {
      throw AuthException('Not authenticated.');
    }

    final data = <String, dynamic>{'token': token};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (email != null) data['email'] = email;
    if (profilePictureUrl != null) {
      data['profile_picture_url'] = profilePictureUrl;
    }

    final response = await apiClient.post(
      '/api/mobile/update-profile',
      data: data,
    );

    if (response['success'] != true) {
      throw AuthException(
        response['error'] as String? ?? 'Failed to update profile.',
      );
    }

    // If the email was changed, update the stored email.
    if (email != null) {
      await secureStorage.saveEmail(email);
    }

    return User.fromJson(response['user'] as Map<String, dynamic>);
  }

  /// Change the user's password. On success the server destroys the session.
  Future<String> changePassword(String newPassword) async {
    final token = await secureStorage.getToken();
    if (token == null) {
      throw AuthException('Not authenticated.');
    }

    final response = await apiClient.post(
      '/api/mobile/change-password',
      data: {'token': token, 'new_password': newPassword},
    );

    if (response['success'] != true) {
      throw AuthException(
        response['error'] as String? ?? 'Failed to change password.',
      );
    }

    return response['message'] as String? ??
        'Password changed successfully. Please log in again.';
  }

  /// Request a password reset email.
  ///
  /// The backend intentionally returns the same success response regardless
  /// of whether the email exists, to prevent enumeration. Callers should
  /// show the same confirmation message on success and on recoverable
  /// failure, and only surface the error for malformed input (e.g. missing
  /// email).
  Future<String> forgotPassword(String email) async {
    final response = await apiClient.post(
      '/api/mobile/forgot-password',
      data: {'email': email},
    );

    if (response['success'] != true) {
      throw AuthException(
        response['error'] as String? ?? 'Failed to request password reset.',
      );
    }

    return response['message'] as String? ??
        'If an account exists with that email, a password reset link has been sent.';
  }

  /// Submit a new password using the token from the reset email.
  ///
  /// The token is single-use and expires after 24 hours. Do not store or
  /// cache it. On success the server invalidates the token, so callers
  /// should route the user back to sign in rather than attempting another
  /// reset with the same token.
  Future<String> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final response = await apiClient.post(
      '/api/mobile/reset-password',
      data: {
        'email': email,
        'token': token,
        'new_password': newPassword,
      },
    );

    if (response['success'] != true) {
      throw AuthException(
        response['error'] as String? ?? 'Failed to reset password.',
      );
    }

    return response['message'] as String? ??
        'Password has been reset successfully. Please log in with your new password.';
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
