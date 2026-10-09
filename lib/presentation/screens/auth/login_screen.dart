import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/providers.dart';

/// Passwordless customer auth with functional segmented Login / Sign up toggle.
/// Login → POST /api/user/login/customer
/// Sign up → POST /api/user/signup/customer (terms flags mandatory)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _S();
}

class _S extends ConsumerState<LoginScreen> {
  bool _isSignup = false;
  late final TextEditingController _ctrl;
  bool _terms = false;
  bool _privacy = false;
  String? _err;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: ref.read(authProvider).mobile ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setMode(bool signup) {
    ref
        .read(authProvider.notifier)
        .setMode(signup ? AuthMode.signup : AuthMode.login);
    setState(() {
      _isSignup = signup;
      _err = null;
    });
  }

  Future<void> _send() async {
    final m = normalizeIndianMobile(_ctrl.text);
    if (!isValidIndianMobile(m)) {
      setState(() => _err = 'Enter a valid 10-digit mobile number');
      return;
    }
    if (_isSignup && !(_terms && _privacy)) {
      setState(() => _err = 'Please accept Terms of Service and Privacy Policy.');
      return;
    }
    setState(() {
      _err = null;
      _busy = true;
    });

    final e = await ref.read(authProvider.notifier).requestOtp(
          m,
          mode: _isSignup ? AuthMode.signup : AuthMode.login,
        );
    if (!mounted) return;
    setState(() => _busy = false);

    if (e != null) {
      final low = e.toLowerCase();
      if (low.contains('already registered') || low.contains('already exist')) {
        _setMode(false);
        showError(
          context,
          title: 'Already Registered',
          message: 'This mobile number is already registered. Please proceed to Login.',
          actionLabel: 'Go to Login',
          onAction: () => _setMode(false),
        );
      } else if (low.contains('signup first') ||
          low.contains('not found') ||
          low.contains('not registered')) {
        _setMode(true);
        setState(() {
          _terms = true;
          _privacy = true;
        });
        showSuccess(
          context,
          title: 'New Account',
          message: 'Number not registered — switched to Sign up, sending OTP...',
        );
        _send();
      } else {
        final appErr = mapException(e);
        showError(
          context,
          title: 'Failed to Send OTP',
          message: appErr.userMessage,
        );
      }
    } else {
      context.push('/otp');
      showSuccess(
        context,
        title: 'OTP Sent',
        message: _isSignup
            ? 'Account OTP sent to +91 $m (valid 5 min)'
            : 'Login OTP sent to +91 $m (valid 5 min)',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Center(child: BrandLogo()),
                  const SizedBox(height: 20),
                  AuthHeader(
                    title: _isSignup
                        ? 'Welcome! Register with\nOTP, no password needed.'
                        : 'Welcome! Login with\nOTP, no password needed.',
                  ),
                  const SizedBox(height: 18),
                  // Segmented Login / Sign up Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(child: _segButton('Login', !_isSignup, () => _setMode(false))),
                        Expanded(child: _segButton('Sign up', _isSignup, () => _setMode(true))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Mobile number',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      prefixText: '+91  ',
                      hintText: '98765 43210',
                      counterText: '',
                    ),
                  ),
                  if (_isSignup) ...[
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _terms,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'I accept the Terms of Service',
                        style: TextStyle(fontSize: 13),
                      ),
                      onChanged: (v) => setState(() => _terms = v ?? false),
                    ),
                    CheckboxListTile(
                      value: _privacy,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'I accept the Privacy Policy',
                        style: TextStyle(fontSize: 13),
                      ),
                      onChanged: (v) => setState(() => _privacy = v ?? false),
                    ),
                  ],
                  if (_err != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _err!,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 20),
                  AppButton(
                    label: _isSignup
                        ? 'Create account & send OTP'
                        : 'Send login OTP',
                    loading: _busy,
                    fullWidth: true,
                    onPressed: _send,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        final m = normalizeIndianMobile(_ctrl.text);
                        if (m.isNotEmpty) {
                          ref.read(authProvider.notifier).setMobile(m);
                        }
                        context.push('/otp');
                      },
                      icon: const Icon(Icons.pin_outlined, size: 18),
                      label: const Text(
                        'Already have an OTP? Enter code',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _segButton(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.ink : AppColors.grey600,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
