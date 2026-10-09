import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/providers.dart';

/// Image2 panel 2 — phone OTP only (no password / role dropdown).
/// POST /api/user/signup/customer {identifier, role, terms, privacy}.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _S();
}

class _S extends ConsumerState<SignupScreen> {
  late final TextEditingController _ctrl;
  bool _terms = false;
  bool _privacy = false;
  String? _err;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: ref.read(authProvider).mobile ?? '');
    Future.microtask(
        () => ref.read(authProvider.notifier).setMode(AuthMode.signup));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final m = normalizeIndianMobile(_ctrl.text);
    if (!isValidIndianMobile(m)) {
      setState(() => _err = 'Enter a valid 10-digit mobile number');
      return;
    }
    if (!(_terms && _privacy)) {
      setState(() =>
          _err = 'Please accept Terms of Service and Privacy Policy.');
      return;
    }
    setState(() {
      _err = null;
      _busy = true;
    });
    final e = await ref
        .read(authProvider.notifier)
        .requestOtp(m, mode: AuthMode.signup);
    if (!mounted) return;
    setState(() => _busy = false);
    if (e != null) {
      if (e.toLowerCase().contains('already registered') ||
          e.toLowerCase().contains('already exist')) {
        ref.read(authProvider.notifier).setMode(AuthMode.login);
        showError(
          context,
          title: 'Already Registered',
          message: 'This mobile number is already registered. Please proceed to Login.',
          actionLabel: 'Go to Login',
          onAction: () => context.go('/login'),
        );
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
        message: 'Account OTP sent to +91 $m (valid 5 min)',
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
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.pop(context);
                        } else {
                          context.go('/login');
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Hello! Register to\nGet Started',
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w900, height: 1.25)),
                  const SizedBox(height: 8),
                  const Text('Create your account with just your mobile number.',
                      style:
                          TextStyle(color: AppColors.grey600, fontSize: 13)),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        prefixText: '+91  ',
                        hintText: 'Enter your mobile number',
                        counterText: '',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 14, vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _terms,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('I accept the Terms of Service',
                        style: TextStyle(fontSize: 13)),
                    onChanged: (v) => setState(() => _terms = v ?? false),
                  ),
                  CheckboxListTile(
                    value: _privacy,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('I accept the Privacy Policy',
                        style: TextStyle(fontSize: 13)),
                    onChanged: (v) => setState(() => _privacy = v ?? false),
                  ),
                  if (_err != null) ...[
                    const SizedBox(height: 4),
                    Text(_err!,
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 13)),
                  ],
                  const SizedBox(height: 16),
                  AppButton(
                      label: 'Create account & send OTP',
                      loading: _busy,
                      fullWidth: true,
                      onPressed: _send),
                  const SizedBox(height: 22),
                  const SocialLoginRow(label: 'Or Register with'),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ',
                          style: TextStyle(
                              color: AppColors.grey600, fontSize: 13)),
                      InkWell(
                        onTap: () {
                          final m = normalizeIndianMobile(_ctrl.text);
                          if (m.isNotEmpty) {
                            ref.read(authProvider.notifier).setMobile(m);
                          }
                          ref
                              .read(authProvider.notifier)
                              .setMode(AuthMode.login);
                          if (Navigator.of(context).canPop()) {
                            Navigator.pop(context);
                          } else {
                            context.go('/login');
                          }
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text('Login Now',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13)),
                        ),
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
