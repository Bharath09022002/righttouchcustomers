import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../network/api_result.dart';
import '../theme/app_colors.dart';
import '../../widgets/rt_loader.dart';

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

  bool get isAuthError =>
      statusCode == 401 ||
      userMessage.toLowerCase().contains('sign in') ||
      userMessage.toLowerCase().contains('sign-in') ||
      userMessage.toLowerCase().contains('log in') ||
      userMessage.toLowerCase().contains('login') ||
      userMessage.toLowerCase().contains('unauthorized');

  @override
  String toString() => userMessage;
}

/// Convert a raw exception (typically [DioException]) into an [AppException]
/// with a customer-safe message. The raw message is logged in debug builds.
AppException mapException(Object error) {
  if (error is AppException) return error;

  if (error is ApiException) {
    if (error.statusCode == 401 || error.message.toLowerCase().contains('unauthorized')) {
      return AppException(
        'Please sign in to complete this action.',
        rawMessage: error.message,
        statusCode: 401,
      );
    }
    final cleaned = error.message.trim();
    if (cleaned.isNotEmpty) {
      return AppException(cleaned, rawMessage: cleaned, statusCode: error.statusCode);
    }
  }

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
    if (code == 401) {
      return AppException('Please sign in to continue.', rawMessage: raw, statusCode: 401);
    }
    if (raw.isNotEmpty && raw != 'Unknown error') {
      return AppException(raw, rawMessage: raw, statusCode: code);
    }
    if (code != null) {
      if (code == 404) return AppException('Requested item not found.', rawMessage: raw, statusCode: 404);
      if (code == 403) return AppException("You don't have permission to do this.", rawMessage: raw, statusCode: 403);
      if (code >= 500) return AppException('Server error ($code). Please try again in a moment.', rawMessage: raw, statusCode: code);
    }
    return AppException(
      'Unable to complete request. Please try again.',
      rawMessage: raw,
      statusCode: code,
    );
  }

  final msg = error.toString().replaceFirst('Exception:', '').replaceFirst('ApiException:', '').trim();
  if (msg.isNotEmpty) {
    if (msg.toLowerCase().contains('unauthorized')) {
      return AppException('Please sign in to complete this action.', rawMessage: msg, statusCode: 401);
    }
    return AppException(msg, rawMessage: msg);
  }
  return AppException(
    'Unable to process request. Please try again.',
    rawMessage: msg,
  );
}

String _rawMsg(DioException e) {
  final d = e.response?.data;
  if (d is Map) {
    for (final k in ['message', 'error', 'msg', 'reason', 'detail', 'castError']) {
      final v = d[k];
      if (v is String && v.isNotEmpty) return v;
    }
    final r = d['result'];
    if (r is Map) {
      for (final k in ['message', 'error', 'reason', 'detail', 'castError']) {
        final v = r[k];
        if (v is String && v.isNotEmpty) return v;
      }
    }
    if (r is String && r.isNotEmpty) return r;
    if (d['errors'] is List && (d['errors'] as List).isNotEmpty) {
      final first = (d['errors'] as List).first;
      if (first is Map && first['message'] != null) return first['message'].toString();
      return first.toString();
    }
  } else if (d is String && d.isNotEmpty && !d.contains('<!DOCTYPE html>')) {
    return d;
  }
  return e.message ?? 'Unknown error';
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

/// Show an error / notice popup with white card, brand green icon & badge, and black text.
void showError(
  BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onRetry,
  String? actionLabel,
  VoidCallback? onAction,
  bool? isAuthRequired,
}) {
  _dismissCurrent(context);

  final isAuth = isAuthRequired == true ||
      (actionLabel == null &&
          onAction == null &&
          (message.toLowerCase().contains('sign in') ||
              message.toLowerCase().contains('sign-in') ||
              message.toLowerCase().contains('log in') ||
              message.toLowerCase().contains('login') ||
              message.toLowerCase().contains('unauthorized')));

  final actLabel = isAuth
      ? 'Log In'
      : (actionLabel ?? (onRetry != null ? 'Retry' : null));

  final act = isAuth
      ? () {
          if (context.mounted) {
            context.push('/login');
          }
        }
      : (onAction ?? onRetry);

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _FeedbackDialog(
      icon: isAuth ? Icons.login_rounded : Icons.info_outline_rounded,
      iconColor: AppColors.primary,
      iconBgColor: AppColors.primarySoft,
      title: title,
      message: message,
      actionLabel: actLabel,
      isAuth: isAuth,
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

/// Show full-screen Right Touch branded loading overlay
void showLoading(BuildContext context, {String? message}) {
  RtLoader.showOverlay(context, message: message);
}

/// Hide full-screen Right Touch branded loading overlay
Future<void> hideLoading({bool enforceMinDisplay = true}) async {
  await RtLoader.hideOverlay(enforceMinDisplay: enforceMinDisplay);
}

void _dismissCurrent(BuildContext context) {
  // Dismiss any existing SnackBar to avoid stacking
  ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
}

class _FeedbackDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color? iconBgColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onOk;
  final bool isAuth;

  const _FeedbackDialog({
    required this.icon,
    required this.iconColor,
    this.iconBgColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    required this.onOk,
    this.isAuth = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = iconBgColor ?? AppColors.primarySoft;
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Green badge container (No red)
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryBorder, width: 1.5),
            ),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(height: 16),
          // Title in solid black
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          // Message in black / dark slate
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        if (actionLabel != null && onAction != null) ...[
          // Primary Action Button (Green) - e.g. "Log In"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onAction,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isAuth) ...[
                    const Icon(Icons.login_rounded, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    actionLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Secondary Dismiss/Cancel Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onOk,
              child: Text(
                isAuth ? 'Cancel' : 'Dismiss',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onOk,
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
        ],
      ],
    );
  }
}
