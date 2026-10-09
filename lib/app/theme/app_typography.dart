import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// TuneTrack Typography System
class AppTypography {
  AppTypography._();

  static TextStyle get displayLarge => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryText,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => GoogleFonts.outfit(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryText,
        letterSpacing: -0.3,
      );

  static TextStyle get displaySmall => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryText,
      );

  static TextStyle get headlineMedium => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryText,
      );

  static TextStyle get headlineSmall => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryText,
      );

  static TextStyle get titleLarge => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryText,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryText,
      );

  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryText,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryText,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.secondaryText,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.tertiaryText,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryText,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.secondaryText,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.secondaryText,
      );
}
