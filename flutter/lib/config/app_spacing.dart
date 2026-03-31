import 'package:flutter/material.dart';

/// Centralised spacing, padding, and border radius constants.
class AppSpacing {
  AppSpacing._();

  // Screen-level padding
  static const double screenHorizontal = 24.0;
  static const EdgeInsets screenInsets = EdgeInsets.symmetric(horizontal: 24);

  // Content padding
  static const EdgeInsets contentInsets = EdgeInsets.all(24);
  static const EdgeInsets tilePadding = EdgeInsets.symmetric(horizontal: 20, vertical: 16);

  // Border radii
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXL = 16.0;

  static final BorderRadius borderRadiusSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius borderRadiusLarge = BorderRadius.circular(radiusLarge);
}
