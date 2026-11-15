import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:message_pro/core/services/haptic_service.dart';
import 'package:message_pro/logic/settings/settings_cubit.dart';
import 'package:message_pro/logic/settings/settings_state.dart';
import 'package:message_pro/ui/screens/settings/settings_screen.dart';
import 'package:message_pro/logic/auth/auth_cubit.dart';
import 'package:message_pro/logic/auth/auth_state.dart';

class MockAuthCubit extends Cubit<AuthState> implements AuthCubit {
  MockAuthCubit() : super(const AuthInitial());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HapticService.setEnabled(true);
  });

  group('HapticService Unit Tests', () {
    test('HapticService tracks enabled state accurately', () {
      expect(HapticService.isEnabled, isTrue);

      HapticService.setEnabled(false);
      expect(HapticService.isEnabled, isFalse);

      HapticService.setEnabled(true);
      expect(HapticService.isEnabled, isTrue);
    });

    test('HapticService methods execute safely without error when disabled', () async {
      HapticService.setEnabled(false);

      await HapticService.lightImpact();
      await HapticService.mediumImpact();
      await HapticService.heavyImpact();
      await HapticService.selectionClick();
      await HapticService.vibrate();

      expect(HapticService.isEnabled, isFalse);
    });

    test('HapticService methods execute safely without error when enabled', () async {
      HapticService.setEnabled(true);

      // In Flutter test environment, HapticFeedback channel calls should not throw
      await HapticService.lightImpact();
      await HapticService.mediumImpact();
      await HapticService.selectionClick();

      expect(HapticService.isEnabled, isTrue);
    });
  });

  group('SettingsState & SettingsCubit Haptic Tests', () {
    test('SettingsState default hapticEnabled is true', () {
      const state = SettingsState();
      expect(state.hapticEnabled, isTrue);

      final updated = state.copyWith(hapticEnabled: false);
      expect(updated.hapticEnabled, isFalse);
      expect(state.hapticEnabled, isTrue);
    });

    test('SettingsCubit loads default hapticEnabled = true when pref is unset', () async {
      SharedPreferences.setMockInitialValues({});
      final cubit = SettingsCubit();

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.hapticEnabled, isTrue);
      expect(HapticService.isEnabled, isTrue);

      await cubit.close();
    });

    test('SettingsCubit loads persisted false value from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'app_haptic_feedback_enabled': false,
      });
      final cubit = SettingsCubit();

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.hapticEnabled, isFalse);
      expect(HapticService.isEnabled, isFalse);

      await cubit.close();
    });

    test('SettingsCubit.setHapticEnabled toggles state and updates SharedPreferences and HapticService', () async {
      SharedPreferences.setMockInitialValues({});
      final cubit = SettingsCubit();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await cubit.setHapticEnabled(false);
      expect(cubit.state.hapticEnabled, isFalse);
      expect(HapticService.isEnabled, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app_haptic_feedback_enabled'), isFalse);

      await cubit.setHapticEnabled(true);
      expect(cubit.state.hapticEnabled, isTrue);
      expect(HapticService.isEnabled, isTrue);
      expect(prefs.getBool('app_haptic_feedback_enabled'), isTrue);

      await cubit.close();
    });
  });

  group('SettingsScreen Haptic Toggle Widget Test', () {
    testWidgets('SettingsScreen displays haptic switch and toggles cubit on tap', (tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({'app_haptic_feedback_enabled': true});
      final settingsCubit = SettingsCubit();
      final authCubit = MockAuthCubit();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SettingsCubit>.value(value: settingsCubit),
            BlocProvider<AuthCubit>.value(value: authCubit),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final hapticFinder = find.byWidgetPredicate(
        (widget) => widget is Text && (widget.data == 'الاهتزاز والتفاعل اللمسي' || widget.data == 'Haptic Feedback'),
      );

      await tester.scrollUntilVisible(
        hapticFinder,
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(hapticFinder, findsOneWidget);

      // Find switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      final initialSwitch = tester.widget<Switch>(switchFinder);
      expect(initialSwitch.value, isTrue);

      // Tap the switch to toggle OFF
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(settingsCubit.state.hapticEnabled, isFalse);
      expect(HapticService.isEnabled, isFalse);

      final toggledSwitch = tester.widget<Switch>(find.byType(Switch));
      expect(toggledSwitch.value, isFalse);

      await settingsCubit.close();
      await authCubit.close();
    });
  });
}
