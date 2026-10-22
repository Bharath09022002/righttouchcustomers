import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:righttouch/core/network/api_result.dart';
import 'package:righttouch/data/datasources/remote_gateway.dart';
import 'package:righttouch/data/models/models.dart';
import 'package:righttouch/data/repositories/repositories.dart';

class MockRemoteGateway extends Mock implements RemoteGateway {}

void main() {
  late MockRemoteGateway mockGateway;

  setUp(() {
    mockGateway = MockRemoteGateway();
  });

  group('CatalogRepository Unit Tests', () {
    test('categories parses remote list on ApiOk', () async {
      when(() => mockGateway.categories()).thenAnswer((_) async => ApiOk([
            {'_id': 'cat_1', 'name': 'Solar Services', 'type': 'service'},
            {'_id': 'cat_2', 'name': 'CCTV Security', 'type': 'service'},
          ]));

      final repo = CatalogRepository(mockGateway);
      final categories = await repo.categories();

      expect(categories.length, 2);
      expect(categories[0].id, 'cat_1');
      expect(categories[0].name, 'Solar Services');
      expect(categories[1].id, 'cat_2');
    });

    test('categories falls back to default categories on ApiError', () async {
      when(() => mockGateway.categories()).thenAnswer((_) async => const ApiErr(
            'Internal server error',
            500,
          ));

      final repo = CatalogRepository(mockGateway);
      final categories = await repo.categories();

      expect(categories, isNotEmpty);
      expect(categories.any((c) => c.name.toLowerCase().contains('solar')), isTrue);
    });

    test('service parses single ServiceModel on ApiOk', () async {
      when(() => mockGateway.service('svc_101')).thenAnswer((_) async => ApiOk({
            '_id': 'svc_101',
            'serviceName': 'Solar Panel Deep Cleaning',
            'discountedPrice': 1299,
            'rating': 4.8,
          }));

      final repo = CatalogRepository(mockGateway);
      final svc = await repo.service('svc_101');

      expect(svc.id, 'svc_101');
      expect(svc.name, 'Solar Panel Deep Cleaning');
      expect(svc.price, 1299);
      expect(svc.rating, 4.8);
    });
  });

  group('BookingRepository Unit Tests', () {
    test('myBookings extracts and returns list of BookingModel on ApiOk', () async {
      when(() => mockGateway.myBookings()).thenAnswer((_) async => const ApiOk([
            {
              '_id': 'bk_1',
              'status': 'confirmed',
              'serviceName': 'Inverter Repair',
              'totalAmount': 1499,
            },
            {
              '_id': 'bk_2',
              'status': 'pending',
              'serviceName': 'Solar Battery Check',
              'totalAmount': 899,
            },
          ]));

      final repo = BookingRepository(mockGateway);
      final bookings = await repo.myBookings();

      expect(bookings.length, 2);
      expect(bookings[0].id, 'bk_1');
      expect(bookings[0].status, 'confirmed');
      expect(bookings[1].id, 'bk_2');
      expect(bookings[1].status, 'pending');
    });

    test('cancel delegates to gateway and handles ApiOk', () async {
      when(() => mockGateway.cancelBooking('bk_1', 'Plan changed'))
          .thenAnswer((_) async => const ApiOk({'success': true, 'message': 'Booking cancelled'}));

      final repo = BookingRepository(mockGateway);
      await repo.cancel('bk_1', 'Plan changed');

      verify(() => mockGateway.cancelBooking('bk_1', 'Plan changed')).called(1);
    });
  });

  group('CartRepository Unit Tests', () {
    test('myCart parses active cart items correctly', () async {
      when(() => mockGateway.myCart()).thenAnswer((_) async => const ApiOk({
            'items': [
              {
                '_id': 'cart_item_1',
                'item': {
                  '_id': 'svc_1',
                  'name': 'AC Servicing',
                  'discountedPrice': 799,
                },
                'quantity': 1,
              }
            ]
          }));

      final repo = CartRepository(mockGateway);
      final items = await repo.myCart();

      expect(items.length, 1);
      expect(items.first.id, 'cart_item_1');
      expect(items.first.name, 'AC Servicing');
      expect(items.first.price, 799);
    });

    test('checkout invokes gateway with payload', () async {
      final payload = {
        'paymentMethod': 'online',
        'addressId': 'addr_1',
      };
      when(() => mockGateway.checkout(payload)).thenAnswer((_) async => const ApiOk({'bookingId': 'bk_new'}));

      final repo = CartRepository(mockGateway);
      await repo.checkout(payload);

      verify(() => mockGateway.checkout(payload)).called(1);
    });
  });

  group('AddressRepository Unit Tests', () {
    test('list extracts list of AddressModel', () async {
      when(() => mockGateway.addresses()).thenAnswer((_) async => ApiOk([
            {
              '_id': 'addr_1',
              'type': 'Home',
              'line': '123 Main St',
              'city': 'Coimbatore',
              'isDefault': true,
            }
          ]));

      final repo = AddressRepository(mockGateway);
      final addresses = await repo.list();

      expect(addresses.length, 1);
      expect(addresses.first.id, 'addr_1');
      expect(addresses.first.city, 'Coimbatore');
      expect(addresses.first.isDefault, isTrue);
    });

    test('getDefault extracts default AddressModel correctly', () async {
      when(() => mockGateway.defaultAddress()).thenAnswer((_) async => const ApiOk({
            'success': true,
            'message': 'Default address fetched successfully',
            'result': {
              '_id': '6ad77ecff2ac4b60fb100091',
              'label': 'home',
              'name': 'bharath p',
              'phone': '9894971618',
            }
          }));

      final repo = AddressRepository(mockGateway);
      final addr = await repo.getDefault();

      expect(addr, isNotNull);
      expect(addr!.id, '6ad77ecff2ac4b60fb100091');
      expect(addr.type.toLowerCase(), 'home');
    });
  });

  group('SupportRepository Unit Tests', () {
    test('submitQuoteRequest sends productId, quantity, addressId, and preferredContactMethod', () async {
      when(() => mockGateway.submitQuoteRequest(any())).thenAnswer((_) async => const ApiOk({
            'success': true,
            'message': 'Quote request created',
            'result': {
              'requestNumber': 'QREQ-2010210424',
              'customerId': 'cust_1',
              'productId': '6ad2eb42af3c8c7f9d56bfc6',
            }
          }));

      final repo = SupportRepository(mockGateway);
      await repo.submitQuoteRequest(
        '3BHK full wiring',
        productId: '6ad2eb42af3c8c7f9d56bfc6',
        quantity: 1,
        addressId: '6ad77ecff2ac4b60fb100091',
        locationType: 'saved',
        additionalNotes: '',
        contactMethod: 'whatsapp',
      );

      final captured = verify(() => mockGateway.submitQuoteRequest(captureAny())).captured;
      expect(captured.length, 1);
      final body = captured.first as Map<String, dynamic>;
      expect(body['productId'], '6ad2eb42af3c8c7f9d56bfc6');
      expect(body['quantity'], 1);
      expect(body['addressId'], '6ad77ecff2ac4b60fb100091');
      expect(body['locationType'], 'saved');
      expect(body['requirementDescription'], '3BHK full wiring');
      expect(body['preferredContactMethod'], 'whatsapp');
    });
  });
}
