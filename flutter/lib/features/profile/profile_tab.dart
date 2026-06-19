import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../config/app_colors.dart';
import '../authentication/bloc/auth_bloc.dart';
import '../authentication/bloc/auth_event.dart';
import '../authentication/bloc/auth_state.dart';
import 'change_password_screen.dart';
import 'my_details_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFFCFCFC),
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            title: const Text(
              'Profile',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 24),
                    _SectionLabel('ACCOUNT DETAILS'),
                    _MenuTile(title: 'My Details', isFirst: true, onTap: () {
                      final user = state is AuthAuthenticated ? state.user : null;
                      if (user == null) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => MyDetailsScreen(user: user),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    _SectionLabel('SETTINGS'),
                    _MenuTile(title: 'Change Password', isFirst: true, onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    _SectionLabel('ABOUT INSITES'),
                    _MenuTile(title: 'Privacy Policy', isFirst: true, onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      );
                    }),
                    _MenuTile(title: 'Terms & Conditions', onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TermsConditionsScreen(),
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                    _LogOutButton(
                      onPressed: () => _confirmLogout(context),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        _appVersion.isEmpty
                            ? 'Insites App Version'
                            : 'Insites App Version $_appVersion',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: Text(
              'Log Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.title, required this.onTap, this.isFirst = false});
  final String title;
  final VoidCallback onTap;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: isFirst ? const BorderSide(color: AppColors.divider) : BorderSide.none,
          bottom: const BorderSide(color: AppColors.divider),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogOutButton extends StatelessWidget {
  const _LogOutButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider),
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Log Out',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.logoutRed,
            ),
          ),
        ),
      ),
    );
  }
}
