import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ---------------------------------------------------------------------------
// TASK 11 — Central error mapper + popup feedback helper
// ---------------------------------------------------------------------------

/// User-friendly exception for display purposes. Raw technical detail is logged
/// via [debugPrint] only and never shown to the customer.
class AppException implements Exception {
  final String userMessage;
  final String? rawMessage;
  final int? statusCode;
  AppException(this.userMessage, {this.rawMessage, this.statusCode});
  @override
  String toString() => userMessage;
}

/// Convert a raw exception (typically [DioException]) into an [AppException]
/// with a customer-safe message. The raw message is logged in debug builds.
AppException mapException(Object error) {
  if (error is AppException) return error;

  if (error is DioException) {
    final raw = _rawMsg(error);
    if (kDebugMode) debugPrint('[AppFeedback] Raw error: $raw');

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException(
          'Server is taking too long. Please try again.',
          rawMessage: raw,
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.connectionError:
        return AppException(
          'No internet connection.',
          rawMessage: raw,
        );
      default:
        break;
    }

    final code = error.response?.statusCode;
    switch (code) {
      case 400:
        // Raw backend technical phrases like "Invalid ID format" or "Cast to ObjectId failed"
        // must never reach customer-facing UI.
        final msg = _isSafeCustomerMessage(raw)
            ? raw
            : 'Unable to process request. Please refresh and try again.';
        return AppException(msg, rawMessage: raw, statusCode: code);
      case 401:
        return AppException(
          'Session expired. Please log in again.',
          rawMessage: raw,
          statusCode: code,
        );
      case 403:
        return AppException(
          "You don't have permission to do this.",
          rawMessage: raw,
          statusCode: code,
        );
      case 404:
        return AppException(
          'Item not found.',
          rawMessage: raw,
          statusCode: code,
        );
      case 409:
        final msg = _isSafeCustomerMessage(raw)
            ? raw
            : 'This action conflicts with an existing entry.';
        return AppException(msg, rawMessage: raw, statusCode: code);
      case 429:
        return AppException(
          'Too many requests. Please wait a moment.',
          rawMessage: raw,
          statusCode: code,
        );
      default:
        if (code != null && code >= 500) {
          return AppException(
            'Something went wrong on our side. Please try again.',
            rawMessage: raw,
            statusCode: code,
          );
        }
    }
    return AppException(
      'Something went wrong. Please try again.',
      rawMessage: raw,
      statusCode: code,
    );
  }

  final msg = error.toString();
  if (msg.contains('ApiException:')) {
    final cleaned = msg.replaceAll('ApiException:', '').trim();
    return AppException(
      _isSafeCustomerMessage(cleaned)
          ? cleaned
          : 'Unable to process request. Please refresh and try again.',
      rawMessage: cleaned,
    );
  }
  return AppException(
    'Something went wrong. Please try again.',
    rawMessage: msg,
  );
}

String _rawMsg(DioException e) {
  final d = e.response?.data;
  if (d is Map) {
    for (final k in ['message', 'error', 'msg']) {
      final v = d[k];
      if (v is String && v.isNotEmpty) return v;
    }
    final r = d['result'];
    if (r is Map) {
      for (final k in ['message', 'error', 'reason']) {
        final v = r[k];
        if (v is String && v.isNotEmpty) return v;
      }
    }
  }
  return e.message ?? 'Unknown error';
}

/// Checks that an error string is safe for customer display.
/// Blocks technical backend errors (e.g. "Invalid ID format", MongoDB cast errors, BSON, stack traces).
bool _isSafeCustomerMessage(String msg) {
  if (msg.isEmpty || msg.length > 140) return false;
  if (msg.contains('\n') || msg.contains('at ') || msg.contains('Error:')) return false;
  final lower = msg.toLowerCase();
  const blockedKeywords = [
    'invalid id',
    'id format',
    'objectid',
    'cast to',
    'cast error',
    'casterror',
    'bson',
    'mongo',
    'mongoose',
    'null pointer',
    'nullpointer',
    'syntax error',
    'stack trace',
    'e11000',
    'referenceerror',
    'typeerror',
    'internal server',
    'unhandled',
    'token expired',
    'jwt',
  ];
  for (final kw in blockedKeywords) {
    if (lower.contains(kw)) return false;
  }
  if (msg.contains('_') && !msg.contains(' ')) return false;
  return true;
}

// ---------------------------------------------------------------------------
// Popup helpers — consistent, dismissible, one-at-a-time.
// ---------------------------------------------------------------------------

/// Show a success popup. Optionally include an [action] button (e.g. "View cart").
void showSuccess(
  BuildContext context, {
  required String title,
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  _dismissCurrent(context);
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _FeedbackDialog(
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.primary,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction != null
          ? () {
              Navigator.of(ctx).pop();
              onAction();
            }
          : null,
      onOk: () => Navigator.of(ctx).pop(),
    ),
  );
}

/// Show an error popup. Optionally include a [onRetry] or custom [onAction].
void showError(
  BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onRetry,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  _dismissCurrent(context);
  final actLabel = actionLabel ?? (onRetry != null ? 'Retry' : null);
  final act = onAction ?? onRetry;
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _FeedbackDialog(
      icon: Icons.error_rounded,
      iconColor: AppColors.danger,
      title: title,
      message: message,
      actionLabel: actLabel,
      onAction: act != null
          ? () {
              Navigator.of(ctx).pop();
              act();
            }
          : null,
      onOk: () => Navigator.of(ctx).pop(),
    ),
  );
}

void _dismissCurrent(BuildContext context) {
  // Dismiss any existing SnackBar to avoid stacking
  ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
}

class _FeedbackDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onOk;

  const _FeedbackDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    required this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
          ),
        ],
      ),
      actions: [
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: TextStyle(color: iconColor, fontWeight: FontWeight.w700),
            ),
          ),
        TextButton(
          onPressed: onOk,
          child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
