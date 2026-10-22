import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:righttouch/core/theme/app_theme.dart';
import 'package:righttouch/data/models/models.dart';
import 'package:righttouch/presentation/providers/providers.dart';
import 'package:righttouch/presentation/screens/products/products_screen.dart';

void main() {
  final sampleProducts = [
    ProductModel(
      id: 'p1',
      name: 'RightTouch 550W Mono PERC Solar Panel',
      price: 18500,
      mrp: 22500,
      rating: 4.9,
      ratingCount: 120,
      categoryName: 'Solar Products',
    ),
    ProductModel(
      id: 'p2',
      name: 'RightTouch 5kVA Solar Hybrid MPPT Inverter',
      price: 42000,
      mrp: 52000,
      rating: 4.9,
      ratingCount: 86,
      categoryName: 'Solar Products',
    ),
    ProductModel(
      id: 'p3',
      name: 'RightTouch 4K Outdoor Bullet Camera',
      price: 6800,
      mrp: 8500,
      rating: 4.8,
      ratingCount: 95,
      categoryName: 'Surveillance',
    ),
    ProductModel(
      id: 'p4',
      name: 'RightTouch 1.5 Ton 5 Star Inverter AC',
      price: 38900,
      mrp: 46000,
      rating: 4.9,
      ratingCount: 110,
      categoryName: 'Appliances',
    ),
  ];

  testWidgets('ProductsScreen renders at 360x784 without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 784);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productListProvider.overrideWith((ref) => Future.value(sampleProducts)),
        ],
        child: const MaterialApp(
          home: ProductsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProductsScreen), findsOneWidget);
    expect(find.text('Quotations'), findsWidgets);
    expect(find.text('RightTouch 550W Mono PERC Solar Panel'), findsOneWidget);
  });

  testWidgets('ProductsScreen renders at 320 width without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productListProvider.overrideWith((ref) => Future.value(sampleProducts)),
        ],
        child: const MaterialApp(
          home: ProductsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProductsScreen), findsOneWidget);
    expect(find.text('Quotations'), findsWidgets);
  });

  testWidgets('ProductsScreen renders with textScaleFactor 1.3 without crash', (tester) async {
    tester.view.physicalSize = const Size(360, 784);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productListProvider.overrideWith((ref) => Future.value(sampleProducts)),
        ],
        child: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1.3),
            size: Size(360, 784),
          ),
          child: const MaterialApp(
            home: ProductsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProductsScreen), findsOneWidget);
  });

  testWidgets('ProductsScreen renders in Dark Mode', (tester) async {
    tester.view.physicalSize = const Size(360, 784);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productListProvider.overrideWith((ref) => Future.value(sampleProducts)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const ProductsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProductsScreen), findsOneWidget);
    expect(find.text('Quotations'), findsWidgets);
  });
}
