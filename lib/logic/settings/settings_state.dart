import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final Locale locale;
  final bool hapticEnabled;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('ar'),
    this.hapticEnabled = true,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? hapticEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    );
  }

  @override
  List<Object?> get props => [themeMode, locale, hapticEnabled];
}
