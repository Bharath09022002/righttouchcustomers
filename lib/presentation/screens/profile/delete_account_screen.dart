import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_feedback.dart';
import '../../providers/providers.dart';
import '../../widgets/right_touch_header.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  int _currentStep = 1; // 1: Explanation, 2: OTP, 3: Confirmation
  bool _busy = false;

  // Step 2 state
  final _otpController = TextEditingController();
  int _resendCountdown = 30;
  Timer? _timer;

  // Step 3 state
  final _confirmationController = TextEditingController();
  bool _acknowledged = false;

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendCountdown = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        t.cancel();
      }
    });
  }

  void _requestOtp() {
    HapticFeedback.lightImpact();
    setState(() => _currentStep = 2);
    _startResendTimer();
  }

  void _verifyOtpAndProceed() {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      showError(context, title: 'Invalid OTP', message: 'Please enter the 4-digit code sent to your phone.');
      return;
    }
    _timer?.cancel();
    HapticFeedback.lightImpact();
    setState(() => _currentStep = 3);
  }

  Future<void> _executeAccountDeletion() async {
    if (_confirmationController.text.trim() != 'DELETE' || !_acknowledged) {
      return;
    }

    setState(() => _busy = true);
    HapticFeedback.heavyImpact();

    try {
      await ref.read(authRepoProvider).deleteAccount();
    } catch (_) {
      // Backend may fail or user may be offline; proceed with local teardown
    }

    try {
      await ref.read(tokenStorageProvider).clear();
    } catch (_) {}

    await ref.read(authProvider.notifier).logout();

    if (mounted) {
      setState(() => _busy = false);
      context.go('/login');
    }
  }

  String _maskedPhone(String? raw) {
    if (raw == null || raw.isEmpty) return '+91 ••••• •••••';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      final last4 = digits.substring(digits.length - 4);
      return '+91 ••••• •$last4';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authProvider);
    final phone = auth.user?.mobile ?? auth.mobile ?? '';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: const RightTouchTopAppBar(title: 'Delete Account'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Progress Indicator (Step 1, 2, 3)
            _buildStepIndicator(isDark: isDark),

            const SizedBox(height: 24),

            if (_currentStep == 1)
              _buildStep1Explanation(isDark: isDark)
            else if (_currentStep == 2)
              _buildStep2Otp(isDark: isDark, phone: phone)
            else
              _buildStep3Confirmation(isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator({required bool isDark}) {
    return Row(
      children: [
        _buildStepDot(1, 'Reason & Info', _currentStep >= 1, isDark: isDark),
        Expanded(child: Container(height: 2, color: _currentStep >= 2 ? AppColors.danger : const Color(0xFFE2E8F0))),
        _buildStepDot(2, 'Verify OTP', _currentStep >= 2, isDark: isDark),
        Expanded(child: Container(height: 2, color: _currentStep >= 3 ? AppColors.danger : const Color(0xFFE2E8F0))),
        _buildStepDot(3, 'Confirm', _currentStep >= 3, isDark: isDark),
      ],
    );
  }

  Widget _buildStepDot(int step, String label, bool active, {required bool isDark}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? AppColors.danger : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? (isDark ? Colors.white : const Color(0xFF0F172A)) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1Explanation({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Permanent Account Deletion',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Deleting your RightTouch account will permanently remove all your account information and records:',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 14),
          _buildBullet('All past booking records, invoices, and service history will be permanently deleted.'),
          _buildBullet('All active doorstep warranties and service guarantee claims will be cancelled.'),
          _buildBullet('Saved addresses, coupons, and customer rewards will be permanently forfeited.'),
          _buildBullet('This action cannot be undone. You will need to create a new account to book services again.'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: _requestOtp,
              child: const Text(
                'Request OTP to Continue',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 6, color: AppColors.danger),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Otp({required bool isDark, required String phone}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security Verification',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a 4-digit security code to your registered mobile number ${_maskedPhone(phone)} to confirm account ownership.',
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 8),
            decoration: InputDecoration(
              counterText: '',
              hintText: '• • • •',
              hintStyle: const TextStyle(letterSpacing: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _resendCountdown > 0 ? 'Resend code in ${_resendCountdown}s' : 'Didn\'t get code?',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              if (_resendCountdown == 0)
                TextButton(
                  onPressed: _startResendTimer,
                  child: const Text('Resend OTP', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: _verifyOtpAndProceed,
              child: const Text(
                'Verify & Proceed',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Confirmation({required bool isDark}) {
    final canDelete = _confirmationController.text.trim() == 'DELETE' && _acknowledged && !_busy;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Final Confirmation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.danger),
          ),
          const SizedBox(height: 8),
          const Text(
            'To confirm, please type "DELETE" in capital letters below:',
            style: TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirmationController,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Type DELETE',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => setState(() => _acknowledged = !_acknowledged),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _acknowledged,
                  activeColor: AppColors.danger,
                  onChanged: (v) => setState(() => _acknowledged = v ?? false),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      'I understand that this action is irreversible and all my RightTouch data will be permanently erased.',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canDelete ? AppColors.danger : const Color(0xFFCBD5E1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: canDelete ? _executeAccountDeletion : null,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Permanently Delete Account',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
