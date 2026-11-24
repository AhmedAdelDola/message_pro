import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static const String englishFontFamily = 'Inter';
  static const String arabicFontFamily = 'IBMPlexSansArabic';

  static List<String> get arabicFontFallback => [
        arabicFontFamily,
        GoogleFonts.ibmPlexSansArabic().fontFamily ?? 'IBMPlexSansArabic',
        'Almarai',
        GoogleFonts.almarai().fontFamily ?? 'Almarai',
      ];

  static String get fontFamily => englishFontFamily;

  static String getFontFamilyForLocale(Locale? locale) {
    if (locale?.languageCode == 'ar') {
      return arabicFontFamily;
    }
    return englishFontFamily;
  }

  static List<String> getFontFallbackForLocale(Locale? locale) {
    if (locale?.languageCode == 'ar') {
      return [
        englishFontFamily,
        GoogleFonts.inter().fontFamily ?? 'Inter',
      ];
    }
    return arabicFontFallback;
  }

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
  }) {
    final base = TextStyle(
      fontFamily: englishFontFamily,
      fontFamilyFallback: arabicFontFallback,
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
    return textStyle != null ? base.merge(textStyle) : base;
  }

  static ThemeData lightTheme([Locale? locale]) {
    final activeFontFamily = getFontFamilyForLocale(locale);
    final fallback = getFontFallbackForLocale(locale);

    TextStyle style({
      required FontWeight fontWeight,
      required Color color,
      double? fontSize,
    }) {
      return TextStyle(
        fontFamily: activeFontFamily,
        fontFamilyFallback: fallback,
        fontWeight: fontWeight,
        color: color,
        fontSize: fontSize,
      );
    }

    final textTheme = TextTheme(
      headlineLarge: style(fontWeight: FontWeight.w700, color: AppColors.textDarkPrimary, fontSize: 32),
      headlineMedium: style(fontWeight: FontWeight.w700, color: AppColors.textDarkPrimary, fontSize: 28),
      headlineSmall: style(fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary, fontSize: 24),
      titleLarge: style(fontWeight: FontWeight.w700, color: AppColors.textDarkPrimary, fontSize: 20),
      titleMedium: style(fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary, fontSize: 16),
      titleSmall: style(fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary, fontSize: 14),
      bodyLarge: style(fontWeight: FontWeight.w400, color: AppColors.textDarkPrimary, fontSize: 16),
      bodyMedium: style(fontWeight: FontWeight.w400, color: AppColors.textDarkPrimary, fontSize: 14),
      bodySmall: style(fontWeight: FontWeight.w400, color: AppColors.textDarkSecondary, fontSize: 12),
      labelLarge: style(fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary, fontSize: 14),
      labelMedium: style(fontWeight: FontWeight.w500, color: AppColors.textDarkSecondary, fontSize: 12),
      labelSmall: style(fontWeight: FontWeight.w500, color: AppColors.textDarkMuted, fontSize: 11),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: activeFontFamily,
      fontFamilyFallback: fallback,
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
        titleTextStyle: style(
          color: AppColors.textDarkPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
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
      textTheme: textTheme,
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
        hintStyle: style(color: AppColors.textDarkMuted, fontSize: 13, fontWeight: FontWeight.w400),
      ),
    );
  }

  static ThemeData darkTheme([Locale? locale]) {
    final activeFontFamily = getFontFamilyForLocale(locale);
    final fallback = getFontFallbackForLocale(locale);

    TextStyle style({
      required FontWeight fontWeight,
      required Color color,
      double? fontSize,
    }) {
      return TextStyle(
        fontFamily: activeFontFamily,
        fontFamilyFallback: fallback,
        fontWeight: fontWeight,
        color: color,
        fontSize: fontSize,
      );
    }

    final textTheme = TextTheme(
      headlineLarge: style(fontWeight: FontWeight.w700, color: AppColors.textLightPrimary, fontSize: 32),
      headlineMedium: style(fontWeight: FontWeight.w700, color: AppColors.textLightPrimary, fontSize: 28),
      headlineSmall: style(fontWeight: FontWeight.w600, color: AppColors.textLightPrimary, fontSize: 24),
      titleLarge: style(fontWeight: FontWeight.w700, color: AppColors.textLightPrimary, fontSize: 20),
      titleMedium: style(fontWeight: FontWeight.w600, color: AppColors.textLightPrimary, fontSize: 16),
      titleSmall: style(fontWeight: FontWeight.w600, color: AppColors.textLightPrimary, fontSize: 14),
      bodyLarge: style(fontWeight: FontWeight.w400, color: AppColors.textLightPrimary, fontSize: 16),
      bodyMedium: style(fontWeight: FontWeight.w400, color: AppColors.textLightPrimary, fontSize: 14),
      bodySmall: style(fontWeight: FontWeight.w400, color: AppColors.textLightSecondary, fontSize: 12),
      labelLarge: style(fontWeight: FontWeight.w600, color: AppColors.textLightPrimary, fontSize: 14),
      labelMedium: style(fontWeight: FontWeight.w500, color: AppColors.textLightSecondary, fontSize: 12),
      labelSmall: style(fontWeight: FontWeight.w500, color: AppColors.textLightMuted, fontSize: 11),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: activeFontFamily,
      fontFamilyFallback: fallback,
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
        titleTextStyle: style(
          color: AppColors.textLightPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
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
      textTheme: textTheme,
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
        hintStyle: style(color: AppColors.textLightMuted, fontSize: 13, fontWeight: FontWeight.w400),
      ),
    );
  }
}
