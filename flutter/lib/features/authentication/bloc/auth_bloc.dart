import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignupRequested>(_onSignupRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthProfileUpdateRequested>(_onProfileUpdateRequested);
    on<AuthPasswordChangeRequested>(_onPasswordChangeRequested);
    on<AuthForgotPasswordRequested>(_onForgotPasswordRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
  }

  final AuthRepository authRepository;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.tryRestoreSession();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.login(event.email, event.password);
      emit(AuthAuthenticated(user));
    } on AuthException catch (e) {
      if (e.errorCode == 'email_not_verified') {
        emit(AuthEmailVerificationRequired(email: event.email));
      } else {
        emit(AuthUnauthenticated(e.message));
      }
    } on ApiException catch (e) {
      emit(AuthUnauthenticated(e.message));
    } catch (_) {
      emit(const AuthUnauthenticated('An unexpected error occurred.'));
    }
  }

  Future<void> _onSignupRequested(
    AuthSignupRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      // Check email availability first.
      final available = await authRepository.checkEmail(event.email);
      if (!available) {
        emit(const AuthUnauthenticated(
          'This email is already registered. Please log in.',
        ));
        return;
      }

      final result = await authRepository.signup(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
      );
      emit(AuthEmailVerificationRequired(
        email: event.email,
        token: result.token,
      ));
    } on AuthException catch (e) {
      emit(AuthUnauthenticated(e.message));
    } on ApiException catch (e) {
      emit(AuthUnauthenticated(e.message));
    } catch (_) {
      emit(const AuthUnauthenticated('An unexpected error occurred.'));
    }
  }

  Future<void> _onProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state is AuthAuthenticated
        ? (state as AuthAuthenticated).user
        : null;
    if (currentUser == null) return;

    emit(const AuthLoading());
    try {
      final updatedUser = await authRepository.updateProfile(
        firstName: event.firstName,
        lastName: event.lastName,
        email: event.email,
        profilePictureUrl: event.profilePictureUrl,
      );
      emit(AuthProfileUpdated(updatedUser));
      emit(AuthAuthenticated(updatedUser));
    } on AuthException catch (e) {
      emit(AuthProfileError(currentUser, e.message));
    } on ApiException catch (e) {
      emit(AuthProfileError(currentUser, e.message));
    } catch (_) {
      emit(AuthProfileError(currentUser, 'An unexpected error occurred.'));
    }
  }

  Future<void> _onPasswordChangeRequested(
    AuthPasswordChangeRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state is AuthAuthenticated
        ? (state as AuthAuthenticated).user
        : null;
    if (currentUser == null) return;

    emit(const AuthLoading());
    try {
      final message = await authRepository.changePassword(event.newPassword);
      await authRepository.secureStorage.clearAll();
      emit(AuthPasswordChanged(message));
    } on AuthException catch (e) {
      emit(AuthProfileError(currentUser, e.message));
    } on ApiException catch (e) {
      emit(AuthProfileError(currentUser, e.message));
    } catch (_) {
      emit(AuthProfileError(currentUser, 'An unexpected error occurred.'));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await authRepository.logout();
    } finally {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthForgotPasswordInProgress());
    try {
      await authRepository.forgotPassword(event.email);
    } on AuthException {
      // Swallow recoverable errors so we show the same confirmation
      // regardless of whether the email exists — prevents enumeration.
    } on ApiException {
      // Same rationale: treat network/API failures as a silent success
      // to avoid leaking information. The user can retry if the email
      // truly did not send.
    } catch (_) {
      // Unknown failure — still present the generic confirmation.
    }
    emit(const AuthForgotPasswordSubmitted());
  }

  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthResetPasswordInProgress());
    try {
      final message = await authRepository.resetPassword(
        email: event.email,
        token: event.token,
        newPassword: event.newPassword,
      );
      // Even though the server may keep existing JWTs valid, clear any
      // local credentials as a safety measure so the app falls back to
      // an unauthenticated state.
      await authRepository.secureStorage.clearAll();
      emit(AuthPasswordResetSucceeded(message));
    } on AuthException catch (e) {
      emit(AuthPasswordResetFailed(e.message));
    } on ApiException catch (e) {
      emit(AuthPasswordResetFailed(e.message));
    } catch (_) {
      emit(const AuthPasswordResetFailed('An unexpected error occurred.'));
    }
  }
}
