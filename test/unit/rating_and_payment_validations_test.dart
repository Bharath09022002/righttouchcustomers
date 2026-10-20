import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:righttouch/core/network/api_result.dart';
import 'package:righttouch/data/datasources/remote_gateway.dart';
import 'package:righttouch/data/models/models.dart';
import 'package:righttouch/data/repositories/repositories.dart';

class MockRemoteGateway extends Mock implements RemoteGateway {}

void main() {
  group('Rating Validation & Model Tests', () {
    test('RatingModel.computeContent matches Auto Content Label rules', () {
      expect(RatingModel.computeContent(5), equals('Excellent'));
      expect(RatingModel.computeContent(4), equals('Excellent'));
      expect(RatingModel.computeContent(3), equals('Good'));
      expect(RatingModel.computeContent(2), equals('Average'));
      expect(RatingModel.computeContent(1), equals('Below Average'));
    });

    test('RatingModel.fromJson parses Service Rating response correctly', () {
      final json = {
        '_id': '65c9876543210fedcba54321',
        'bookingId': '65b1234567890abcdef12345',
        'bookingType': 'service',
        'serviceId': {
          '_id': '65a111111111111111111111',
          'serviceName': 'AC Master Servicing',
        },
        'productId': null,
        'technicianId': '65a222222222222222222222',
        'userId': '65a333333333333333333333',
        'rates': 5,
        'content': 'Excellent',
        'comment': 'Ramesh arrived on time and fixed the AC leakage quickly!',
        'createdAt': '2026-10-20T11:00:00.000Z',
        'updatedAt': '2026-10-20T11:00:00.000Z',
        'technician': {'avg': 4.8, 'count': 42},
        'service': {'avg': 4.7, 'count': 128},
      };

      final model = RatingModel.fromJson(json);

      expect(model.id, equals('65c9876543210fedcba54321'));
      expect(model.bookingId, equals('65b1234567890abcdef12345'));
      expect(model.bookingType, equals('service'));
      expect(model.serviceName, equals('AC Master Servicing'));
      expect(model.rates, equals(5));
      expect(model.content, equals('Excellent'));
      expect(model.comment, equals('Ramesh arrived on time and fixed the AC leakage quickly!'));
      expect(model.techAvg, equals(4.8));
      expect(model.techCount, equals(42));
      expect(model.svcAvg, equals(4.7));
      expect(model.svcCount, equals(128));
    });

    test('RatingModel.fromJson parses Product Rating response correctly', () {
      final json = {
        '_id': '65c9876543210fedcba54322',
        'bookingId': '65b1234567890abcdef12346',
        'bookingType': 'product',
        'productId': {
          '_id': '65a555555555555555555555',
          'productName': 'Copper Condenser Coil 1.5T',
        },
        'rates': 4,
        'content': 'Excellent',
        'comment': 'Great quality genuine spare part.',
        'product': {'avg': 4.5, 'count': 31},
      };

      final model = RatingModel.fromJson(json);

      expect(model.id, equals('65c9876543210fedcba54322'));
      expect(model.bookingId, equals('65b1234567890abcdef12346'));
      expect(model.bookingType, equals('product'));
      expect(model.productName, equals('Copper Condenser Coil 1.5T'));
      expect(model.rates, equals(4));
      expect(model.prodAvg, equals(4.5));
      expect(model.prodCount, equals(31));
    });
  });

  group('RatingRepository CRUD & Error Handling', () {
    late MockRemoteGateway mockGw;
    late RatingRepository repo;

    setUp(() {
      mockGw = MockRemoteGateway();
      repo = RatingRepository(mockGw);
    });

    test('getMyRatings parses list from API result', () async {
      when(() => mockGw.myRatings()).thenAnswer(
        (_) async => ApiOk({
          'success': true,
          'result': [
            {
              '_id': 'r1',
              'bookingId': 'b1',
              'bookingType': 'service',
              'rates': 5,
              'content': 'Excellent',
              'comment': 'Superb service',
            }
          ]
        }),
      );

      final list = await repo.getMyRatings();
      expect(list.length, equals(1));
      expect(list.first.id, equals('r1'));
      expect(list.first.rates, equals(5));
      expect(list.first.content, equals('Excellent'));
    });

    test('submitRating sends bookingId, bookingType, rates, comment', () async {
      when(() => mockGw.submitRating(any())).thenAnswer(
        (_) async => ApiOk({
          'success': true,
          'message': 'Service rating submitted successfully',
          'data': {'ratingId': 'r_new', 'rates': 5}
        }),
      );

      final res = await repo.submitRating(
        bookingId: '65b1234567890abcdef12345',
        bookingType: 'service',
        rates: 5,
        comment: 'Very professional technician',
      );

      expect(res['data']['ratingId'], equals('r_new'));
      verify(() => mockGw.submitRating({
            'bookingId': '65b1234567890abcdef12345',
            'bookingType': 'service',
            'rates': 5,
            'comment': 'Very professional technician',
          })).called(1);
    });

    test('updateRating sends rates and comment update', () async {
      when(() => mockGw.updateRating(any(), any())).thenAnswer(
        (_) async => ApiOk({
          'success': true,
          'message': 'Rating updated successfully',
          'data': {'ratingId': 'r1', 'rates': 4}
        }),
      );

      final res = await repo.updateRating(
        id: 'r1',
        rates: 4,
        comment: 'Updated review note',
      );

      expect(res['data']['rates'], equals(4));
      verify(() => mockGw.updateRating('r1', {
            'rates': 4,
            'comment': 'Updated review note',
          })).called(1);
    });

    test('deleteRating invokes gateway delete', () async {
      when(() => mockGw.deleteRating('r1')).thenAnswer(
        (_) async => ApiOk({'success': true, 'message': 'Rating deleted successfully'}),
      );

      await expectLater(repo.deleteRating('r1'), completes);
      verify(() => mockGw.deleteRating('r1')).called(1);
    });

    test('submitRating throws on 409 duplicate or 400 completion error', () async {
      when(() => mockGw.submitRating(any())).thenAnswer(
        (_) async => ApiErr('Rating already exists for this booking', 409),
      );

      expect(
        () => repo.submitRating(
          bookingId: 'b_dup',
          bookingType: 'service',
          rates: 5,
          comment: 'test',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('Payment Validations in PaymentRepository', () {
    late MockRemoteGateway mockGw;
    late PaymentRepository repo;

    setUp(() {
      mockGw = MockRemoteGateway();
      repo = PaymentRepository(mockGw);
    });

    test('declareCash sends cash declaration endpoint', () async {
      when(() => mockGw.declareCash('b_cash')).thenAnswer(
        (_) async => ApiOk({'success': true, 'message': 'Cash declared'}),
      );

      await expectLater(repo.declareCash('b_cash'), completes);
      verify(() => mockGw.declareCash('b_cash')).called(1);
    });

    test('declareCash throws when ALREADY_PAID or PAYMENT_IN_FLIGHT', () async {
      when(() => mockGw.declareCash('b_err')).thenAnswer(
        (_) async => ApiErr('PAYMENT_IN_FLIGHT', 409),
      );

      expect(() => repo.declareCash('b_err'), throwsA(isA<ApiException>()));
    });
  });
}
