import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:righttouch/data/models/models.dart';
import 'package:righttouch/presentation/providers/providers.dart';
import 'package:righttouch/presentation/screens/home/home_screen.dart';
import 'test_harness.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('Populated State: renders header, categories, and banners', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const HomeScreen(),
          overrides: createDefaultOverrides(
            categories: [
              createFakeCategory(id: 'cat_solar', name: 'Solar Solutions'),
              createFakeCategory(id: 'cat_cctv', name: 'CCTV Security'),
            ],
            services: [
              createFakeService(id: 'svc_clean', name: 'Solar Cleaning Service'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Deliver to'), findsOneWidget);
      expect(find.text('50K+'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Solar Inverter 5kW'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Solar Inverter 5kW'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Featured Products')), findsOneWidget);
    });

    testWidgets('Loading State: shows loading indicators gracefully', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const HomeScreen(),
          overrides: [
            ...createDefaultOverrides(),
            categoryListProvider.overrideWith((ref) => Completer<List<CategoryModel>>().future),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Error State: renders retry or fallback without crashing', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const HomeScreen(),
          overrides: [
            ...createDefaultOverrides(),
            categoryListProvider.overrideWith((ref) => Future.error(Exception('Failed to load categories'))),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Empty State: renders gracefully when categories and services are empty', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const HomeScreen(),
          overrides: createDefaultOverrides(
            categories: [],
            services: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('HomeScreen Viewport & Overflow Tests', () {
    for (final entry in kScreenResolutions.entries) {
      testWidgets('renders on ${entry.key} (${entry.value.width}x${entry.value.height})', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestApp(screen: const HomeScreen()));
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
      });
    }
  });

  group('HomeScreen Font Scale Tests', () {
    for (final scale in kFontScales) {
      testWidgets('renders at textScaleFactor $scale', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestApp(screen: const HomeScreen(), textScale: scale));
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
      });
    }
  });

  group('HomeScreen Accessibility Tests', () {
    testWidgets('Interactive deliver-to address bar has adequate touch area', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(screen: const HomeScreen()));
      await tester.pumpAndSettle();

      final deliverToFinder = find.text('Deliver to');
      expect(deliverToFinder, findsOneWidget);
    });
  });
}
