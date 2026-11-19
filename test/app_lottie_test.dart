import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:message_pro/core/constants/app_lottie.dart';

void main() {
  testWidgets('AppLottie renders all animations from memory without error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                AppLottie.emptyInbox(width: 100, height: 100),
                AppLottie.emptyNotifications(width: 100, height: 100),
                AppLottie.emptySearch(width: 100, height: 100),
                AppLottie.emptyCalls(width: 100, height: 100),
                AppLottie.voiceRecording(width: 50, height: 50),
                AppLottie.aiSparkle(width: 50, height: 50),
                AppLottie.successCheck(width: 50, height: 50),
              ],
            ),
          ),
        ),
      ),
    );

    // Initial pump
    await tester.pump();
    expect(find.byType(Lottie), findsNWidgets(7));
  });
}
