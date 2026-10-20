import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  final FlutterLocalNotificationsPlugin _localNotifs = FlutterLocalNotificationsPlugin();
  ProviderContainer? _container;
  String? _currentToken;
  String? get currentToken => _currentToken;
  bool _initialized = false;
  String _lastPermissionStatus = 'granted';

  /// Initialize Firebase Messaging, local notifications, permissions and listeners.
  Future<void> initialize(ProviderContainer container) async {
    _container = container;
    if (_initialized) return;

    try {
      // 1. Initialize Firebase App
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Initialize Local Notifications for System Status Bar Display
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _localNotifs.initialize(
        settings: const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final map = jsonDecode(response.payload!);
              if (map is Map<String, dynamic>) {
                _handleNotificationClick(map);
              }
            } catch (_) {}
          }
        },
      );

      // 3. Register Background Handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 4. Request permissions (Android 13+ & iOS)
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
      _lastPermissionStatus = (settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional)
          ? 'granted'
          : 'denied';
      debugPrint('[FCM] Permission status: ${settings.authorizationStatus} ($_lastPermissionStatus)');

      // 5. Foreground notification presentation options (iOS)
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 6. Get and register FCM token
      // ignore: deprecated_member_use
      _currentToken = await messaging.getToken();
      debugPrint('[FCM] Token: $_currentToken');
      if (_currentToken != null) {
        _syncToken(container, _currentToken!);
      }

      // 7. Token refresh listener
      // ignore: deprecated_member_use
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed: $newToken');
        _currentToken = newToken;
        _syncToken(container, newToken);
      });

      // 8. Foreground message listener -> Show Real System Notification
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Foreground] ${message.notification?.title}: ${message.notification?.body}');
        
        container.invalidate(unreadNotificationCountProvider);
        container.invalidate(notificationListProvider);

        final notif = message.notification;
        if (notif != null) {
          _showSystemNotification(
            id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: notif.title ?? 'RightTouch Alert',
            body: notif.body ?? '',
            data: message.data,
          );
        }
      });

      // 9. User tapped notification when app was in background
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

  /// Sync token and permissions to backend if user is authenticated
  Future<void> _syncToken(ProviderContainer? container, String token) async {
    final c = container ?? _container;
    if (c == null) return;
    try {
      final auth = c.read(authProvider);
      if (auth.loggedIn && !auth.isGuest) {
        await c.read(supportRepoProvider).registerDeviceToken(token);
        await c.read(supportRepoProvider).syncPermissions(status: _lastPermissionStatus);
        debugPrint('[FCM] Token and permission ($_lastPermissionStatus) registered with backend');
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

  /// Display a real Android/iOS system notification in status bar & heads-up shade
  Future<void> _showSystemNotification({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'righttouch_alerts',
        'RightTouch Alerts',
        channelDescription: 'RightTouch customer notifications and booking updates',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _localNotifs.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('[LocalNotif Error] $e');
    }
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
