import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:righttouch/core/network/api_result.dart';
import 'package:righttouch/core/storage/token_storage.dart';
import 'package:righttouch/data/datasources/remote_gateway.dart';
import 'package:righttouch/data/models/models.dart';
import 'package:righttouch/data/repositories/repositories.dart';
import 'package:righttouch/presentation/providers/providers.dart';

import 'package:shared_preferences/shared_preferences.dart';

class MockRemoteGateway extends Mock implements RemoteGateway {}
class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TokenStorage & JWT Debug Parsing', () {
    test('TokenStorage initializes with null cached token', () {
      final storage = TokenStorage();
      expect(storage.cachedToken, isNull);
      expect(storage.isLoggedInSync, isFalse);
    });

    test('isLoggedInSync returns true when cachedToken is non-empty', () {
      final storage = TokenStorage();
      storage.cachedToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.t-ae';
      expect(storage.isLoggedInSync, isTrue);
    });

    test('debugValidateJwt handles malformed token safely without throwing', () {
      expect(() => TokenStorage.debugValidateJwt('not.a.valid.jwt'), returnsNormally);
      expect(() => TokenStorage.debugValidateJwt(''), returnsNormally);
      expect(() => TokenStorage.debugValidateJwt(null), returnsNormally);
    });
  });

  group('AuthNotifier & State Transitions', () {
    late MockRemoteGateway mockGateway;
    late MockTokenStorage mockTokenStorage;
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockGateway = MockRemoteGateway();
      mockTokenStorage = MockTokenStorage();
      when(() => mockTokenStorage.clear()).thenAnswer((_) async {});
      when(() => mockTokenStorage.saveMobile(any())).thenAnswer((_) async {});
      when(() => mockTokenStorage.getMobile()).thenAnswer((_) async => null);
      when(() => mockTokenStorage.loadCache()).thenAnswer((_) async {});
      when(() => mockTokenStorage.saveToken(any())).thenAnswer((_) async {});
      when(() => mockTokenStorage.saveRefreshToken(any())).thenAnswer((_) async {});
      when(() => mockTokenStorage.getToken()).thenAnswer((_) async => null);
      when(() => mockTokenStorage.getRefreshToken()).thenAnswer((_) async => null);

      container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(mockTokenStorage),
          gatewayProvider.overrideWithValue(mockGateway),
          cartProvider.overrideWith((ref) => Future.value([])),
          myBookingsProvider.overrideWith((ref) => Future.value([])),
          addressListProvider.overrideWith((ref) => Future.value([])),
          notificationListProvider.overrideWith((ref) => Future.value([])),
          unreadNotificationCountProvider.overrideWith((ref) => Future.value(0)),
          paymentListProvider.overrideWith((ref) => Future.value([])),
          quotationListProvider.overrideWith((ref) => Future.value([])),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial auth state is unauthenticated and mode is login', () {
      final state = container.read(authProvider);
      expect(state.loggedIn, isFalse);
      expect(state.isGuest, isFalse);
      expect(state.loading, isFalse);
      expect(state.mode, AuthMode.login);
    });

    test('setMode flips between login and signup mode', () {
      final notifier = container.read(authProvider.notifier);
      notifier.setMode(AuthMode.signup);
      expect(container.read(authProvider).mode, AuthMode.signup);

      notifier.setMode(AuthMode.login);
      expect(container.read(authProvider).mode, AuthMode.login);
    });

    test('continueAsGuest sets guest state and guest user model', () {
      final notifier = container.read(authProvider.notifier);
      notifier.continueAsGuest();

      final state = container.read(authProvider);
      expect(state.loggedIn, isTrue);
      expect(state.isGuest, isTrue);
      expect(state.user, isNotNull);
      expect(state.user!.id, 'guest_user');
      expect(state.user!.fname, 'Guest');
    });

    test('requestOtp dispatches login request on login mode', () async {
      when(() => mockGateway.loginCustomer('9876543210')).thenAnswer(
        (_) async => const ApiOk({
          'purpose': 'LOGIN',
          'expiresInSeconds': 300,
        }),
      );

      final notifier = container.read(authProvider.notifier);
      final err = await notifier.requestOtp('9876543210', mode: AuthMode.login);

      expect(err, isNull);
      final state = container.read(authProvider);
      expect(state.mobile, '9876543210');
      expect(state.otpHint, contains('Login OTP sent'));
      verify(() => mockGateway.loginCustomer('9876543210')).called(1);
    });

    test('requestOtp dispatches signup request on signup mode', () async {
      when(() => mockGateway.signupCustomer('9876543210')).thenAnswer(
        (_) async => const ApiOk({
          'purpose': 'SIGNUP',
          'expiresInSeconds': 300,
        }),
      );

      final notifier = container.read(authProvider.notifier);
      final err = await notifier.requestOtp('9876543210', mode: AuthMode.signup);

      expect(err, isNull);
      final state = container.read(authProvider);
      expect(state.otpHint, contains('Signup OTP sent'));
      verify(() => mockGateway.signupCustomer('9876543210')).called(1);
    });

    test('logout resets auth state to unauthenticated default', () async {
      when(() => mockGateway.logout()).thenAnswer((_) async => const ApiOk({'success': true}));

      final notifier = container.read(authProvider.notifier);
      notifier.continueAsGuest();
      expect(container.read(authProvider).loggedIn, isTrue);

      await notifier.logout();
      final state = container.read(authProvider);
      expect(state.loggedIn, isFalse);
      expect(state.isGuest, isFalse);
      expect(state.user, isNull);
    });
  });
}
