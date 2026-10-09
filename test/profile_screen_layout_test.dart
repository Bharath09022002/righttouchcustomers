import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:righttouch/core/theme/app_theme.dart';
import 'package:righttouch/data/models/models.dart';
import 'package:righttouch/presentation/providers/providers.dart';
import 'package:righttouch/presentation/screens/profile/profile_screen.dart';

class FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  FakeAuthNotifier(super.initial);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final sampleUser = UserModel(
    id: 'u1',
    fname: 'Vignesh',
    lname: 'S',
    email: 'vigneshs@gmail.com',
    mobile: '+91 98765 43210',
  );

  testWidgets('ProfileScreen renders at 360x784 without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 784);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
              (ref) => FakeAuthNotifier(AuthState(loggedIn: true, user: sampleUser))),
          cartProvider.overrideWith((ref) => Future.value([
                CartItemModel(
                  id: 'c1',
                  itemId: 'p1',
                  name: 'Solar Panel',
                  itemType: 'product',
                  price: 18500,
                  qty: 2,
                )
              ])),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Vignesh S'), findsOneWidget);
    expect(find.text('vigneshs@gmail.com'), findsOneWidget);
    expect(find.text('+91 98765 43210'), findsOneWidget);
    expect(find.text('Shopping Cart & Checkout'), findsOneWidget);
    expect(find.text('Saved Addresses'), findsOneWidget);
    expect(find.text('Help & Complaints Desk'), findsOneWidget);

    // Scroll to reveal lower sections
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pump();

    expect(find.text('Need Help?'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ProfileScreen renders at 320 wide without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 784);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
              (ref) => FakeAuthNotifier(AuthState(loggedIn: true, user: sampleUser))),
          cartProvider.overrideWith((ref) => Future.value(<CartItemModel>[])),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Account & Preferences'), findsOneWidget);
    expect(find.text('Support & Legal'), findsOneWidget);

    // Scroll to reveal lower sections
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pump();

    expect(find.text('Log Out'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ProfileScreen renders with textScaleFactor 1.3 without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 784);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
              (ref) => FakeAuthNotifier(AuthState(loggedIn: true, user: sampleUser))),
          cartProvider.overrideWith((ref) => Future.value(<CartItemModel>[])),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: ProfileScreen(),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Shopping Cart & Checkout'), findsOneWidget);

    // Scroll to reveal lower sections
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pump();

    expect(find.text('Log Out'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ProfileScreen renders in dark mode without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 784);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
              (ref) => FakeAuthNotifier(AuthState(loggedIn: true, user: sampleUser))),
          cartProvider.overrideWith((ref) => Future.value(<CartItemModel>[])),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const ProfileScreen(),
        ),
      ),
    );

    await tester.pump();

    // Scroll to reveal lower sections
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pump();

    expect(find.text('Need Help?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
