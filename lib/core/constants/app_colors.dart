import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF4162E3);
  static const Color primaryLight = Color(0xFF4162E3);
  static const Color primaryDark = Color(0xFF1B21A8);
  static const Color accent = Color(0xFF4162E3);
  static const Color brandSubtle = Color(0xFFF0F2FD);
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF1B21A9), Color(0xFF4162E3)],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  // Light Backgrounds & Surfaces
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFEFEFE);
  static const Color lightSurface2 = Color(0xFFF9F9FB);
  static const Color lightSolid3 = Color(0xFFF0F0F3);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E3E7);
  static const Color lightInputBg = Color(0x08000000); // rgba(0, 0, 0, 0.03)

  // Dark Backgrounds & Surfaces
  static const Color darkBackground = Color(0xFF0D0D0D);
  static const Color darkSurface = Color(0xFF161616);
  static const Color darkSurface2 = Color(0xFF1F2228);
  static const Color darkSolid3 = Color(0xFF24262B);
  static const Color darkCard = Color(0xFF1C1C1E);
  static const Color darkBorder = Color(0xFF212121);
  static const Color darkInputBg = Color(0xFF161616);

  // Text - Light Theme (Slate Palette)
  static const Color textDarkPrimary = Color(0xFF282E34);   // slate-12
  static const Color textDarkSecondary = Color(0xFF626F7F); // slate-11
  static const Color textDarkMuted = Color(0xFF80838D);     // slate-10

  // Text - Dark Theme (Light Text)
  static const Color textLightPrimary = Color(0xFFFAFAFA);
  static const Color textLightSecondary = Color(0xFFB0B4BA);
  static const Color textLightMuted = Color(0xFF80838D);

  // Status
  static const Color success = Color(0xFF2CA54A);
  static const Color warning = Color(0xFFFFC53D);
  static const Color danger = Color(0xFFFF382E);
  static const Color info = Color(0xFF4162E3);

  // Chat Specific
  static const Color outgoingBubble = Color(0xFF4162E3);
  static const Color incomingBubbleLight = Color(0xFFF0F2F5);
  static const Color incomingBubbleDark = Color(0xFF161616);
  static const Color privateNoteLight = Color(0xFFFFFBEB);
  static const Color privateNoteDark = Color(0xFF2E2413);
  static const Color privateNoteBorder = Color(0xFFFBBF24);

  // Channels
  static const Color whatsapp = Color(0xFF25D366);
  static const Color facebook = Color(0xFF1877F2);
  static const Color email = Color(0xFFEA4335);
  static const Color telegram = Color(0xFF229ED9);
  static const Color website = Color(0xFF6366F1);
}
