import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:righttouch/core/network/api_client.dart';
import 'package:righttouch/core/storage/token_storage.dart';

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockTokenStorage mockTokens;
  late ApiClient client;

  setUp(() {
    mockTokens = MockTokenStorage();
    when(() => mockTokens.getToken()).thenAnswer((_) async => 'fake_access_token');
    when(() => mockTokens.getRefreshToken()).thenAnswer((_) async => 'fake_refresh_token');
    when(() => mockTokens.saveToken(any())).thenAnswer((_) async {});
    when(() => mockTokens.saveRefreshToken(any())).thenAnswer((_) async {});
    when(() => mockTokens.clear()).thenAnswer((_) async {});
    client = ApiClient(mockTokens);
  });

  group('ApiClient Core Unit Tests', () {
    test('initializes with BaseOptions matching environment', () {
      expect(client.dio.options.headers['Content-Type'], 'application/json');
      expect(client.dio.interceptors, isNotEmpty);
    });

    test('injects Bearer token into headers when token is available', () async {
      final options = RequestOptions(path: '/api/user/profile');
      // Simulate interceptor onRequest
      final interceptor = client.dio.interceptors.whereType<QueuedInterceptorsWrapper>().first;
      
      interceptor.onRequest(options, RequestInterceptorHandler());
      // Give async token fetch time to settle
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(options.headers['Authorization'], 'Bearer fake_access_token');
    });

    test('strips Authorization header for /auth/refresh endpoint', () async {
      final options = RequestOptions(
        path: '/api/user/auth/refresh',
        headers: {'Authorization': 'Bearer existing_stale_token'},
      );
      final interceptor = client.dio.interceptors.whereType<QueuedInterceptorsWrapper>().first;
      interceptor.onRequest(options, RequestInterceptorHandler());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(options.headers.containsKey('Authorization'), isFalse);
    });
  });
}
