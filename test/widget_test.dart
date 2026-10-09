import 'package:flutter_test/flutter_test.dart';
import 'package:righttouch/core/utils/validators.dart';
import 'package:righttouch/core/utils/format.dart';

void main() {
  test('mobile validator', () {
    expect(isValidIndianMobile('9876543210'), true);
    expect(isValidIndianMobile('12345'), false);
  });
  test('currency format', () {
    expect(inr(499).contains('499'), true);
  });
}
