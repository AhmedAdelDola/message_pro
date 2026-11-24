import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBrandLogo extends StatelessWidget {
  final Animation<double> controller;
  final bool isDark;

  const AnimatedBrandLogo({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
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

    final p1Anim = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 620 / 3300, curve: Cubic(0.16, 1.0, 0.3, 1.0)),
    );
    final p2Anim = CurvedAnimation(
      parent: controller,
      curve: const Interval(70 / 3300, 690 / 3300, curve: Cubic(0.16, 1.0, 0.3, 1.0)),
    );
    final p3Anim = CurvedAnimation(
      parent: controller,
      curve: const Interval(140 / 3300, 760 / 3300, curve: Cubic(0.16, 1.0, 0.3, 1.0)),
    );
    final markHomeAnim = CurvedAnimation(
      parent: controller,
      curve: const Interval(820 / 3300, 1260 / 3300, curve: Cubic(0.65, 0.0, 0.2, 1.0)),
    );
    final wordmarkAnim = CurvedAnimation(
      parent: controller,
      curve: const Interval(1220 / 3300, 1680 / 3300, curve: Cubic(0.16, 1.0, 0.3, 1.0)),
    );
    final shakeAnim = CurvedAnimation(
      parent: controller,
      curve: const Interval(2400 / 3300, 3000 / 3300, curve: Curves.linear),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final p1T = p1Anim.value;
        final p1Tx = Tween<double>(begin: -210 * ratio, end: 0).transform(p1T);
        final p1Ty = Tween<double>(begin: 180 * ratio, end: 0).transform(p1T);
        final p1Rot = Tween<double>(begin: -12 * math.pi / 180, end: 0).transform(p1T);
        final p1Op = (p1T / 0.35).clamp(0.0, 1.0);

        final p2T = p2Anim.value;
        final p2Tx = Tween<double>(begin: 20 * ratio, end: 0).transform(p2T);
        final p2Ty = Tween<double>(begin: -230 * ratio, end: 0).transform(p2T);
        final p2Rot = Tween<double>(begin: 8 * math.pi / 180, end: 0).transform(p2T);
        final p2Op = (p2T / 0.35).clamp(0.0, 1.0);

        final p3T = p3Anim.value;
        final p3Tx = Tween<double>(begin: 240 * ratio, end: 0).transform(p3T);
        final p3Ty = Tween<double>(begin: 160 * ratio, end: 0).transform(p3T);
        final p3Rot = Tween<double>(begin: 12 * math.pi / 180, end: 0).transform(p3T);
        final p3Op = (p3T / 0.35).clamp(0.0, 1.0);

        final homeT = markHomeAnim.value;
        final markHomeTx = Tween<double>(begin: logoWidth * 0.317177, end: 0).transform(homeT);
        final markHomeScale = Tween<double>(begin: 1.08, end: 1.0).transform(homeT);

        final wmT = wordmarkAnim.value;
        final wmTx = Tween<double>(begin: 90 * ratio, end: 0).transform(wmT);
        final wmOp = wmT.clamp(0.0, 1.0);

        final sT = shakeAnim.value;
        double shakeTx = 0;
        double shakeRot = 0;
        if (sT > 0 && sT < 1.0) {
          shakeTx = _interpolateShakeTx(sT, ratio);
          shakeRot = _interpolateShakeRot(sT);
        }

        return Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: logoWidth,
            height: logoHeight,
            child: Row(
              children: [
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
        );
      },
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
