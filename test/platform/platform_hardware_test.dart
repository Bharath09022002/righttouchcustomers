import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:righttouch/app.dart';

void main() {
  group('Platform & Hardware Integration Tests', () {
    testWidgets('Platform Brightness: App forces Light mode even when OS is in Dark Mode', (tester) async {
      // Simulate platform brightness set to dark by OS
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(() {
        tester.platformDispatcher.clearPlatformBrightnessTestValue();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: RightTouchApp(),
        ),
      );
      // Advance by 9 seconds to drain the unmanaged 8s splash watchdog timer
      await tester.pump(const Duration(seconds: 9));

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      
      // Verification: The app hardcodes ThemeMode.light and ignores platformBrightness
      expect(materialApp.themeMode, equals(ThemeMode.light));
      
      final BuildContext context = tester.element(find.byType(MaterialApp));
      final theme = Theme.of(context);
      
      // Even with OS dark mode active, the active theme brightness remains light
      expect(theme.brightness, equals(Brightness.light));
    });
  });
}
