import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:righttouch/core/network/api_result.dart';
import 'package:righttouch/core/ui/app_feedback.dart';

void main() {
  group('Error Mapping - mapException', () {
    test('passes through existing AppException unchanged', () {
      final original = AppException('Existing error', statusCode: 400);
      final mapped = mapException(original);
      expect(mapped.userMessage, 'Existing error');
      expect(mapped.statusCode, 400);
    });

    test('maps ApiException with 401 status to sign-in message', () {
      final apiEx = ApiException('jwt expired', 401);
      final mapped = mapException(apiEx);
      expect(mapped.userMessage, 'Please sign in to complete this action.');
      expect(mapped.statusCode, 401);
    });

    test('maps ApiException with unauthorized string to sign-in message', () {
      final apiEx = ApiException('Unauthorized access attempt');
      final mapped = mapException(apiEx);
      expect(mapped.userMessage, 'Please sign in to complete this action.');
      expect(mapped.statusCode, 401);
    });

    test('extracts custom error message from ApiException', () {
      final apiEx = ApiException('Selected slot is no longer available.', 409);
      final mapped = mapException(apiEx);
      expect(mapped.userMessage, 'Selected slot is no longer available.');
      expect(mapped.statusCode, 409);
    });

    test('maps DioException connection timeout', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/api/user/checkout'),
        type: DioExceptionType.connectionTimeout,
      );
      final mapped = mapException(dioEx);
      expect(mapped.userMessage, contains('Server is taking too long'));
    });

    test('maps DioException connection error to no internet', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/api/user/checkout'),
        type: DioExceptionType.connectionError,
      );
      final mapped = mapException(dioEx);
      expect(mapped.userMessage, 'No internet connection.');
    });

    test('maps DioException 401 status code response', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/api/user/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/user/me'),
          statusCode: 401,
          data: {'message': 'Invalid token'},
        ),
      );
      final mapped = mapException(dioEx);
      expect(mapped.userMessage, 'Please sign in to continue.');
      expect(mapped.statusCode, 401);
    });

    test('maps DioException 404 response to not found message', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/api/user/service/unknown'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/user/service/unknown'),
          statusCode: 404,
        ),
      );
      final mapped = mapException(dioEx);
      expect(mapped.userMessage, 'Requested item not found.');
      expect(mapped.statusCode, 404);
    });

    test('extracts nested backend response message from DioException', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/api/user/booking'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/user/booking'),
          statusCode: 400,
          data: {
            'success': false,
            'message': 'Address is outside service territory',
          },
        ),
      );
      final mapped = mapException(dioEx);
      expect(mapped.userMessage, 'Address is outside service territory');
    });

    test('maps generic Exception string cleanly', () {
      final ex = Exception('Something failed during data sync');
      final mapped = mapException(ex);
      expect(mapped.userMessage, 'Something failed during data sync');
    });
  });
}
