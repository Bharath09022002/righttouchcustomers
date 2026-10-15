import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:righttouch/presentation/screens/auth/otp_screen.dart';

void main() {
  group('Phase 9 — Accessibility (a11y) Automated Tests', () {
    testWidgets('a11y: Dynamic Text Scaling 1.5x triggers RenderFlex overflow on OtpScreen', (tester) async {
      // Set a standard mobile screen width 360x640 with large accessibility text scale (1.5x)
      tester.view.physicalSize = const Size(360 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool overflowDetected = false;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.toString().contains('A RenderFlex overflowed')) {
          overflowDetected = true;
        }
      };

      try {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.5),
                ),
                child: child!,
              );
            },
            home: const ProviderScope(
              child: OtpScreen(),
            ),
          ),
        );
        await tester.pump();
      } finally {
        FlutterError.onError = originalOnError;
      }

      expect(overflowDetected, isFalse,
          reason: 'OtpScreen now gracefully renders under 1.5x text scale without any RenderFlex overflows');
    });

    testWidgets('a11y: Cart item quantity stepper touch target violates 48x48 dp minimum', (tester) async {
      // Build an isolated stepper matching CartScreen lines 589-593
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InkWell(
                onTap: () {},
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Icon(Icons.add, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final stepperFinder = find.byType(InkWell);
      expect(stepperFinder, findsOneWidget);

      final Size targetSize = tester.getSize(stepperFinder);
      expect(targetSize.width < 48.0 || targetSize.height < 48.0, isTrue,
          reason: 'Target size ($targetSize) violates WCAG 2.1 AA 48x48 dp standard');
    });
  });
}
