import 'package:equatable/equatable.dart';

import '../data/models/user_model.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any auth check has run.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// A login or session-restore request is in flight.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// The user is authenticated. Holds the current [User].
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final User user;

  @override
  List<Object?> get props => [user.id];
}

/// The user is not authenticated. Optionally carries an [error] message
/// from a failed login attempt.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated([this.error]);

  final String? error;

  @override
  List<Object?> get props => [error];
}

/// Profile was updated successfully.
final class AuthProfileUpdated extends AuthState {
  const AuthProfileUpdated(this.user);

  final User user;

  @override
  List<Object?> get props => [user.id, user.email, user.firstName];
}

/// Password was changed — user must re-authenticate.
final class AuthPasswordChanged extends AuthState {
  const AuthPasswordChanged(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// A profile operation failed. Keeps the user authenticated.
final class AuthProfileError extends AuthState {
  const AuthProfileError(this.user, this.error);

  final User user;
  final String error;

  @override
  List<Object?> get props => [user.id, error];
}

/// A forgot-password request is in flight. Rendered as a loading state on
/// the Forgot Password screen without clobbering the global unauthenticated
/// state.
final class AuthForgotPasswordInProgress extends AuthState {
  const AuthForgotPasswordInProgress();
}

/// Confirmation to display after a forgot-password submission, regardless
/// of whether the email exists server-side (the backend intentionally does
/// not distinguish to prevent enumeration).
final class AuthForgotPasswordSubmitted extends AuthState {
  const AuthForgotPasswordSubmitted();
}

/// A reset-password request (new password submission) is in flight.
final class AuthResetPasswordInProgress extends AuthState {
  const AuthResetPasswordInProgress();
}

/// The password reset completed successfully. The local session has been
/// cleared; the user must sign in with the new password.
final class AuthPasswordResetSucceeded extends AuthState {
  const AuthPasswordResetSucceeded(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// The password reset failed (invalid/expired token, network, etc.).
/// The screen should surface [error] and offer a way to request a new link.
final class AuthPasswordResetFailed extends AuthState {
  const AuthPasswordResetFailed(this.error);

  final String error;

  @override
  List<Object?> get props => [error];
}

/// Email verification is required before the user can log in.
///
/// Carries the [email] for display and an optional [token] from signup
/// (needed to call send-verification-email). When arriving from a failed
/// login, [token] will be null.
final class AuthEmailVerificationRequired extends AuthState {
  const AuthEmailVerificationRequired({
    required this.email,
    this.token,
  });

  final String email;
  final String? token;

  @override
  List<Object?> get props => [email, token];
}
