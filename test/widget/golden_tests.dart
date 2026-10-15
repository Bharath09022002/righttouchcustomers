import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:righttouch/presentation/screens/booking/booking_detail_screen.dart';
import 'package:righttouch/presentation/screens/booking/bookings_screen.dart';
import 'package:righttouch/presentation/screens/booking/checkout_screen.dart';
import 'package:righttouch/presentation/screens/cart/cart_screen.dart';
import 'package:righttouch/presentation/screens/home/home_screen.dart';
import 'package:righttouch/presentation/screens/home/service_detail_screen.dart';
import 'package:righttouch/presentation/screens/profile/profile_screen.dart';
import 'test_harness.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  final screens = <String, Widget>{
    'home_screen': const HomeScreen(),
    'service_detail_screen': const ServiceDetailScreen(id: 'svc_1'),
    'cart_screen': const CartScreen(),
    'checkout_screen': const CheckoutScreen(),
    'bookings_screen': const BookingsScreen(),
    'booking_detail_screen': const BookingDetailScreen(id: 'bk_101'),
    'profile_screen': const ProfileScreen(),
  };

  for (final entry in screens.entries) {
    final name = entry.key;
    final widget = entry.value;

    testWidgets('Golden: $name - Light Mode', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: widget,
          themeMode: ThemeMode.light,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../goldens/${name}_light.png'),
      );
    });

    testWidgets('Golden: $name - Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: widget,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../goldens/${name}_dark.png'),
      );
    });
  }
}
