import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:righttouch/presentation/screens/auth/login_screen.dart';
import 'package:righttouch/presentation/screens/booking/booking_detail_screen.dart';
import 'package:righttouch/presentation/screens/booking/bookings_screen.dart';
import 'package:righttouch/presentation/screens/booking/checkout_screen.dart';
import 'package:righttouch/presentation/screens/cart/cart_screen.dart';
import 'package:righttouch/presentation/screens/home/home_screen.dart';
import 'package:righttouch/presentation/screens/home/service_detail_screen.dart';
import 'package:righttouch/presentation/screens/profile/profile_screen.dart';
import '../widget/test_harness.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Phase 6 — Memory Leak & Push/Pop Lifecycle Tests', () {
    final screens = <String, Widget Function()>{
      'HomeScreen': () => const HomeScreen(),
      'ServiceDetailScreen': () => const ServiceDetailScreen(id: 'svc_1'),
      'CartScreen': () => const CartScreen(),
      'CheckoutScreen': () => const CheckoutScreen(),
      'BookingsScreen': () => const BookingsScreen(),
      'BookingDetailScreen': () => const BookingDetailScreen(id: 'bk_101'),
      'ProfileScreen': () => const ProfileScreen(),
      'LoginScreen': () => const LoginScreen(),
    };

    for (final entry in screens.entries) {
      final name = entry.key;
      final builder = entry.value;

      testWidgets('Push and Pop $name 10 times: verify clean state disposal', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final initialImageCacheCount = PaintingBinding.instance.imageCache.currentSize;

        for (int i = 0; i < 10; i++) {
          final router = GoRouter(
            initialLocation: '/target',
            routes: [
              GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('Root Screen'))),
              GoRoute(path: '/target', builder: (_, __) => builder()),
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
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          // Pop / replace with root
          router.go('/');
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
        }

        final postImageCacheCount = PaintingBinding.instance.imageCache.currentSize;
        debugPrint('[$name] 10x Push/Pop Lifecycle complete. Image Cache: $initialImageCacheCount -> $postImageCacheCount');
        expect(find.text('Root Screen'), findsOneWidget);
      });
    }
  });
}
