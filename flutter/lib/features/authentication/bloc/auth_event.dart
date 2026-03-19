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
