import 'package:flutter_test/flutter_test.dart';
import 'package:righttouch/core/utils/format.dart';

void main() {
  group('INR Currency Formatting', () {
    test('formats positive amounts with currency symbol and commas', () {
      final res = inr(1499);
      expect(res.contains('1,499'), isTrue);
      expect(res.contains('₹'), isTrue);
    });

    test('formats large numbers with Indian/international grouping', () {
      final res = inr(245000);
      expect(res.contains('₹'), isTrue);
      expect(res.contains('245'), isTrue);
    });

    test('formats zero correctly', () {
      final res = inr(0);
      expect(res.contains('₹'), isTrue);
      expect(res.contains('0'), isTrue);
    });

    test('handles null input gracefully with fallback placeholder', () {
      expect(inr(null), '₹--');
    });
  });

  group('Date and Time Formatting', () {
    test('formats valid ISO date string to dd MMM yyyy, hh:mm a', () {
      final dt = DateTime(2026, 10, 14, 14, 30);
      final formatted = fmtDate(dt);
      expect(formatted.contains('14 Oct 2026'), isTrue);
      expect(formatted.contains('02:30 PM') || formatted.contains('2:30 PM'), isTrue);
    });

    test('formats string timestamp representation', () {
      const iso = '2026-05-20T09:15:00.000Z';
      final formatted = fmtDate(iso);
      expect(formatted.contains('2026'), isTrue);
    });

    test('returns fallback for null date input', () {
      expect(fmtDate(null), '--');
    });

    test('returns raw string as fallback on unparseable date input', () {
      expect(fmtDate('Tomorrow morning'), 'Tomorrow morning');
    });
  });

  group('Title Case Utility', () {
    test('capitalizes initial letter of each word', () {
      expect(titleCase('solar inverter repair'), 'Solar Inverter Repair');
      expect(titleCase('water heater'), 'Water Heater');
    });

    test('handles empty or single letter strings', () {
      expect(titleCase(''), '');
      expect(titleCase('a'), 'A');
    });
  });
}
