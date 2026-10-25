import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/config/app_config.dart';
import 'core/constants/app_theme.dart';
import 'core/di/injection_container.dart';
import 'logic/auth/auth_cubit.dart';
import 'logic/conversation/conversation_cubit.dart';
import 'logic/notification/notification_cubit.dart';
import 'logic/calls/calls_cubit.dart';
import 'logic/settings/settings_cubit.dart';
import 'logic/settings/settings_state.dart';
import 'logic/shorebird/shorebird_cubit.dart';
import 'ui/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Dependency Injection with GetIt
  await initDI();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MessageProApp());
}

class MessageProApp extends StatelessWidget {
  const MessageProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>(create: (_) => sl<SettingsCubit>()),
        BlocProvider<AuthCubit>(create: (_) => sl<AuthCubit>()),
        BlocProvider<ConversationCubit>(create: (_) => sl<ConversationCubit>()),
        BlocProvider<NotificationCubit>(create: (_) => sl<NotificationCubit>()),
        BlocProvider<CallsCubit>(create: (_) => sl<CallsCubit>()),
        BlocProvider<ShorebirdCubit>(create: (_) => sl<ShorebirdCubit>()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return BlocBuilder<SettingsCubit, SettingsState>(
            buildWhen: (previous, current) =>
                previous.themeMode != current.themeMode ||
                previous.locale != current.locale,
            builder: (context, settingsState) {
              return MaterialApp(
                title: AppConfig.appName,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme(),
                darkTheme: AppTheme.darkTheme(),
                themeMode: settingsState.themeMode,
                locale: settingsState.locale,
                supportedLocales: const [
                  Locale('ar'),
                  Locale('en'),
                ],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: child,
              );
            },
          );
        },
        child: const SplashScreen(),
      ),
    );
  }
}
