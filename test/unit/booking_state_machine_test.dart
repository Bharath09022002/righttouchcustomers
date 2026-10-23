import 'package:flutter_test/flutter_test.dart';
import 'package:righttouch/data/models/models.dart';

/// RightTouch Booking Lifecycle State Machine
enum BookingState {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
}

BookingState parseBookingState(String status) {
  switch (status.toLowerCase().trim()) {
    case 'pending':
    case 'awaiting':
      return BookingState.pending;
    case 'confirmed':
    case 'assigned':
    case 'accepted':
      return BookingState.confirmed;
    case 'in_progress':
    case 'inprogress':
    case 'ongoing':
      return BookingState.inProgress;
    case 'completed':
    case 'done':
      return BookingState.completed;
    case 'cancelled':
    case 'canceled':
      return BookingState.cancelled;
    default:
      throw ArgumentError('Unknown booking status: $status');
  }
}

bool canTransition(BookingState from, BookingState to) {
  switch (from) {
    case BookingState.pending:
      return to == BookingState.confirmed || to == BookingState.cancelled;
    case BookingState.confirmed:
      return to == BookingState.inProgress || to == BookingState.cancelled;
    case BookingState.inProgress:
      return to == BookingState.completed || to == BookingState.cancelled;
    case BookingState.completed:
      return false; // Terminal state
    case BookingState.cancelled:
      return false; // Terminal state
  }
}

void main() {
  group('Booking State Machine - Legal Transitions', () {
    test('pending can transition to confirmed (technician assigned)', () {
      expect(canTransition(BookingState.pending, BookingState.confirmed), isTrue);
    });

    test('pending can transition to cancelled (customer cancels early)', () {
      expect(canTransition(BookingState.pending, BookingState.cancelled), isTrue);
    });

    test('confirmed can transition to inProgress (technician arrives)', () {
      expect(canTransition(BookingState.confirmed, BookingState.inProgress), isTrue);
    });

    test('confirmed can transition to cancelled (customer cancels before start)', () {
      expect(canTransition(BookingState.confirmed, BookingState.cancelled), isTrue);
    });

    test('inProgress can transition to completed (service successfully done)', () {
      expect(canTransition(BookingState.inProgress, BookingState.completed), isTrue);
    });

    test('inProgress can transition to cancelled (emergency cancellation)', () {
      expect(canTransition(BookingState.inProgress, BookingState.cancelled), isTrue);
    });
  });

  group('Booking State Machine - Illegal Transitions', () {
    test('completed is a terminal state and cannot transition to anything', () {
      expect(canTransition(BookingState.completed, BookingState.pending), isFalse);
      expect(canTransition(BookingState.completed, BookingState.confirmed), isFalse);
      expect(canTransition(BookingState.completed, BookingState.inProgress), isFalse);
      expect(canTransition(BookingState.completed, BookingState.cancelled), isFalse);
    });

    test('cancelled is a terminal state and cannot transition to anything', () {
      expect(canTransition(BookingState.cancelled, BookingState.pending), isFalse);
      expect(canTransition(BookingState.cancelled, BookingState.confirmed), isFalse);
      expect(canTransition(BookingState.cancelled, BookingState.inProgress), isFalse);
      expect(canTransition(BookingState.cancelled, BookingState.completed), isFalse);
    });

    test('pending cannot jump directly to completed', () {
      expect(canTransition(BookingState.pending, BookingState.completed), isFalse);
    });

    test('pending cannot jump directly to inProgress without confirmation', () {
      expect(canTransition(BookingState.pending, BookingState.inProgress), isFalse);
    });
  });

  group('BookingModel parsing and status extraction', () {
    test('parses pending booking with defaults correctly', () {
      final json = {
        '_id': 'bk_123',
        'status': 'pending',
        'serviceName': 'Solar Panel Cleaning',
        'totalAmount': 1499,
        'scheduledAt': '2026-10-15T10:00:00Z',
      };
      final model = BookingModel.fromJson(json);
      expect(model.id, 'bk_123');
      expect(model.status, 'pending');
      expect(model.serviceName, 'Solar Panel Cleaning');
      expect(model.amount, 1499);
      expect(parseBookingState(model.status), BookingState.pending);
    });

    test('parses nested services list when serviceName is absent', () {
      final json = {
        'id': 'bk_456',
        'bookingStatus': 'confirmed',
        'services': [
          {'name': 'Inverter Battery Check', 'cost': 899}
        ],
        'technician': {'name': 'Ramesh Kumar'},
      };
      final model = BookingModel.fromJson(json);
      expect(model.id, 'bk_456');
      expect(model.status, 'confirmed');
      expect(model.serviceName, 'Inverter Battery Check');
      expect(model.technicianName, 'Ramesh Kumar');
      expect(parseBookingState(model.status), BookingState.confirmed);
    });

    test('falls back to default service title when all name fields are empty', () {
      final json = {
        'bookingId': 'bk_789',
        'status': 'in_progress',
      };
      final model = BookingModel.fromJson(json);
      expect(model.serviceName, 'Service');
      expect(parseBookingState(model.status), BookingState.inProgress);
    });

    test('throws ArgumentError on invalid status string', () {
      expect(() => parseBookingState('corrupted_status'), throwsArgumentError);
    });
  });
}
