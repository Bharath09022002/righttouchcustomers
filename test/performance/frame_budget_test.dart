import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:righttouch/presentation/screens/booking/bookings_screen.dart';
import 'package:righttouch/presentation/screens/home/home_screen.dart';
import 'package:righttouch/presentation/screens/products/products_screen.dart';
import '../widget/test_harness.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Phase 6 — Frame Render Budget & Scrolling Jank Audit', () {
    testWidgets('HomeScreen: 60-frame continuous scroll budget audit', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(screen: const HomeScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final scrollable = find.byType(Scrollable).first;
      int jankCount = 0;
      double worstFrameMs = 0;
      double totalDurationMs = 0;

      for (int i = 0; i < 40; i++) {
        await tester.drag(scrollable, const Offset(0, -25));
        final sw = Stopwatch()..start();
        await tester.pump(const Duration(milliseconds: 16));
        sw.stop();
        final ms = sw.elapsedMicroseconds / 1000.0;
        totalDurationMs += ms;
        if (ms > worstFrameMs) worstFrameMs = ms;
        if (ms > 16.6) jankCount++;
      }

      final avgFrameMs = totalDurationMs / 40;
      debugPrint('[HomeScreen Benchmark] 40 frames | Avg: ${avgFrameMs.toStringAsFixed(2)}ms | Worst: ${worstFrameMs.toStringAsFixed(2)}ms | Jank Frames: $jankCount');
      expect(avgFrameMs, lessThan(33.0));
    });

    testWidgets('BookingsScreen: 40-frame scroll budget audit', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bookings = List.generate(
        15,
        (i) => createFakeBooking(id: 'bk_$i', serviceName: 'Service Item #$i'),
      );

      await tester.pumpWidget(
        createTestApp(
          screen: const BookingsScreen(),
          route: '/bookings',
          overrides: [
            ...createDefaultOverrides(bookings: bookings),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final scrollable = find.byType(Scrollable);
      int jankCount = 0;
      double worstFrameMs = 0;
      double totalDurationMs = 0;

      if (scrollable.evaluate().isNotEmpty) {
        for (int i = 0; i < 30; i++) {
          await tester.drag(scrollable.first, const Offset(0, -30));
          final sw = Stopwatch()..start();
          await tester.pump(const Duration(milliseconds: 16));
          sw.stop();
          final ms = sw.elapsedMicroseconds / 1000.0;
          totalDurationMs += ms;
          if (ms > worstFrameMs) worstFrameMs = ms;
          if (ms > 16.6) jankCount++;
        }
      }

      final avgFrameMs = totalDurationMs > 0 ? totalDurationMs / 30 : 0.0;
      debugPrint('[BookingsScreen Benchmark] 30 frames | Avg: ${avgFrameMs.toStringAsFixed(2)}ms | Worst: ${worstFrameMs.toStringAsFixed(2)}ms | Jank Frames: $jankCount');
    });

    testWidgets('ProductsScreen: 40-frame scroll budget audit', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const ProductsScreen(),
          route: '/products',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final scrollable = find.byType(Scrollable);
      int jankCount = 0;
      double worstFrameMs = 0;
      double totalDurationMs = 0;

      if (scrollable.evaluate().isNotEmpty) {
        for (int i = 0; i < 30; i++) {
          await tester.drag(scrollable.first, const Offset(0, -30));
          final sw = Stopwatch()..start();
          await tester.pump(const Duration(milliseconds: 16));
          sw.stop();
          final ms = sw.elapsedMicroseconds / 1000.0;
          totalDurationMs += ms;
          if (ms > worstFrameMs) worstFrameMs = ms;
          if (ms > 16.6) jankCount++;
        }
      }

      final avgFrameMs = totalDurationMs > 0 ? totalDurationMs / 30 : 0.0;
      debugPrint('[ProductsScreen Benchmark] 30 frames | Avg: ${avgFrameMs.toStringAsFixed(2)}ms | Worst: ${worstFrameMs.toStringAsFixed(2)}ms | Jank Frames: $jankCount');
    });
  });
}
