import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../firebase_options.dart';
import '../../presentation/providers/providers.dart';
import '../router/app_router.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  debugPrint('[FCM Background] ${message.messageId} | ${message.notification?.title}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  ProviderContainer? _container;
  String? _currentToken;
  String? get currentToken => _currentToken;
  bool _initialized = false;

  /// Initialize Firebase Messaging, permissions and listeners.
  Future<void> initialize(ProviderContainer container) async {
    _container = container;
    if (_initialized) return;

    try {
      // 1. Initialize Firebase App
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Register Background Handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Request permissions (Android 13+ & iOS)
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      // 4. Foreground notification presentation options (iOS)
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Get and register FCM token
      // ignore: deprecated_member_use
      _currentToken = await messaging.getToken();
      debugPrint('[FCM] Token: $_currentToken');
      if (_currentToken != null) {
        _syncToken(container, _currentToken!);
      }

      // 6. Token refresh listener
      // ignore: deprecated_member_use
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed: $newToken');
        _currentToken = newToken;
        _syncToken(container, newToken);
      });

      // 7. Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Foreground] ${message.notification?.title}: ${message.notification?.body}');
        
        // Invalidate notification caches so UI updates immediately
        container.invalidate(unreadNotificationCountProvider);
        container.invalidate(notificationListProvider);

        // Show in-app banner for foreground notification
        final notif = message.notification;
        if (notif != null) {
          _showForegroundBanner(
            title: notif.title ?? 'New Notification',
            body: notif.body ?? '',
            data: message.data,
          );
        }
      });

      // 8. User tapped notification when app was in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM Opened App] ${message.data}');
        _handleNotificationClick(message.data);
      });

      // 9. User opened app by tapping notification when app was terminated
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM Initial Message] ${initialMessage.data}');
        _handleNotificationClick(initialMessage.data);
      }

      _initialized = true;
    } catch (e, stack) {
      debugPrint('[FCM Init Error] $e\n$stack');
    }
  }

  /// Sync token to backend if user is authenticated
  Future<void> _syncToken(ProviderContainer? container, String token) async {
    final c = container ?? _container;
    if (c == null) return;
    try {
      final auth = c.read(authProvider);
      if (auth.loggedIn && !auth.isGuest) {
        await c.read(supportRepoProvider).registerDeviceToken(token);
        debugPrint('[FCM] Token registered with backend');
      }
    } catch (e) {
      debugPrint('[FCM] Failed to register token with backend: $e');
    }
  }

  /// Manually sync current token (e.g. called right after user signs in)
  Future<void> syncCurrentToken([ProviderContainer? container]) async {
    final c = container ?? _container;
    // ignore: deprecated_member_use
    final token = _currentToken ?? await FirebaseMessaging.instance.getToken();
    if (token != null) {
      _currentToken = token;
      await _syncToken(c, token);
    }
  }

  /// Delete token when user logs out
  Future<void> unregisterToken([ProviderContainer? container]) async {
    final c = container ?? _container;
    final token = _currentToken;
    try {
      if (c != null) {
        await c.read(supportRepoProvider).deleteDeviceToken(token);
      }
      // ignore: deprecated_member_use
      await FirebaseMessaging.instance.deleteToken();
      _currentToken = null;
      debugPrint('[FCM] Device token deleted');
    } catch (e) {
      debugPrint('[FCM] Error unregistering token: $e');
    }
  }

  /// Display an attractive foreground SnackBar / in-app alert
  void _showForegroundBanner({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Color(0xFF22C55E),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: const Color(0xFF22C55E),
          onPressed: () => _handleNotificationClick(data),
        ),
      ),
    );
  }

  /// Handle routing when user taps on notification or notification action
  void _handleNotificationClick(Map<String, dynamic> data) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    final route = data['route']?.toString();
    if (route != null && route.isNotEmpty) {
      context.push(route);
      return;
    }

    final type = (data['type'] ?? data['category'] ?? '').toString().toLowerCase();
    final id = data['id']?.toString() ?? data['bookingId']?.toString() ?? data['orderId']?.toString();

    if (type.contains('booking') && id != null && id.isNotEmpty) {
      context.push('/bookings/$id');
    } else if (type.contains('quote') || type.contains('quotation')) {
      context.push('/product-quotations');
    } else {
      context.push('/notifications');
    }
  }
}
