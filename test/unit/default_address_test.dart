import 'package:flutter_test/flutter_test.dart';
import 'package:righttouch/data/models/models.dart';

void main() {
  group('Default Address Behavior Tests', () {
    test('AddressModel correctly parses isDefault from backend responses', () {
      final json1 = {
        '_id': 'addr_123',
        'addressType': 'Home',
        'addressLine': '123 Main Street',
        'city': 'Chennai',
        'state': 'Tamil Nadu',
        'pincode': '600001',
        'isDefault': true,
      };
      final addr1 = AddressModel.fromJson(json1);
      expect(addr1.id, 'addr_123');
      expect(addr1.isDefault, true);

      final json2 = {
        '_id': 'addr_456',
        'addressType': 'Work',
        'addressLine': 'IT Park Block B',
        'city': 'Chennai',
        'state': 'Tamil Nadu',
        'pincode': '600096',
        'isDefault': false,
      };
      final addr2 = AddressModel.fromJson(json2);
      expect(addr2.id, 'addr_456');
      expect(addr2.isDefault, false);
    });

    test('Default address resolution logic prioritizes isDefault and cached ID', () {
      final list = [
        AddressModel(
          id: 'addr_1',
          type: 'Home',
          line: 'Line 1',
          city: 'City',
          state: 'State',
          pincode: '123456',
          isDefault: false,
        ),
        AddressModel(
          id: 'addr_2',
          type: 'Work',
          line: 'Line 2',
          city: 'City',
          state: 'State',
          pincode: '123456',
          isDefault: true,
        ),
      ];

      // Match isDefault
      final defaultAddr = list.firstWhere((a) => a.isDefault, orElse: () => list.first);
      expect(defaultAddr.id, 'addr_2');
      expect(defaultAddr.type, 'Work');

      // If user cached addr_1 as preferred default
      const cachedId = 'addr_1';
      final match = list.firstWhere((a) => a.id == cachedId, orElse: () => defaultAddr);
      expect(match.id, 'addr_1');
    });
  });
}
