import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

/// Reusable blue app bar used across screens.
///
/// Supports an optional back button, centered title, and trailing menu icon.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.showMenuIcon = true,
    this.onMenuTap,
  });

  final String title;
  final bool showBackButton;
  final bool showMenuIcon;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(top: topPadding > 0 ? topPadding : 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (showBackButton)
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Go back',
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else
              const SizedBox(width: 48),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            if (showMenuIcon)
              IconButton(
                onPressed: onMenuTap,
                tooltip: 'Open menu',
                icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
