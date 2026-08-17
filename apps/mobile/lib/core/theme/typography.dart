import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Inter-based text styles. Prefer these over ad-hoc TextStyle in features.
abstract final class FletegoTypography {
  static TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 40,
      fontWeight: FontWeight.w800,
      height: 1.15,
      color: FletegoColors.textPrimary,
      letterSpacing: -0.5,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: FletegoColors.textPrimary,
      letterSpacing: -0.3,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: FletegoColors.textPrimary,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.3,
      color: FletegoColors.textPrimary,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: FletegoColors.textPrimary,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: FletegoColors.textPrimary,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: FletegoColors.textPrimary,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: FletegoColors.textPrimary,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: FletegoColors.textPrimary,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: FletegoColors.textSecondary,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: FletegoColors.textMuted,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: FletegoColors.textPrimary,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.2,
      color: FletegoColors.textSecondary,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.2,
      color: FletegoColors.textMuted,
    ),
  );

  /// Strong figures for prices, distances, capacity, ratings.
  static TextStyle metric({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w800,
    Color color = FletegoColors.textPrimary,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.1,
      color: color,
      letterSpacing: -0.4,
    );
  }
}
