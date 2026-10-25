import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState()) {
    _loadSettings();
  }

  static const _themeKey = 'app_theme_mode';
  static const _langKey = 'app_language_code';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_themeKey);
    final langStr = prefs.getString(_langKey) ?? 'ar';

    ThemeMode mode = ThemeMode.system;
    if (themeStr == 'light') mode = ThemeMode.light;
    if (themeStr == 'dark') mode = ThemeMode.dark;

    emit(state.copyWith(
      themeMode: mode,
      locale: Locale(langStr),
    ));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    final prefs = await SharedPreferences.getInstance();
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    await prefs.setString(_themeKey, val);
  }

  Future<void> setLocale(Locale loc) async {
    emit(state.copyWith(locale: loc));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, loc.languageCode);
  }
}
