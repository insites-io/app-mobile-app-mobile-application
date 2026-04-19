import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2448C9);
  static const Color secondary = Color(0xFFF2437D);

  static const Color splashBackground = primary;

  static const Color textPrimary = Color(0xFF141414);
  static const Color textSecondary = Color(0xFF595959);
  static const Color inputBorder = Color(0xFFD1D1D1);

  // Design system tokens from Figma (Insites mobile v1). Prefer these over
  // inline hex values when matching specific Figma nodes.
  static const Color bodyText = Color(0xFF575757);   // paragraph body copy
  static const Color linkMuted = Color(0xFF3C3C3C);  // --text-2, inline link surround
  static const Color linkAccent = Color(0xFF5056EF); // --platform-user, link accent
  static const Color successBadge = Color(0xFF048801); // --alert-positive

  // Semantic colours
  static const Color error = Color(0xFFC62828);       // replaces Colors.red.shade600
  static const Color errorLight = Color(0xFFEF5350);  // replaces Colors.red.shade400
  static const Color success = Color(0xFF2E7D32);     // replaces Colors.green.shade600
  static const Color warning = Color(0xFFEF6C00);     // replaces Colors.orange.shade700
  static const Color ratingGold = Color(0xFFF9A825);  // replaces Colors.amber.shade700
  static const Color logoutRed = Color(0xFFD32F2F);   // replaces Colors.red.shade700
  static const Color divider = Color(0xFFE1E1E1);
  static const Color surface = Colors.white;
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color placeholderBg = Color(0xFFEEEEEE);   // Colors.grey.shade200
  static const Color placeholderIcon = Color(0xFFBDBDBD);  // Colors.grey.shade400
  static Color get hintText => textSecondary.withValues(alpha: 0.7);
}

