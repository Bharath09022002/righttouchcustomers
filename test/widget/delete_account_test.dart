import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:righttouch/core/network/api_result.dart';
import 'package:righttouch/core/storage/token_storage.dart';
import 'package:righttouch/data/repositories/repositories.dart';
import 'package:righttouch/presentation/providers/providers.dart';
import 'package:righttouch/presentation/screens/profile/account_settings_screen.dart';
import 'package:righttouch/presentation/screens/profile/delete_account_screen.dart';
import 'test_harness.dart';

class FakeTokenStorage extends Fake implements TokenStorage {
  @override
  Future<void> clear() async {}
}

class FakeAuthRepository extends Fake implements AuthRepository {
  @override
  Future<ApiResult<dynamic>> deleteAccount() async {
    return const ApiOk({'status': 'deleted'});
  }
}

class FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  FakeAuthNotifier(super.initial);
  @override
  Future<void> logout({bool allDevices = false}) async {
    state = AuthState(loggedIn: false);
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Item 7: Delete Account Multi-Step Safety Tests', () {
    testWidgets('AccountSettingsScreen renders low-emphasis Delete Account button', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          screen: const AccountSettingsScreen(),
          route: '/account-settings',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets('DeleteAccountScreen full multi-step flow: Info -> OTP -> Type DELETE -> Execute', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/delete-account',
        routes: [
          GoRoute(path: '/delete-account', builder: (_, __) => const DeleteAccountScreen()),
          GoRoute(path: '/login', builder: (_, __) => const Scaffold(body: Text('Login Screen'))),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...createDefaultOverrides(),
            tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
            authRepoProvider.overrideWithValue(FakeAuthRepository()),
            authProvider.overrideWith((ref) => FakeAuthNotifier(AuthState(loggedIn: true))),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Explanation
      expect(find.text('Permanent Account Deletion'), findsOneWidget);
      expect(find.text('Request OTP to Continue'), findsOneWidget);

      // Tap Request OTP
      await tester.tap(find.text('Request OTP to Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Step 2: OTP Verification
      expect(find.text('Security Verification'), findsOneWidget);
      expect(find.text('Verify & Proceed'), findsOneWidget);

      // Enter OTP "1234"
      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();

      // Tap Verify & Proceed (cancels periodic resend timer)
      await tester.tap(find.text('Verify & Proceed'));
      await tester.pumpAndSettle();

      // Step 3: Final Confirmation
      expect(find.text('Final Confirmation'), findsOneWidget);
      expect(find.text('To confirm, please type "DELETE" in capital letters below:'), findsOneWidget);

      // Verify Delete button is initially disabled
      final deleteBtnFinder = find.widgetWithText(ElevatedButton, 'Permanently Delete Account');
      expect(deleteBtnFinder, findsOneWidget);
      final ElevatedButton btnWidget = tester.widget(deleteBtnFinder);
      expect(btnWidget.onPressed, isNull);

      // Type "DELETE"
      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pumpAndSettle();

      // Still disabled without checkbox
      final ElevatedButton btnWidgetAfterText = tester.widget(deleteBtnFinder);
      expect(btnWidgetAfterText.onPressed, isNull);

      // Tap Checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Now button is enabled
      final ElevatedButton btnWidgetEnabled = tester.widget(deleteBtnFinder);
      expect(btnWidgetEnabled.onPressed, isNotNull);

      // Tap Delete
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      // Successfully redirected to login
      expect(find.text('Login Screen'), findsOneWidget);
    });
  });
}
