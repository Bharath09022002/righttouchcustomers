import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_result.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';

/// Complete Profile (POST /api/user/complete-profile)
/// Accepts: { fname, lname, gender, email? }
/// Forces profileComplete: true on backend.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});
  @override
  ConsumerState<CompleteProfileScreen> createState() => _S();
}

class _S extends ConsumerState<CompleteProfileScreen> {
  final _f = TextEditingController();
  final _l = TextEditingController();
  final _e = TextEditingController();
  String _gender = 'Male';
  bool _busy = false;
  String? _err;

  @override
  void dispose() {
    _f.dispose();
    _l.dispose();
    _e.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final fname = _f.text.trim();
    final lname = _l.text.trim();
    final email = _e.text.trim();

    if (fname.isEmpty) {
      setState(() => _err = 'First name is required');
      return;
    }
    if (lname.isEmpty) {
      setState(() => _err = 'Last name is required');
      return;
    }

    setState(() {
      _busy = true;
      _err = null;
    });

    try {
      final r = await ref.read(authRepoProvider).completeProfile({
        'fname': fname,
        'lname': lname,
        'gender': _gender,
        if (email.isNotEmpty) 'email': email,
      });

      if (r is ApiErr) {
        throw Exception(r.message);
      }

      // Refresh profile in Riverpod
      final meRes = await ref.read(authRepoProvider).me();
      if (meRes is ApiOk) {
        final d = meRes.data;
        final m = asMap(d);
        ref.read(authProvider.notifier).setUser(
          UserModel.fromJson(m.containsKey('user') ? m['user'] : d),
        );
      }

      if (mounted) {
        showSuccess(
          context,
          title: 'Profile Completed',
          message: 'Profile completed successfully! Welcome to RightTouch.',
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        final appErr = mapException(e);
        setState(() => _err = appErr.userMessage);
        showError(
          context,
          title: 'Failed to Save Profile',
          message: appErr.userMessage,
          onRetry: _save,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Complete your profile'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Almost there! 🎉',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Please tell us your name and gender to finalize your account.',
                    style: TextStyle(color: AppColors.grey600, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  const Text('First Name *',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _f,
                    decoration: const InputDecoration(hintText: 'e.g. Ravi'),
                  ),
                  const SizedBox(height: 14),
                  const Text('Last Name *',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _l,
                    decoration: const InputDecoration(hintText: 'e.g. Kumar'),
                  ),
                  const SizedBox(height: 14),
                  const Text('Gender',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Male', 'Female', 'Other'].map((g) {
                      final sel = _gender == g;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => setState(() => _gender = g),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.primarySoft : AppColors.grey100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: sel ? AppColors.primary : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  g,
                                  style: TextStyle(
                                    fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                                    color: sel ? AppColors.primary : AppColors.grey600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  const Text('Email Address (Optional)',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _e,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'ravi@example.com'),
                  ),
                  if (_err != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _err!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Complete & continue',
                    loading: _busy,
                    fullWidth: true,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
