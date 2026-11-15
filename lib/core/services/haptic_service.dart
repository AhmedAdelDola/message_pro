import 'package:flutter/services.dart';

/// Centralized Haptic Service that respects user's preference in Settings.
class HapticService {
  static bool _enabled = true;

  /// Global enabled state reflecting user settings
  static bool get isEnabled => _enabled;

  /// Update enabled state
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Light impact haptic (for swipe to reply, tabs, subtle feedback)
  static Future<void> lightImpact() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium impact haptic (for action buttons, toggles)
  static Future<void> mediumImpact() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy impact haptic (for confirmations, critical actions)
  static Future<void> heavyImpact() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Selection click haptic (for pickers, dropdowns, menus)
  static Future<void> selectionClick() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Standard vibration
  static Future<void> vibrate() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }
}
