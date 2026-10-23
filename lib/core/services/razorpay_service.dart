import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../ui/app_feedback.dart';

typedef PaymentCallback = void Function(bool success, String message);

/// Service wrapper to open native Razorpay Checkout and verify signatures
class RazorpayService {
  RazorpayService._();
  static final RazorpayService instance = RazorpayService._();

  Razorpay? _razorpay;
  PaymentRepository? _paymentRepo;
  String? _currentBookingId;
  PaymentCallback? _onComplete;

  void initialize(PaymentRepository paymentRepo) {
    _paymentRepo = paymentRepo;
    _razorpay ??= Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }

  /// Opens Razorpay Checkout screen using order details from POST /api/user/payments/:bookingId/order
  Future<void> openCheckout({
    required BuildContext context,
    required String bookingId,
    required PaymentOrderResult order,
    String? userPhone,
    String? userEmail,
    required PaymentCallback onComplete,
  }) async {
    _currentBookingId = bookingId;
    _onComplete = onComplete;

    final key = order.rzpKey;
    final orderId = order.providerOrderId;

    if (key == null || key.isEmpty) {
      showError(context, title: 'Payment Configuration', message: 'Razorpay key is not configured on the server.');
      onComplete(false, 'Missing Razorpay key');
      return;
    }

    if (orderId == null || orderId.isEmpty) {
      showError(context, title: 'Payment Error', message: 'Unable to initialize Razorpay order ID.');
      onComplete(false, 'Missing Razorpay order ID');
      return;
    }

    final options = {
      'key': key,
      'amount': order.amountPaise.toInt(), // integer paise
      'name': 'RightTouch',
      'description': 'Booking #$bookingId',
      'order_id': orderId,
      'timeout': 300, // 5 minutes
      'prefill': {
        if (userPhone != null && userPhone.isNotEmpty) 'contact': userPhone,
        if (userEmail != null && userEmail.isNotEmpty) 'email': userEmail,
      },
      'theme': {
        'color': '#00A859', // Brand green
      },
    };

    try {
      _razorpay?.open(options);
    } catch (e) {
      if (kDebugMode) debugPrint('[RazorpayService] open error: $e');
      showError(context, title: 'Payment Error', message: 'Unable to open Razorpay checkout: $e');
      onComplete(false, e.toString());
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final bookingId = _currentBookingId;
    final repo = _paymentRepo;
    if (bookingId == null || repo == null) {
      _onComplete?.call(true, 'Payment succeeded');
      return;
    }

    try {
      if (kDebugMode) {
        debugPrint('[Razorpay] Payment Success! Verifying on backend: ${response.paymentId}');
      }
      // POST /api/user/payment/verify
      await repo.verifyPayment({
        'bookingId': bookingId,
        'razorpay_order_id': response.orderId ?? '',
        'razorpay_payment_id': response.paymentId ?? '',
        'razorpay_signature': response.signature ?? '',
      });

      _onComplete?.call(true, 'Payment verified successfully!');
    } catch (e) {
      if (kDebugMode) debugPrint('[Razorpay] Verify error: $e');
      _onComplete?.call(false, 'Payment captured, but server verification is pending: $e');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (kDebugMode) {
      debugPrint('[Razorpay] Payment failed code: ${response.code}, message: ${response.message}');
    }
    _onComplete?.call(false, response.message ?? 'Payment cancelled or failed');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (kDebugMode) {
      debugPrint('[Razorpay] External wallet selected: ${response.walletName}');
    }
  }
}
