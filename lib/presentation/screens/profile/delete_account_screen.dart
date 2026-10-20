import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../widgets/right_touch_header.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  int _currentStep = 1; // 1: Reason & Info, 2: Confirm
  bool _busy = false;

  final _confirmationController = TextEditingController();
  bool _acknowledged = false;

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  void _proceedToConfirm() {
    HapticFeedback.lightImpact();
    setState(() => _currentStep = 2);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: const RightTouchTopAppBar(title: 'Delete Account'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Progress Indicator (Step 1, 2)
            _buildStepIndicator(isDark: isDark),

            const SizedBox(height: 24),

            if (_currentStep == 1)
              _buildStep1Explanation(isDark: isDark)
            else
              _buildStep2Confirmation(isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator({required bool isDark}) {
    return Row(
      children: [
        _buildStepDot(1, 'Reason & Info', _currentStep >= 1, isDark: isDark),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep >= 2 ? AppColors.danger : const Color(0xFFE2E8F0),
          ),
        ),
        _buildStepDot(2, 'Confirm', _currentStep >= 2, isDark: isDark),
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
            fontSize: 11,
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
              onPressed: _proceedToConfirm,
              child: const Text(
                'Continue to Confirmation',
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

  Widget _buildStep2Confirmation({required bool isDark}) {
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
            'To confirm permanent deletion, please type "DELETE" in capital letters below:',
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => setState(() => _currentStep = 1),
              child: const Text('Back to Warning Info', style: TextStyle(color: Color(0xFF64748B))),
            ),
          ),
        ],
      ),
    );
  }
}
