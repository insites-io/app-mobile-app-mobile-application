import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
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

    // The white content panel overlaps the blue image area by this much
    // to eliminate any sub-pixel seam between the two sections.
    const double overlap = 16.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Blue background + illustration (fills top ~55%)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              // Extend slightly past 55% so the overlap region is still blue
              height: size.height * 0.55 + overlap,
              child: Container(
                color: AppColors.primary,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/Welcome-Screen.webp',
                  fit: BoxFit.contain,
                  width: size.width,
                ),
              ),
            ),
            // White content panel (starts at 55% minus overlap)
            Positioned(
              top: size.height * 0.55 - overlap,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(color: Colors.white),
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
                launchUrl(
                  Uri.parse(ApiConfig.termsUrl),
                  mode: LaunchMode.externalApplication,
                );
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
                launchUrl(
                  Uri.parse(ApiConfig.privacyPolicyUrl),
                  mode: LaunchMode.externalApplication,
                );
              },
          ),
          const TextSpan(text: ' policies.'),
        ],
      ),
    );
  }
}
