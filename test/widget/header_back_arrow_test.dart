import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:righttouch/presentation/screens/cart/cart_screen.dart';
import 'package:righttouch/presentation/widgets/right_touch_header.dart';
import 'test_harness.dart';

void main() {
  group('Item 9: RightTouchTopAppBar Back Arrow Tests', () {
    testWidgets('Root tab /bookings never shows back arrow, even when modal bottom sheet is opened', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/bookings',
        routes: [
          GoRoute(
            path: '/bookings',
            builder: (context, _) => Scaffold(
              appBar: const RightTouchTopAppBar(title: 'Bookings'),
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => const SizedBox(
                        height: 200,
                        child: Text('Help Sheet Content'),
                      ),
                    );
                  },
                  child: const Text('Open Help Sheet'),
                ),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: createDefaultOverrides(),
          child: MaterialApp.router(
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Before sheet open: NO back arrow
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);

      // Open modal bottom sheet
      await tester.tap(find.text('Open Help Sheet'));
      await tester.pumpAndSettle();

      // Sheet is open
      expect(find.text('Help Sheet Content'), findsOneWidget);

      // Header must STILL have NO back arrow!
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);

      // Dismiss the sheet
      Navigator.of(tester.element(find.text('Help Sheet Content'))).pop();
      await tester.pumpAndSettle();

      // After dismiss: still NO back arrow
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    });

    testWidgets('Cart on pushed /cart displays back arrow and pops when tapped', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => context.push('/cart'),
                  child: const Text('Go to Cart'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/cart',
            builder: (context, _) => const CartScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: createDefaultOverrides(cartItems: []),
          child: MaterialApp.router(
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Push /cart
      await tester.tap(find.text('Go to Cart'));
      await tester.pumpAndSettle();

      // User requested CartScreen to remove return icon and move My Cart to left
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
      expect(find.text('My Cart'), findsOneWidget);
    });

    testWidgets('Cart rendered as tab /cart-tab does NOT show back arrow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/cart-tab',
        routes: [
          GoRoute(
            path: '/cart-tab',
            builder: (context, _) => const CartScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: createDefaultOverrides(cartItems: []),
          child: MaterialApp.router(
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // /cart-tab is a root tab destination, so no back arrow
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    });
  });
}
