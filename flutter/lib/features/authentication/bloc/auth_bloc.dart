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
      emit(AuthUnauthenticated(e.message));
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

      final user = await authRepository.signup(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
      );
      emit(AuthAuthenticated(user));
    } on AuthException catch (e) {
      emit(AuthUnauthenticated(e.message));
    } on ApiException catch (e) {
      emit(AuthUnauthenticated(e.message));
    } catch (_) {
      emit(const AuthUnauthenticated('An unexpected error occurred.'));
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
}
