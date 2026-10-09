import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// TuneTrack Material 3 Theme Definitions
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryAccent,
      scaffoldBackgroundColor: AppColors.primaryBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryAccent,
        onPrimary: Colors.black,
        secondary: AppColors.secondaryAccent,
        onSecondary: Colors.white,
        surface: AppColors.secondaryBackground,
        onSurface: AppColors.primaryText,
        error: AppColors.error,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.primaryBackground,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.secondaryBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bottomNavBackground,
        selectedItemColor: AppColors.primaryAccent,
        unselectedItemColor: AppColors.secondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primaryAccent,
        inactiveTrackColor: AppColors.surfaceLight,
        thumbColor: AppColors.primaryText,
        overlayColor: AppColors.primaryAccent.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: Colors.black,
          textStyle:
              AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          side: const BorderSide(color: AppColors.secondaryText, width: 1),
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryAccent,
          textStyle: AppTypography.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle:
            AppTypography.bodyMedium.copyWith(color: AppColors.tertiaryText),
        labelStyle: AppTypography.bodyMedium,
        prefixIconColor: AppColors.secondaryText,
        suffixIconColor: AppColors.secondaryText,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primaryAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle:
            AppTypography.bodyMedium.copyWith(color: AppColors.primaryText),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.8,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryAccent,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryAccent,
        onPrimary: Colors.white,
        secondary: AppColors.secondaryAccent,
        surface: AppColors.lightSecondary,
        onSurface: AppColors.lightPrimaryText,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.lightPrimaryText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSecondary,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
