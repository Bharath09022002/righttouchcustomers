import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/providers.dart';

/// Image2 panel 4 — OTP only, no password reset.
/// Title + mobile subtitle + boxes + green Verify + resend + Back to Login.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});
  @override
  ConsumerState<OtpScreen> createState() => _S();
}

class _S extends ConsumerState<OtpScreen> {
  String _otp = '';
  String? _err;
  bool _busy = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startCooldown();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) {
        t.cancel();
        if (mounted) setState(() => _cooldown = 0);
      } else if (mounted) {
        setState(() => _cooldown--);
      }
    });
  }

  Future<void> _verify() async {
    if (_otp.length < 4) {
      setState(() => _err = 'Enter the OTP sent to your phone');
      return;
    }
    setState(() {
      _err = null;
      _busy = true;
    });
    // Scoped verify: signup/customer/verify-otp or login/customer/verify-otp
    // → 200/201 {token, refresh_token, expires_in, user}
    final e = await ref.read(authProvider.notifier).verifyOtp(_otp);
    if (!mounted) return;
    setState(() => _busy = false);
    if (e != null) {
      setState(() => _err = e);
      final appErr = mapException(e);
      showError(
        context,
        title: 'Verification Failed',
        message: appErr.userMessage,
        onRetry: _verify,
      );
    } else {
      final user = ref.read(authProvider).user;
      final isSignup = ref.read(authProvider).mode == AuthMode.signup;
      showSuccess(
        context,
        title: isSignup ? 'Welcome!' : 'Verified successfully',
        message: isSignup
            ? 'Account created successfully!'
            : 'Login successful!',
      );
      if (user == null || !user.profileCompleted) {
        context.go('/complete-profile');
      } else {
        context.go('/');
      }
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    final e = await ref.read(authProvider.notifier).resendOtp();
    if (!mounted) return;
    if (e != null) {
      setState(() => _err = e);
      final appErr = mapException(e);
      showError(
        context,
        title: 'Resend Failed',
        message: appErr.userMessage,
        onRetry: _resend,
      );
    } else {
      _startCooldown();
      final mobile = ref.read(authProvider).mobile ?? '';
      showSuccess(
        context,
        title: 'OTP Resent',
        message: 'OTP resent successfully to +91 $mobile',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final pinTheme = PinTheme(
      width: 64,
      height: 64,
      textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.pop(context);
                      } else {
                        context.go('/login');
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  const SizedBox(height: 6),
                  const Text('OTP Verification',
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the 4-digit verification code we just sent on your mobile number +91 ${auth.mobile ?? ''}.\nCode is valid for 5 minutes.',
                    style: const TextStyle(
                        color: AppColors.grey600, fontSize: 13, height: 1.5),
                  ),
                  if ((auth.otpHint ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.mark_email_read_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(auth.otpHint!,
                              style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Center(
                    child: Pinput(
                      length: 4,
                      autofocus: true,
                      defaultPinTheme: pinTheme,
                      focusedPinTheme: pinTheme.copyWith(
                        decoration: pinTheme.decoration!.copyWith(
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2.0,
                          ),
                        ),
                      ),
                      onChanged: (v) {
                        _otp = v;
                        if (v.length == 4 && !_busy) {
                          _verify();
                        }
                      },
                      onCompleted: (v) {
                        _otp = v;
                        if (!_busy) {
                          _verify();
                        }
                      },
                    ),
                  ),
                  if (_err != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Center(
                        child: Text(_err!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.danger, fontSize: 13)),
                      ),
                    ),
                  const SizedBox(height: 24),
                  AppButton(
                      label: 'Verify',
                      loading: _busy,
                      fullWidth: true,
                      onPressed: _verify),
                  const SizedBox(height: 18),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Didn't receive code? ",
                            style: TextStyle(
                                color: AppColors.grey600, fontSize: 13)),
                        GestureDetector(
                          onTap: _cooldown > 0 ? null : _resend,
                          child: Text(
                              _cooldown > 0
                                  ? 'Resend in ${_cooldown}s'
                                  : 'Resend',
                              style: TextStyle(
                                  color: _cooldown > 0
                                      ? AppColors.grey400
                                      : AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13)),
                        ),
                      ]),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Wrong number? ',
                          style: TextStyle(
                              color: AppColors.grey600, fontSize: 13)),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: const Text('Back to Login',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
