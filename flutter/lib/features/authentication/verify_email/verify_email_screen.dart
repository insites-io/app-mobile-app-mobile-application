import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../bloc/auth_bloc.dart';
import '../data/repositories/auth_repository.dart';
import '../sign_in/sign_in_screen.dart';
import '../../welcome/welcome_screen.dart';

/// Shown after signup or when login is rejected due to an unverified email.
///
/// If [token] is provided (either fresh from signup or restored from secure
/// storage on a sign-in retry), the user can request a verification email.
/// If null (no pending signup on this device for this email), tapping resend
/// surfaces a contact-support fallback message.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.token,
  });

  final String email;
  final String? token;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _sending = false;
  bool _sent = false;
  String? _error;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _onSendVerificationEmail() async {
    if (_cooldown > 0) return;

    if (widget.token == null) {
      setState(() {
        _error =
            "We can't send a verification email automatically. "
            "If you can't find the original email, please contact support.";
      });
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await context
          .read<AuthBloc>()
          .authRepository
          .sendVerificationEmail(widget.token!);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
        _cooldown = 30;
      });
      _startCooldown();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Failed to send verification email. Please try again.';
      });
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const SignInScreen(),
      ),
      (_) => false,
    );
  }

  void _navigateToWelcome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
          onPressed: _navigateToWelcome,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Verify Your Email',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We need to verify your email address. '
                'Tap the button below to receive a verification email, '
                'then check your inbox and click the link.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Email display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.email,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Success banner
              if (_sent && _error == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Verification email sent! Check your inbox.',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Error banner
              if (_error != null)
                Padding(
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
                            _error!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              AppPrimaryButton(
                label: _cooldown > 0
                    ? 'RESEND IN ${_cooldown}s'
                    : _sent
                        ? 'RESEND VERIFICATION EMAIL'
                        : 'SEND VERIFICATION EMAIL',
                isLoading: _sending,
                onPressed:
                    _sending || _cooldown > 0 ? null : _onSendVerificationEmail,
              ),

              const SizedBox(height: 16),
              AppSecondaryButton(
                label: "I'VE ALREADY VERIFIED",
                onPressed: _navigateToLogin,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
