import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:righttouch/presentation/screens/auth/login_screen.dart';

void main() {
  Widget buildTestScreen({bool initialSignup = false}) {
    return ProviderScope(
      child: MaterialApp(
        home: LoginScreen(initialSignup: initialSignup),
      ),
    );
  }

  group('Login & Register Swipeable Auth Screen Tests', () {
    testWidgets('renders exact design elements on Login tab', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Brand header & subtitle
      expect(find.text('RIGHT '), findsOneWidget);
      expect(find.text('TOUCH'), findsOneWidget);
      expect(find.text('Sign in to continue to your account'), findsOneWidget);

      // Segment tabs
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);

      // Mobile number input
      expect(find.text('Mobile number'), findsOneWidget);
      expect(find.text('+91'), findsOneWidget);
      expect(find.text('Enter 10-digit number'), findsOneWidget);

      // Security note removed per design update
      expect(
        find.text("Your number is safe with us. We'll send a 4-digit OTP."),
        findsNothing,
      );

      // Buttons & Divider
      expect(find.text('Continue with OTP'), findsOneWidget);
      expect(find.text('OR'), findsOneWidget);
      expect(find.text('Explore as Guest'), findsOneWidget);

      // Footer
      expect(find.text('By continuing, you agree to our'), findsOneWidget);
      expect(find.text('Terms'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('swiping left navigates to Sign up tab', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('Sign in to continue to your account'), findsOneWidget);

      // Fling left to swipe PageView to Sign up
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
      await tester.pumpAndSettle();

      expect(find.text('Create an account to get started'), findsOneWidget);
    });

    testWidgets('tapping Sign up tab animates to Sign up page', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('Sign in to continue to your account'), findsOneWidget);

      // Tap "Sign up" tab
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      expect(find.text('Create an account to get started'), findsOneWidget);

      // Tap "Login" tab back
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to continue to your account'), findsOneWidget);
    });
  });
}
