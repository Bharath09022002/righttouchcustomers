import 'package:flutter/material.dart';
import 'login_screen.dart';

/// Signup screen using the unified Right Touch auth design, defaulting to Sign up tab.
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(initialSignup: true);
  }
}
