import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/settings/settings_cubit.dart';
import '../auth/login_screen.dart';
import '../main_layout.dart';

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

    final screenWidth = MediaQuery.of(context).size.width;
    final logoWidth = math.min(screenWidth * 0.68, 292.0);
    final logoHeight = logoWidth * (703.0 / 3528.0);
    final scale = logoWidth / 3528.0;
    final ratio = logoWidth / 292.0;

    final p1W = (428.0 * scale).roundToDouble();
    final p2W = (428.0 * scale).roundToDouble();
    final p3W = (434.0 * scale).roundToDouble();
    final markW = p1W + p2W + p3W;
    final wordmarkW = logoWidth - markW;

    final logoPath = isDark
        ? 'assets/images/brand/fulllogobabywhite.png'
        : 'assets/images/brand/fulllogobabyblue2.png';

    // Curves and intervals matching C:\crm AnimatedSplash.tsx
    // Total: 3300ms
    // Piece 1: 0ms -> 620ms (0.0 -> 0.1878)
    final p1Anim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 620 / 3300, curve: Cubic(0.16, 1.0, 0.3, 1.0)),
    );

    // Piece 2: 70ms -> 690ms (0.0212 -> 0.209)
    final p2Anim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(70 / 3300, 690 / 3300, curve: Cubic(0.16, 1.0, 0.3, 1.0)),
    );

    // Piece 3: 140ms -> 760ms (0.0424 -> 0.230)
    final p3Anim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(140 / 3300, 760 / 3300, curve: Cubic(0.16, 1.0, 0.3, 1.0)),
    );

    // Mark Home: 820ms -> 1260ms (0.248 -> 0.3818)
    final markHomeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(820 / 3300, 1260 / 3300, curve: Cubic(0.65, 0.0, 0.2, 1.0)),
    );

    // Wordmark: 1220ms -> 1680ms (0.3696 -> 0.509)
    final wordmarkAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(1220 / 3300, 1680 / 3300, curve: Cubic(0.16, 1.0, 0.3, 1.0)),
    );

    // Shake: 2400ms -> 3000ms (0.727 -> 0.909)
    final shakeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(2400 / 3300, 3000 / 3300, curve: Curves.linear),
    );

    // Fade Out: 3050ms -> 3300ms (0.924 -> 1.0)
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

              // Piece 1 Transforms
              final p1T = p1Anim.value;
              final p1Tx = Tween<double>(begin: -210 * ratio, end: 0).transform(p1T);
              final p1Ty = Tween<double>(begin: 180 * ratio, end: 0).transform(p1T);
              final p1Rot = Tween<double>(begin: -12 * math.pi / 180, end: 0).transform(p1T);
              final p1Op = (p1T / 0.35).clamp(0.0, 1.0);

              // Piece 2 Transforms
              final p2T = p2Anim.value;
              final p2Tx = Tween<double>(begin: 20 * ratio, end: 0).transform(p2T);
              final p2Ty = Tween<double>(begin: -230 * ratio, end: 0).transform(p2T);
              final p2Rot = Tween<double>(begin: 8 * math.pi / 180, end: 0).transform(p2T);
              final p2Op = (p2T / 0.35).clamp(0.0, 1.0);

              // Piece 3 Transforms
              final p3T = p3Anim.value;
              final p3Tx = Tween<double>(begin: 240 * ratio, end: 0).transform(p3T);
              final p3Ty = Tween<double>(begin: 160 * ratio, end: 0).transform(p3T);
              final p3Rot = Tween<double>(begin: 12 * math.pi / 180, end: 0).transform(p3T);
              final p3Op = (p3T / 0.35).clamp(0.0, 1.0);

              // Mark Home Glide (starts centered at 31.7177% with 1.08 scale, glides to 0 at scale 1)
              final homeT = markHomeAnim.value;
              final markHomeTx = Tween<double>(begin: logoWidth * 0.317177, end: 0).transform(homeT);
              final markHomeScale = Tween<double>(begin: 1.08, end: 1.0).transform(homeT);

              // Wordmark slide-in from +90px
              final wmT = wordmarkAnim.value;
              final wmTx = Tween<double>(begin: 90 * ratio, end: 0).transform(wmT);
              final wmOp = wmT.clamp(0.0, 1.0);

              // M-Shake keyframes
              final sT = shakeAnim.value;
              double shakeTx = 0;
              double shakeRot = 0;
              if (sT > 0 && sT < 1.0) {
                shakeTx = _interpolateShakeTx(sT, ratio);
                shakeRot = _interpolateShakeRot(sT);
              }

              return Opacity(
                opacity: containerOpacity.clamp(0.0, 1.0),
                child: Stack(
                  children: [
                    // Centered Animated Logo Box
                    Center(
                      child: Transform.translate(
                        offset: Offset(0, -18.h),
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: SizedBox(
                            width: logoWidth,
                            height: logoHeight,
                            child: Row(
                              children: [
                                // Animated M Mark (Home Glide + Shake)
                                Transform.translate(
                                  offset: Offset(markHomeTx + shakeTx, 0),
                                  child: Transform.scale(
                                    scale: markHomeScale,
                                    child: Transform.rotate(
                                      angle: shakeRot,
                                      child: SizedBox(
                                        width: markW,
                                        height: logoHeight,
                                        child: Row(
                                          children: [
                                            // Piece 1: Left Leg
                                            Opacity(
                                              opacity: p1Op,
                                              child: Transform.translate(
                                                offset: Offset(p1Tx, p1Ty),
                                                child: Transform.rotate(
                                                  angle: p1Rot,
                                                  child: _buildClippedSlice(
                                                    width: p1W,
                                                    offsetLeft: 0,
                                                    logoWidth: logoWidth,
                                                    logoHeight: logoHeight,
                                                    logoPath: logoPath,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Piece 2: Middle Leg
                                            Opacity(
                                              opacity: p2Op,
                                              child: Transform.translate(
                                                offset: Offset(p2Tx, p2Ty),
                                                child: Transform.rotate(
                                                  angle: p2Rot,
                                                  child: _buildClippedSlice(
                                                    width: p2W,
                                                    offsetLeft: p1W,
                                                    logoWidth: logoWidth,
                                                    logoHeight: logoHeight,
                                                    logoPath: logoPath,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Piece 3: Right Leg
                                            Opacity(
                                              opacity: p3Op,
                                              child: Transform.translate(
                                                offset: Offset(p3Tx, p3Ty),
                                                child: Transform.rotate(
                                                  angle: p3Rot,
                                                  child: _buildClippedSlice(
                                                    width: p3W,
                                                    offsetLeft: p1W + p2W,
                                                    logoWidth: logoWidth,
                                                    logoHeight: logoHeight,
                                                    logoPath: logoPath,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Wordmark: "Message Pro"
                                Opacity(
                                  opacity: wmOp,
                                  child: Transform.translate(
                                    offset: Offset(wmTx, 0),
                                    child: _buildClippedSlice(
                                      width: wordmarkW,
                                      offsetLeft: markW,
                                      logoWidth: logoWidth,
                                      logoHeight: logoHeight,
                                      logoPath: logoPath,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Status Text at Bottom
                    Positioned(
                      bottom: 44.h,
                      left: 20.w,
                      right: 20.w,
                      child: Text(
                        statusText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Gontserrat',
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

  static Widget _buildClippedSlice({
    required double width,
    required double offsetLeft,
    required double logoWidth,
    required double logoHeight,
    required String logoPath,
  }) {
    return SizedBox(
      width: width,
      height: logoHeight,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: logoWidth,
          maxWidth: logoWidth,
          minHeight: logoHeight,
          maxHeight: logoHeight,
          child: Transform.translate(
            offset: Offset(-offsetLeft, 0),
            child: Image.asset(
              logoPath,
              width: logoWidth,
              height: logoHeight,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        ),
      ),
    );
  }

  static double _interpolateShakeTx(double t, double ratio) {
    const points = [0.0, 0.15, 0.30, 0.45, 0.60, 0.75, 0.90, 1.0];
    const values = [0.0, -24.0, 21.0, -16.0, 11.0, -6.0, 2.0, 0.0];

    for (int i = 0; i < points.length - 1; i++) {
      if (t >= points[i] && t <= points[i + 1]) {
        final localT = (t - points[i]) / (points[i + 1] - points[i]);
        return (values[i] + (values[i + 1] - values[i]) * localT) * ratio;
      }
    }
    return 0.0;
  }

  static double _interpolateShakeRot(double t) {
    const points = [0.0, 0.15, 0.30, 0.45, 0.60, 0.75, 0.90, 1.0];
    const degrees = [0.0, -4.0, 3.5, -2.6, 1.8, -0.9, 0.3, 0.0];

    for (int i = 0; i < points.length - 1; i++) {
      if (t >= points[i] && t <= points[i + 1]) {
        final localT = (t - points[i]) / (points[i + 1] - points[i]);
        final deg = degrees[i] + (degrees[i + 1] - degrees[i]) * localT;
        return deg * math.pi / 180.0;
      }
    }
    return 0.0;
  }
}
