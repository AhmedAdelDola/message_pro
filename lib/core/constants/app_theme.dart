import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static String? get fontFamily => GoogleFonts.ibmPlexSansArabic().fontFamily;

  static TextStyle font({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) =>
      GoogleFonts.ibmPlexSansArabic(
        textStyle: textStyle,
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        textBaseline: textBaseline,
        height: height,
        foreground: foreground,
        background: background,
        shadows: shadows,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: decorationThickness,
      );

  static ThemeData lightTheme() {
    final baseTextTheme = TextTheme(
      headlineLarge: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDarkPrimary),
      headlineMedium: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDarkPrimary),
      headlineSmall: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
      titleLarge: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDarkPrimary),
      titleMedium: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
      titleSmall: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
      bodyLarge: const TextStyle(fontWeight: FontWeight.w400, color: AppColors.textDarkPrimary),
      bodyMedium: const TextStyle(fontWeight: FontWeight.w400, color: AppColors.textDarkPrimary),
      bodySmall: const TextStyle(fontWeight: FontWeight.w400, color: AppColors.textDarkSecondary),
      labelLarge: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
      labelMedium: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textDarkSecondary),
      labelSmall: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textDarkMuted),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.ibmPlexSansArabic().fontFamily,
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
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textDarkPrimary),
        titleTextStyle: GoogleFonts.ibmPlexSansArabic(
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
      textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(baseTextTheme),
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
        hintStyle: GoogleFonts.ibmPlexSansArabic(color: AppColors.textDarkMuted, fontSize: 13),
      ),
    );
  }

  static ThemeData darkTheme() {
    final baseTextTheme = TextTheme(
      headlineLarge: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textLightPrimary),
      headlineMedium: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textLightPrimary),
      headlineSmall: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textLightPrimary),
      titleLarge: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textLightPrimary),
      titleMedium: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textLightPrimary),
      titleSmall: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textLightPrimary),
      bodyLarge: const TextStyle(fontWeight: FontWeight.w400, color: AppColors.textLightPrimary),
      bodyMedium: const TextStyle(fontWeight: FontWeight.w400, color: AppColors.textLightPrimary),
      bodySmall: const TextStyle(fontWeight: FontWeight.w400, color: AppColors.textLightSecondary),
      labelLarge: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textLightPrimary),
      labelMedium: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textLightSecondary),
      labelSmall: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textLightMuted),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.ibmPlexSansArabic().fontFamily,
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
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textLightPrimary),
        titleTextStyle: GoogleFonts.ibmPlexSansArabic(
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
      textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(baseTextTheme),
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
        hintStyle: GoogleFonts.ibmPlexSansArabic(color: AppColors.textLightMuted, fontSize: 13),
      ),
    );
  }
}
