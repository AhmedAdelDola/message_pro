import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_pro/core/localization/app_localizations.dart';

void main() {
  group('AppLocalizations Tests', () {
    test('Loads Arabic translations correctly', () {
      final l10n = AppLocalizations(const Locale('ar'));

      expect(l10n.isArabic, true);
      expect(l10n.login, 'تسجيل الدخول');
      expect(l10n.inbox, 'صندوق الوارد');
      expect(l10n.preferences, 'التفضيلات');
      expect(l10n.typeMessageHint, 'اكتب رسالتك...');
    });

    test('Loads English translations correctly', () {
      final l10n = AppLocalizations(const Locale('en'));

      expect(l10n.isArabic, false);
      expect(l10n.login, 'Login');
      expect(l10n.inbox, 'Inbox');
      expect(l10n.preferences, 'PREFERENCES');
      expect(l10n.typeMessageHint, 'Type a message...');
    });

    test('Falls back gracefully for undefined keys', () {
      final l10n = AppLocalizations(const Locale('ar'));
      expect(l10n.translate('undefined_key', defaultVal: 'Default Value'), 'Default Value');
      expect(l10n.translate('undefined_key'), 'undefined_key');
    });
  });
}
