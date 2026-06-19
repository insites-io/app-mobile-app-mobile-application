import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../verify_email/verify_email_screen.dart';
import '../../welcome/welcome_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _submitted = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSignUp() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
          AuthSignupRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
          ),
        );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthEmailVerificationRequired) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => VerifyEmailScreen(
                email: state.email,
                token: state.token,
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon:
                const Icon(Icons.chevron_left, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => const WelcomeScreen(),
                ),
                (_) => false,
              );
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Create an account',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // API error banner
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      if (!_submitted) return const SizedBox.shrink();
                      final error =
                          state is AuthUnauthenticated ? state.error : null;
                      if (error == null) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  error,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  AppTextField(
                    label: 'First Name *',
                    placeholder: 'First Name',
                    keyboardType: TextInputType.name,
                    controller: _firstNameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'First name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Last Name *',
                    placeholder: 'Last Name',
                    keyboardType: TextInputType.name,
                    controller: _lastNameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Last name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Email *',
                    placeholder: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Password *',
                    placeholder: 'Password',
                    obscureText: _obscurePassword,
                    controller: _passwordController,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Confirm Password *',
                    placeholder: 'Confirm Password',
                    obscureText: _obscureConfirmPassword,
                    controller: _confirmPasswordController,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () => _obscureConfirmPassword =
                            !_obscureConfirmPassword,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return AppPrimaryButton(
                        label: 'CREATE AN ACCOUNT',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _onSignUp,
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
