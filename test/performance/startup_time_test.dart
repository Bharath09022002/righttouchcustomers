import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:righttouch/app.dart';
import '../widget/test_harness.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 6 — Startup Time Benchmark (TTFF & TTI)', () {
    testWidgets('Measure Time-To-First-Frame and Time-To-Interactive', (tester) async {
      final totalSw = Stopwatch()..start();

      // Pre-warm initialization
      final initSw = Stopwatch()..start();
      final container = ProviderContainer(
        overrides: createDefaultOverrides(),
      );
      initSw.stop();
      final initMs = initSw.elapsedMicroseconds / 1000.0;

      // Mount App & Measure First Frame (TTFF)
      final ttffSw = Stopwatch()..start();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const RightTouchApp(),
        ),
      );
      await tester.pump();
      ttffSw.stop();
      final ttffMs = initMs + (ttffSw.elapsedMicroseconds / 1000.0);

      // Measure Time to Interactive (TTI)
      final ttiSw = Stopwatch()..start();
      await tester.pump(const Duration(milliseconds: 300));
      ttiSw.stop();
      totalSw.stop();
      final ttiMs = ttffMs + (ttiSw.elapsedMicroseconds / 1000.0);

      debugPrint('=== Startup Benchmarks ===');
      debugPrint('Pre-runApp container initialization: ${initMs.toStringAsFixed(2)} ms');
      debugPrint('Time-To-First-Frame (TTFF): ${ttffMs.toStringAsFixed(2)} ms');
      debugPrint('Time-To-Interactive (TTI): ${ttiMs.toStringAsFixed(2)} ms');
      debugPrint('Total benchmark duration: ${totalSw.elapsedMilliseconds} ms');

      expect(ttffMs, lessThan(1000.0));
      expect(ttiMs, lessThan(2000.0));
    });
  });
}
