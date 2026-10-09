import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'presentation/providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  // TASK 11 — Global fallback error handlers
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[Global FlutterError] ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[Global PlatformError] $error\n$stack');
    return true;
  };

  // Global uncaught UI error UI — only active in release builds
  if (kReleaseMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                SizedBox(height: 12),
                Text(
                  'Something went wrong',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                SizedBox(height: 6),
                Text(
                  'Please restart the app or try again later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    };
  }

  // pre-warm token cache for router guard
  try {
    final t = container.read(tokenStorageProvider);
    await t.loadCache();
  } catch (_) {}

  // TASK 4 — lightweight wake-up ping for Render cold-start
  // Fire-and-forget so it doesn't block app launch.
  final api = container.read(apiClientProvider);
  api.wakeUp().then((warm) {
    if (kDebugMode) debugPrint('[Main] Backend warm: $warm');
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const RightTouchApp(),
    ),
  );
  // bootstrap profile after first frame (TASK 6 — single call)
  Future.microtask(() => container.read(authProvider.notifier).bootstrap());
}
