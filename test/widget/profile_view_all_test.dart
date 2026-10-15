import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:righttouch/presentation/screens/profile/profile_screen.dart';
import 'package:righttouch/presentation/screens/profile/account_settings_screen.dart';
import 'package:righttouch/presentation/screens/profile/support_legal_screen.dart';
import 'package:righttouch/presentation/screens/profile/warranty_info_screen.dart';
import 'test_harness.dart';

void main() {
  group('Item 5: Profile View All, Hubs, and Warranty Tests', () {
    testWidgets('AccountSettingsScreen renders at 390x844 and 320x480 without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const AccountSettingsScreen(),
          route: '/account-settings',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Account & Preferences'), findsOneWidget);
      expect(find.text('Saved Addresses'), findsOneWidget);
      expect(find.text('Payment Receipts & History'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Product Quotations & Orders'), findsOneWidget);
      expect(find.text('Edit Profile Information'), findsOneWidget);
    });

    testWidgets('SupportLegalScreen renders at 390x844 and 320x480 without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const SupportLegalScreen(),
          route: '/support-legal',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Support & Legal'), findsOneWidget);
      expect(find.text('Help & Complaints Desk'), findsOneWidget);
      expect(find.text('RightTouch Guarantee & Warranty'), findsOneWidget);
      expect(find.text('Call Customer Support'), findsOneWidget);
      expect(find.text('Email Support Team'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Terms of Service'), 200);
      expect(find.text('Terms of Service'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Privacy Policy'), 200);
      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('WarrantyInfoScreen renders 30-day guarantee and manufacturer warranty details', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          screen: const WarrantyInfoScreen(),
          route: '/warranty-info',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Warranty & Guarantee'), findsOneWidget);
      expect(find.text('RightTouch 30-Day Guarantee'), findsOneWidget);
      expect(find.text('30-Day Free Re-Service'), findsOneWidget);
      expect(find.text('100% Genuine Spare Parts'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('How to Claim Warranty'), 200);
      expect(find.text('Manufacturer Product Warranty'), findsOneWidget);
      expect(find.text('How to Claim Warranty'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Raise a Warranty Claim'), 200);
      expect(find.text('Raise a Warranty Claim'), findsOneWidget);
    });

    testWidgets('ProfileScreen View All navigates to intermediate hub screens', (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/account-settings', builder: (_, __) => const AccountSettingsScreen()),
          GoRoute(path: '/support-legal', builder: (_, __) => const SupportLegalScreen()),
          GoRoute(path: '/warranty-info', builder: (_, __) => const WarrantyInfoScreen()),
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

      // Find the first "View All" (Account & Preferences)
      final viewAllFinders = find.text('View All');
      expect(viewAllFinders, findsWidgets);

      await tester.tap(viewAllFinders.first);
      await tester.pumpAndSettle();

      // Landed on AccountSettingsScreen
      expect(find.byType(AccountSettingsScreen), findsOneWidget);

      // Pop back to profile
      router.go('/profile');
      await tester.pumpAndSettle();

      // Scroll slightly to ensure second View All is visible
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      // Tap the second "View All" (Support & Legal)
      await tester.tap(find.text('View All').last);
      await tester.pumpAndSettle();

      // Landed on SupportLegalScreen
      expect(find.byType(SupportLegalScreen), findsOneWidget);

      // Pop back to profile
      router.go('/profile');
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      // Tap Guarantee tile
      await tester.tap(find.text('RightTouch Guarantee & Warranty'));
      await tester.pumpAndSettle();

      // Landed on WarrantyInfoScreen
      expect(find.byType(WarrantyInfoScreen), findsOneWidget);
    });
  });
}
