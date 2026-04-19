import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

/// Large circular success badge used in confirmation screens (e.g. Email
/// Sent, Password Changed). 72x72 green circle with a centred 40px white
/// icon, per the Figma design system.
class SuccessBadge extends StatelessWidget {
  const SuccessBadge({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.successBadge,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 40),
    );
  }
}
