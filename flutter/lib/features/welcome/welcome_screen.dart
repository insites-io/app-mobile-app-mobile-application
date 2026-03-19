import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../authentication/sign_in/sign_in_screen.dart';
import '../authentication/sign_up/sign_up_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Size size = MediaQuery.sizeOf(context);

    final double overlapPx =
        MediaQuery.devicePixelRatioOf(context) > 2 ? 4.0 : 2.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top section: illustration on primary background (~55%)
            Expanded(
              flex: 55,
              child: Container(
                width: double.infinity,
                color: AppColors.primary,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/Welcome-Screen.webp',
                  fit: BoxFit.contain,
                  width: size.width,
                ),
              ),
            ),
            // Bottom section: content on white (~45%)
            Expanded(
              flex: 45,
              child: Transform.translate(
                offset: Offset(0, -overlapPx),
                child: Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            'Welcome to Insites',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Bringing you the top cocktail recipes from around the world.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),
                          AppPrimaryButton(
                            label: 'CREATE AN ACCOUNT',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SignUpScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          AppSecondaryButton(
                            label: 'SIGN IN',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SignInScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          _LegalDisclaimer(theme: theme),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalDisclaimer extends StatelessWidget {
  const _LegalDisclaimer({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        children: [
          const TextSpan(
            text: 'By creating an account and using this app, you agree to our ',
          ),
          TextSpan(
            text: 'Terms',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // TODO: Navigate to Terms
              },
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // TODO: Navigate to Privacy
              },
          ),
          const TextSpan(text: ' policies.'),
        ],
      ),
    );
  }
}
