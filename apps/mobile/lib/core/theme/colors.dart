import 'package:flutter/material.dart';

/// Design tokens — never scatter hex values in widgets.
abstract final class FletegoColors {
  static const primary = Color(0xFF1769FF);
  static const navy = Color(0xFF0B1220);
  static const success = Color(0xFF20C77A);
  static const background = Color(0xFFF6F8FC);
  static const white = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF0B1220);
  static const textSecondary = Color(0xFF5B6472);
  static const textMuted = Color(0xFF8B93A1);
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFEEF2F7);
  static const error = Color(0xFFE11D48);
  static const warning = Color(0xFFF59E0B);
  static const disabled = Color(0xFFC5CBD6);
  static const surfaceMuted = Color(0xFFEFF3FA);
}
