import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired on app launch to restore a previous session.
final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Fired when the user submits the login form.
final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Fired when the user submits the signup form.
final class AuthSignupRequested extends AuthEvent {
  const AuthSignupRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
  });

  final String email;
  final String password;
  final String firstName;
  final String lastName;

  @override
  List<Object?> get props => [email, password, firstName, lastName];
}

/// Fired when the user taps logout.
final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Fired when the user updates their profile.
final class AuthProfileUpdateRequested extends AuthEvent {
  const AuthProfileUpdateRequested({
    this.firstName,
    this.lastName,
    this.email,
    this.profilePictureUrl,
  });

  final String? firstName;
  final String? lastName;
  final String? email;
  final String? profilePictureUrl;

  @override
  List<Object?> get props => [firstName, lastName, email, profilePictureUrl];
}

/// Fired when the user changes their password.
final class AuthPasswordChangeRequested extends AuthEvent {
  const AuthPasswordChangeRequested({required this.newPassword});

  final String newPassword;

  @override
  List<Object?> get props => [newPassword];
}

/// Fired when the user requests a password reset email.
final class AuthForgotPasswordRequested extends AuthEvent {
  const AuthForgotPasswordRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

/// Fired when the user submits a new password using a reset token.
final class AuthResetPasswordRequested extends AuthEvent {
  const AuthResetPasswordRequested({
    required this.email,
    required this.token,
    required this.newPassword,
  });

  final String email;
  final String token;
  final String newPassword;

  @override
  List<Object?> get props => [email, token, newPassword];
}
