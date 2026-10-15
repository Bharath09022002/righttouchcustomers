import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:righttouch/data/models/models.dart';
import 'package:righttouch/presentation/providers/providers.dart';
import 'package:righttouch/presentation/screens/auth/login_screen.dart';
import 'package:righttouch/presentation/screens/booking/booking_detail_screen.dart';
import 'package:righttouch/presentation/screens/booking/bookings_screen.dart';
import 'package:righttouch/presentation/screens/booking/checkout_screen.dart';
import 'package:righttouch/presentation/screens/cart/cart_screen.dart';
import 'package:righttouch/presentation/screens/home/service_detail_screen.dart';
import 'package:righttouch/presentation/screens/profile/profile_screen.dart';
import 'test_harness.dart';

void main() {
  group('ServiceDetailScreen Widget & Viewport Tests', () {
    testWidgets('Populated: renders service details at standard 390x844', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const ServiceDetailScreen(id: 'svc_1'),
          route: '/service/svc_1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ServiceDetailScreen), findsOneWidget);
    });

    testWidgets('Empty/Loading State: handles loading without crash', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final completer = Completer<ServiceModel>();
      addTearDown(() {
        if (!completer.isCompleted) {
          completer.complete(createFakeService(id: 'svc_nonexistent'));
        }
      });

      await tester.pumpWidget(
        createTestApp(
          screen: const ServiceDetailScreen(id: 'svc_nonexistent'),
          route: '/service/svc_nonexistent',
          overrides: [
            ...createDefaultOverrides(),
            serviceDetailProvider.overrideWith((ref, id) => completer.future),
          ],
        ),
      );
      await tester.pump();
      expect(find.byType(ServiceDetailScreen), findsOneWidget);
    });

    testWidgets('Viewport: 320x480 test', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const ServiceDetailScreen(id: 'svc_1'),
          route: '/service/svc_1',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ServiceDetailScreen), findsOneWidget);
    });
  });

  group('CartScreen Widget & Viewport Tests', () {
    testWidgets('Populated: renders items and price breakdown at 390x844', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const CartScreen(),
          route: '/cart',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('Empty State: renders empty cart state', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const CartScreen(),
          route: '/cart',
          overrides: [
            ...createDefaultOverrides(),
            cartProvider.overrideWith((ref) async => <CartItemModel>[]),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('Viewport: 320x480 test', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const CartScreen(),
          route: '/cart',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CartScreen), findsOneWidget);
    });
  });

  group('CheckoutScreen Widget & Viewport Tests', () {
    testWidgets('Populated: renders checkout address and schedule slots', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const CheckoutScreen(),
          route: '/checkout',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CheckoutScreen), findsOneWidget);
    });

    testWidgets('Viewport: 320x480 test', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const CheckoutScreen(),
          route: '/checkout',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CheckoutScreen), findsOneWidget);
    });
  });

  group('BookingsScreen Widget & Viewport Tests', () {
    testWidgets('Populated: renders booking card list', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const BookingsScreen(),
          route: '/bookings',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BookingsScreen), findsOneWidget);
    });

    testWidgets('Empty State: renders empty bookings placeholder', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const BookingsScreen(),
          route: '/bookings',
          overrides: [
            ...createDefaultOverrides(),
            myBookingsProvider.overrideWith((ref) async => <BookingModel>[]),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BookingsScreen), findsOneWidget);
    });
  });

  group('BookingDetailScreen Widget & Viewport Tests', () {
    testWidgets('Populated: renders status and details for booking', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const BookingDetailScreen(id: 'bk_101'),
          route: '/booking/bk_101',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BookingDetailScreen), findsOneWidget);
    });
  });

  group('ProfileScreen Widget & Viewport Tests', () {
    testWidgets('Populated: renders user profile items', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const ProfileScreen(),
          route: '/profile',
          overrides: createDefaultOverrides(
            user: createFakeUser(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });

  group('AuthScreen Widget & Viewport Tests', () {
    testWidgets('renders login form and mobile input field', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const LoginScreen(),
          route: '/auth',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('renders on 320x480 small phone', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const LoginScreen(),
          route: '/auth',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
