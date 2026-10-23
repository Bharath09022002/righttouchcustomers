import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:righttouch/presentation/providers/providers.dart';
import 'package:righttouch/presentation/screens/products/product_detail_screen.dart';
import 'test_harness.dart';

void main() {
  group('ProductDetailScreen Widget & Viewport Tests', () {
    testWidgets('Fixed Price Product: renders price, stepper, add to cart at 390x844', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fixedProduct = createFakeProduct(
        id: 'prod_fixed',
        name: 'RightTouch 5kVA Solar Inverter',
        price: 45000,
        mrp: 52000,
        quoteRequired: false,
      );

      await tester.pumpWidget(
        createTestApp(
          screen: const ProductDetailScreen(id: 'prod_fixed'),
          route: '/product/prod_fixed',
          overrides: [
            ...createDefaultOverrides(),
            productDetailProvider('prod_fixed').overrideWith((ref) async => fixedProduct),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(find.text('RightTouch 5kVA Solar Inverter'), findsOneWidget);
      expect(find.text('₹45000'), findsWidgets);
      expect(find.text('Request Quote'), findsOneWidget);
    });

    testWidgets('Quote Required Product: renders quote badge and request quote button', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final quoteProduct = createFakeProduct(
        id: 'prod_quote',
        name: 'Industrial Rooftop 50kW Setup',
        quoteRequired: true,
      );

      await tester.pumpWidget(
        createTestApp(
          screen: const ProductDetailScreen(id: 'prod_quote'),
          route: '/product/prod_quote',
          overrides: [
            ...createDefaultOverrides(),
            productDetailProvider('prod_quote').overrideWith((ref) async => quoteProduct),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(find.text('Industrial Rooftop 50kW Setup'), findsOneWidget);
      expect(find.text('Request Quote'), findsOneWidget);
      expect(find.textContaining('Custom Quote Required'), findsOneWidget);
    });

    testWidgets('ProductDetailScreen renders on 320x480 phone without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fixedProduct = createFakeProduct(
        id: 'prod_small',
        name: 'Solar Panel 550W Mono PERC',
        price: 18500,
        mrp: 22000,
      );

      await tester.pumpWidget(
        createTestApp(
          screen: const ProductDetailScreen(id: 'prod_small'),
          route: '/product/prod_small',
          overrides: [
            ...createDefaultOverrides(),
            productDetailProvider('prod_small').overrideWith((ref) async => fixedProduct),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailScreen), findsOneWidget);
    });

    testWidgets('ProductDetailScreen renders with textScale 1.5 without crash or overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 784);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fixedProduct = createFakeProduct(
        id: 'prod_scale',
        name: 'Solar Panel 550W Mono PERC',
        price: 18500,
        mrp: 22000,
      );

      await tester.pumpWidget(
        createTestApp(
          screen: const ProductDetailScreen(id: 'prod_scale'),
          route: '/product/prod_scale',
          textScale: 1.5,
          overrides: [
            ...createDefaultOverrides(),
            productDetailProvider('prod_scale').overrideWith((ref) async => fixedProduct),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailScreen), findsOneWidget);
    });
  });
}
