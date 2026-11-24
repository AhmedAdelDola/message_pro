import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:message_pro/core/services/push_notification_service.dart';
import 'package:message_pro/logic/auth/auth_cubit.dart';
import 'package:message_pro/logic/settings/settings_cubit.dart';
import 'package:message_pro/ui/screens/auth/login_screen.dart';
import 'package:message_pro/ui/screens/main_layout.dart';
import 'widgets/animated_brand_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hasSession = false;
  bool _sessionChecked = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3300),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finish();
      }
    });

    _controller.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      _hasSession = await context.read<AuthCubit>().restoreSession();
    } catch (_) {
      _hasSession = false;
    }
    _sessionChecked = true;
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;

    if (_hasSession) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainLayout(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
      Future.delayed(const Duration(milliseconds: 400), () {
        PushNotificationService.processPendingNotification();
      });
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.watch<SettingsCubit>().state.locale;
    final isArabic = locale.languageCode == 'ar';

    final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAFAFA);
    final mutedColor = isDark ? const Color(0xFFAEB5C9) : const Color(0xFF626262);
    final statusText = isArabic ? 'جارٍ تجهيز مساحة عملك' : 'Preparing your workspace';

    final fadeOutAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(3050 / 3300, 1.0, curve: Curves.easeInOut),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_sessionChecked) _finish();
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final containerOpacity = 1.0 - fadeOutAnim.value;

              return Opacity(
                opacity: containerOpacity.clamp(0.0, 1.0),
                child: Stack(
                  children: [
                    Center(
                      child: Transform.translate(
                        offset: Offset(0, -18.h),
                        child: AnimatedBrandLogo(
                          controller: _controller,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 44.h,
                      left: 20.w,
                      right: 20.w,
                      child: Text(
                        statusText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: mutedColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
