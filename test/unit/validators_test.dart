import 'package:flutter_test/flutter_test.dart';
import 'package:righttouch/core/utils/validators.dart';

void main() {
  group('Indian Mobile Validation & Normalization', () {
    test('validates standard 10-digit Indian numbers starting with 6, 7, 8, 9', () {
      expect(isValidIndianMobile('9876543210'), isTrue);
      expect(isValidIndianMobile('8123456789'), isTrue);
      expect(isValidIndianMobile('7012345678'), isTrue);
      expect(isValidIndianMobile('6381234567'), isTrue);
    });

    test('rejects numbers starting with invalid leading digit (< 6)', () {
      expect(isValidIndianMobile('5123456789'), isFalse);
      expect(isValidIndianMobile('1234567890'), isFalse);
      expect(isValidIndianMobile('0123456789'), isFalse);
    });

    test('rejects too short or too long numbers', () {
      expect(isValidIndianMobile('98765'), isFalse);
      expect(isValidIndianMobile('9876543210123'), isFalse);
    });

    test('normalizes numbers with +91 country prefix', () {
      expect(normalizeIndianMobile('+91 98765 43210'), '9876543210');
      expect(isValidIndianMobile('+91 98765 43210'), isTrue);
      expect(normalizeIndianMobile('+919876543210'), '9876543210');
      expect(isValidIndianMobile('+919876543210'), isTrue);
    });

    test('normalizes numbers with 91 prefix without plus', () {
      expect(normalizeIndianMobile('919876543210'), '9876543210');
      expect(isValidIndianMobile('919876543210'), isTrue);
    });

    test('normalizes numbers with leading 0 trunk prefix', () {
      expect(normalizeIndianMobile('09876543210'), '9876543210');
      expect(isValidIndianMobile('09876543210'), isTrue);
    });

    test('rejects alphabetical or special character inputs', () {
      expect(isValidIndianMobile('abcdefghij'), isFalse);
      expect(isValidIndianMobile('98765abcde'), isFalse);
    });
  });

  group('OTP Validation', () {
    test('validates 4-digit numeric OTP', () {
      expect(isValidOtp('1234'), isTrue);
      expect(isValidOtp('0000'), isTrue);
      expect(isValidOtp('9999'), isTrue);
      expect(isValidOtp(' 4821 '), isTrue); // trims whitespace
    });

    test('rejects OTP of incorrect length', () {
      expect(isValidOtp('123'), isFalse);
      expect(isValidOtp('12345'), isFalse);
      expect(isValidOtp(''), isFalse);
    });

    test('rejects alphanumeric OTP', () {
      expect(isValidOtp('12a4'), isFalse);
      expect(isValidOtp('abcd'), isFalse);
    });
  });

  group('Email Validation', () {
    test('validates standard email formats', () {
      expect(isValidEmail('user@righttouch.com'), isTrue);
      expect(isValidEmail('customer.service@sub.example.co.in'), isTrue);
    });

    test('rejects malformed email addresses', () {
      expect(isValidEmail('userexample.com'), isFalse);
      expect(isValidEmail('user@'), isFalse);
      expect(isValidEmail('@example.com'), isFalse);
      expect(isValidEmail('user@example'), isFalse);
      expect(isValidEmail(''), isFalse);
    });
  });
}
