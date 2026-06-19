import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/app_colors.dart';
import '../authentication/bloc/auth_bloc.dart';
import '../authentication/bloc/auth_state.dart';
import '../home/home_screen.dart';
import '../welcome/welcome_screen.dart';

/// Shows the Insites logo while the auth check runs.
///
/// Waits for both a minimum 2-second branding display AND the [AuthBloc]
/// result before navigating — whichever finishes last triggers the route.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _minDelayDone = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _startMinDelay();
  }

  Future<void> _startMinDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _minDelayDone = true;
    _tryNavigate(context.read<AuthBloc>().state);
  }

  void _tryNavigate(AuthState state) {
    if (_hasNavigated || !_minDelayDone || !mounted) return;

    final Widget destination;
    if (state is AuthAuthenticated) {
      destination = const HomeScreen();
    } else if (state is AuthUnauthenticated) {
      destination = const WelcomeScreen();
    } else {
      return; // still loading
    }

    _hasNavigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _tryNavigate(state),
      child: Scaffold(
        backgroundColor: AppColors.splashBackground,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/Insites-Logo.svg',
                width: 250,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const CupertinoActivityIndicator(
                color: Colors.white,
                radius: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
