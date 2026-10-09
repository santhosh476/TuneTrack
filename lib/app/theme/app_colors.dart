import 'package:flutter/material.dart';

/// TuneTrack Application Color Palette
class AppColors {
  AppColors._();

  // Dark Theme Core Colors (TuneTrack 2.0)
  static const Color primaryBackground = Color(0xFF101010);
  static const Color secondaryBackground = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFF222222);
  static const Color surfaceLight = Color(0xFF2C2C2C);
  static const Color surfaceElevated = Color(0xFF1A1A1A);

  // Accent Colors
  static const Color primaryAccent =
      Color(0xFF1DB954); // TuneTrack Vibrant Green
  static const Color primaryAccentLight = Color(0xFF1ED760);
  static const Color primaryAccentDark = Color(0xFF169C46);
  static const Color secondaryAccent =
      Color(0xFF6C5CE7); // Violet accent for stats & discovery
  static const Color tertiaryAccent = Color(0xFFFF7675);

  // Text Colors
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFA7A7A7);
  static const Color tertiaryText = Color(0xFF757575);
  static const Color textDisabled = Color(0xFF535353);

  // Functional Colors
  static const Color error = Color(0xFFE22134);
  static const Color warning = Color(0xFFFFB300);
  static const Color success = Color(0xFF1DB954);
  static const Color info = Color(0xFF29B6F6);

  // Borders & Dividers
  static const Color divider = Color(0xFF2A2A2A);
  static const Color border = Color(0xFF333333);

  // Overlay & Glassmorphism
  static const Color glassOverlay = Color(0x991E1E1E);
  static const Color miniPlayerOverlay = Color(0xEE1E1E1E);
  static const Color bottomNavBackground = Color(0xF2121212);

  // Vibrant Gradient Palettes for Dynamic Artwork & Recaps
  static const List<Color> greenGradient = [
    Color(0xFF1DB954),
    Color(0xFF191414)
  ];
  static const List<Color> purpleGradient = [
    Color(0xFF8E2DE2),
    Color(0xFF4A00E0)
  ];
  static const List<Color> sunsetGradient = [
    Color(0xFFFF512F),
    Color(0xFFDD2476)
  ];
  static const List<Color> oceanGradient = [
    Color(0xFF2193B0),
    Color(0xFF6DD5ED)
  ];
  static const List<Color> amberGradient = [
    Color(0xFFF7971E),
    Color(0xFFFFD200)
  ];

  // Light Theme Alternatives (for optional theme switching)
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSecondary = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFEEEEEE);
  static const Color lightPrimaryText = Color(0xFF191414);
  static const Color lightSecondaryText = Color(0xFF616161);
}
