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
