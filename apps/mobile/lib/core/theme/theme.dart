import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'radii.dart';
import 'typography.dart';

abstract final class FletegoTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: FletegoColors.primary,
      onPrimary: FletegoColors.white,
      secondary: FletegoColors.navy,
      onSecondary: FletegoColors.white,
      tertiary: FletegoColors.success,
      onTertiary: FletegoColors.white,
      surface: FletegoColors.white,
      onSurface: FletegoColors.textPrimary,
      error: FletegoColors.error,
      onError: FletegoColors.white,
      outline: FletegoColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: FletegoColors.background,
      textTheme: FletegoTypography.textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: FletegoColors.background,
        foregroundColor: FletegoColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: FletegoTypography.textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: FletegoColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: FletegoRadii.borderLg,
          side: const BorderSide(color: FletegoColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: FletegoColors.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FletegoColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: FletegoRadii.borderMd,
          borderSide: const BorderSide(color: FletegoColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: FletegoRadii.borderMd,
          borderSide: const BorderSide(color: FletegoColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: FletegoRadii.borderMd,
          borderSide: const BorderSide(
            color: FletegoColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: FletegoRadii.borderMd,
          borderSide: const BorderSide(color: FletegoColors.error),
        ),
        hintStyle: FletegoTypography.textTheme.bodyMedium?.copyWith(
          color: FletegoColors.textMuted,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FletegoColors.primary,
          foregroundColor: FletegoColors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: FletegoRadii.borderMd),
          textStyle: FletegoTypography.textTheme.labelLarge?.copyWith(
            color: FletegoColors.white,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FletegoColors.navy,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: FletegoColors.border),
          shape: RoundedRectangleBorder(borderRadius: FletegoRadii.borderMd),
          textStyle: FletegoTypography.textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FletegoColors.primary,
          textStyle: FletegoTypography.textTheme.labelLarge,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: FletegoColors.navy,
        contentTextStyle: FletegoTypography.textTheme.bodyMedium?.copyWith(
          color: FletegoColors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: FletegoRadii.borderMd),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: FletegoColors.white,
        selectedItemColor: FletegoColors.primary,
        unselectedItemColor: FletegoColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
