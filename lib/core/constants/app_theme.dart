import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Gontserrat',
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.lightSurface,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSurface: AppColors.textDarkPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0.5,
        iconTheme: IconThemeData(color: AppColors.textDarkPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Gontserrat',
          color: AppColors.textDarkPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w700, color: AppColors.textDarkPrimary),
        headlineMedium: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w700, color: AppColors.textDarkPrimary),
        headlineSmall: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
        titleLarge: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w700, color: AppColors.textDarkPrimary),
        titleMedium: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
        titleSmall: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
        bodyLarge: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w400, color: AppColors.textDarkPrimary),
        bodyMedium: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w400, color: AppColors.textDarkPrimary),
        bodySmall: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w400, color: AppColors.textDarkSecondary),
        labelLarge: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
        labelMedium: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w500, color: AppColors.textDarkSecondary),
        labelSmall: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w500, color: AppColors.textDarkMuted),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightInputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: Color(0xFFFB7185)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: Color(0xFFFB7185), width: 1.5),
        ),
        hintStyle: const TextStyle(fontFamily: 'Gontserrat', color: AppColors.textDarkMuted, fontSize: 13),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Gontserrat',
      primaryColor: AppColors.primaryLight,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.accent,
        surface: AppColors.darkSurface,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSurface: AppColors.textLightPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0.5,
        iconTheme: IconThemeData(color: AppColors.textLightPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Gontserrat',
          color: AppColors.textLightPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w700, color: AppColors.textLightPrimary),
        headlineMedium: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w700, color: AppColors.textLightPrimary),
        headlineSmall: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w600, color: AppColors.textLightPrimary),
        titleLarge: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w700, color: AppColors.textLightPrimary),
        titleMedium: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w600, color: AppColors.textLightPrimary),
        titleSmall: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w600, color: AppColors.textLightPrimary),
        bodyLarge: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w400, color: AppColors.textLightPrimary),
        bodyMedium: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w400, color: AppColors.textLightPrimary),
        bodySmall: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w400, color: AppColors.textLightSecondary),
        labelLarge: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w600, color: AppColors.textLightPrimary),
        labelMedium: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w500, color: AppColors.textLightSecondary),
        labelSmall: TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w500, color: AppColors.textLightMuted),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkInputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: Color(0xFFFB7185)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: Color(0xFFFB7185), width: 1.5),
        ),
        hintStyle: const TextStyle(fontFamily: 'Gontserrat', color: AppColors.textLightMuted, fontSize: 13),
      ),
    );
  }
}
