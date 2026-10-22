import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/env.dart';
import '../../presentation/providers/providers.dart';

/// Callback signatures for real-time customer socket events
typedef SocketEventCallback = void Function(dynamic data);

/// Central SocketService managing real-time Socket.IO connection
/// strictly adhering to the customer-app frontend handoff spec:
/// - URL: API origin only (e.g. Env.baseUrl without sub-paths)
/// - Namespace: '/'
/// - Path: '/socket.io'
/// - Auth: JWT in handshake.auth.token
/// - Transport: ['websocket', 'polling']
/// - Missed-event recovery: up to 2 minutes
/// - Auto-reconnect with exponential backoff (1s to 5s)
/// - Rate limit conscious (max 20 handshakes/min)
class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;
  String? _currentToken;
  bool _isConnected = false;
  ProviderContainer? _container;

  bool get isConnected => _isConnected;
  String? get socketId => _socket?.id;

  /// Initialize with ProviderContainer so socket events automatically refresh UI providers
  void initialize(ProviderContainer container) {
    _container = container;
  }

  // Stream controllers for app-wide reactive event handling
  final _bookingAcceptedController = StreamController<dynamic>.broadcast();
  final _bookingCompletedController = StreamController<dynamic>.broadcast();
  final _bookingCancelledController = StreamController<dynamic>.broadcast();
  final _bookingRebroadcastController = StreamController<dynamic>.broadcast();
  final _paymentSuccessController = StreamController<dynamic>.broadcast();
  final _paymentStatusController = StreamController<dynamic>.broadcast();
  final _refundInitiatedController = StreamController<dynamic>.broadcast();
  final _refundProcessedController = StreamController<dynamic>.broadcast();
  final _notificationNewController = StreamController<dynamic>.broadcast();
  final _sessionReplacedController = StreamController<void>.broadcast();

  // Public streams
  Stream<dynamic> get onBookingAccepted => _bookingAcceptedController.stream;
  Stream<dynamic> get onBookingCompleted => _bookingCompletedController.stream;
  Stream<dynamic> get onBookingCancelled => _bookingCancelledController.stream;
  Stream<dynamic> get onBookingRebroadcast => _bookingRebroadcastController.stream;
  Stream<dynamic> get onPaymentSuccess => _paymentSuccessController.stream;
  Stream<dynamic> get onPaymentStatus => _paymentStatusController.stream;
  Stream<dynamic> get onRefundInitiated => _refundInitiatedController.stream;
  Stream<dynamic> get onRefundProcessed => _refundProcessedController.stream;
  Stream<dynamic> get onNotificationNew => _notificationNewController.stream;
  Stream<void> get onSessionReplaced => _sessionReplacedController.stream;

  /// Extract the clean origin from Env.baseUrl (no subpaths like /api)
  String _getSocketOrigin() {
    try {
      final uri = Uri.parse(Env.baseUrl);
      return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    } catch (_) {
      return Env.baseUrl;
    }
  }

  /// Connect or reconnect socket with customer JWT token
  void connect(String token) {
    if (token.isEmpty) {
      if (kDebugMode) debugPrint('[Socket] Connect skipped: empty token');
      return;
    }

    if (_socket != null && _currentToken == token && _isConnected) {
      if (kDebugMode) debugPrint('[Socket] Already connected with active token');
      return;
    }

    _currentToken = token;

    if (_socket != null) {
      if (kDebugMode) debugPrint('[Socket] Reconfiguring existing socket with fresh token');
      _socket!.io.options?['auth'] = {'token': token};
      _socket!.disconnect();
      _socket!.connect();
      return;
    }

    final origin = _getSocketOrigin();
    if (kDebugMode) debugPrint('[Socket] Connecting to origin: $origin');

    _socket = io.io(
      origin,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setPath('/socket.io')
          .enableReconnection()
          .setReconnectionAttempts(99999) // Infinite reconnection
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _setupListeners();
    _socket!.connect();
  }

  /// Update JWT token (e.g. after refresh) and reconnect cleanly
  void updateTokenAndReconnect(String newToken) {
    if (newToken.isEmpty) return;
    _currentToken = newToken;
    if (_socket != null) {
      _socket!.io.options?['auth'] = {'token': newToken};
      _socket!.disconnect();
      _socket!.connect();
      if (kDebugMode) debugPrint('[Socket] Token updated, reconnecting...');
    } else {
      connect(newToken);
    }
  }

  /// Disconnect socket on logout or background
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentToken = null;
    _isConnected = false;
    if (kDebugMode) debugPrint('[Socket] Disconnected and disposed');
  }

  void _setupListeners() {
    final s = _socket;
    if (s == null) return;

    // Connection lifecycle
    s.onConnect((_) {
      _isConnected = true;
      if (kDebugMode) debugPrint('[Socket] Connected successfully. Socket ID: ${s.id}');
    });

    s.onConnectError((err) {
      _isConnected = false;
      if (kDebugMode) debugPrint('[Socket] Connect error: $err');
    });

    s.onDisconnect((_) {
      _isConnected = false;
      if (kDebugMode) debugPrint('[Socket] Disconnected from server');
    });

    // Mandatory Server Events according to handoff spec
    s.on('notification:new', (data) {
      if (kDebugMode) debugPrint('[Socket] notification:new received: $data');
      _notificationNewController.add(data);
      _container?.invalidate(unreadNotificationCountProvider);
      _container?.invalidate(notificationListProvider);
    });

    s.on('booking:accepted', (data) {
      if (kDebugMode) debugPrint('[Socket] booking:accepted received: $data');
      _bookingAcceptedController.add(data);
      _container?.invalidate(myBookingsProvider);
    });

    s.on('job_accepted', (data) {
      if (kDebugMode) debugPrint('[Socket] job_accepted (legacy) received: $data');
      _bookingAcceptedController.add(data);
      _container?.invalidate(myBookingsProvider);
    });

    s.on('booking_completed', (data) {
      if (kDebugMode) debugPrint('[Socket] booking_completed received: $data');
      _bookingCompletedController.add(data);
      _container?.invalidate(myBookingsProvider);
      _container?.invalidate(paymentListProvider);
      _container?.invalidate(paymentSummaryProvider);
    });

    s.on('booking_cancelled', (data) {
      if (kDebugMode) debugPrint('[Socket] booking_cancelled received: $data');
      _bookingCancelledController.add(data);
      _container?.invalidate(myBookingsProvider);
    });

    s.on('booking:rebroadcast', (data) {
      if (kDebugMode) debugPrint('[Socket] booking:rebroadcast received: $data');
      _bookingRebroadcastController.add(data);
      _container?.invalidate(myBookingsProvider);
    });

    s.on('payment_success', (data) {
      if (kDebugMode) debugPrint('[Socket] payment_success received: $data');
      _paymentSuccessController.add(data);
      _container?.invalidate(paymentListProvider);
      _container?.invalidate(paymentSummaryProvider);
      _container?.invalidate(myBookingsProvider);
      _container?.invalidate(productBookingsProvider);
    });

    s.on('payment:status', (data) {
      if (kDebugMode) debugPrint('[Socket] payment:status received: $data');
      _paymentStatusController.add(data);
      _container?.invalidate(paymentListProvider);
      _container?.invalidate(paymentSummaryProvider);
    });

    s.on('refund:initiated', (data) {
      if (kDebugMode) debugPrint('[Socket] refund:initiated received: $data');
      _refundInitiatedController.add(data);
      _container?.invalidate(paymentListProvider);
      _container?.invalidate(paymentSummaryProvider);
    });

    s.on('refund:processed', (data) {
      if (kDebugMode) debugPrint('[Socket] refund:processed received: $data');
      _refundProcessedController.add(data);
      _container?.invalidate(paymentListProvider);
      _container?.invalidate(paymentSummaryProvider);
    });

    s.on('session:replaced', (_) {
      if (kDebugMode) debugPrint('[Socket] session:replaced received — account active elsewhere');
      _sessionReplacedController.add(null);
      // Forced logout rule
      _container?.read(authProvider.notifier).logout();
    });
  }
}
