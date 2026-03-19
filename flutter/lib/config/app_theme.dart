import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final ColorScheme baseScheme =
        ColorScheme.fromSeed(seedColor: AppColors.primary);

    final ColorScheme colorScheme =
        baseScheme.copyWith(secondary: AppColors.secondary);

    return ThemeData(
      colorScheme: colorScheme,
      textTheme: GoogleFonts.poppinsTextTheme(),
      useMaterial3: true,
    );
  }
}

