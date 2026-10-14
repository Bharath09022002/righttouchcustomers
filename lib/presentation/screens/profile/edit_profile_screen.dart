import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/network/api_result.dart';
import '../../../core/ui/app_feedback.dart';
import '../../providers/providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _fnameController;
  late final TextEditingController _lnameController;
  late final TextEditingController _emailController;
  String? _gender;
  bool _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    final u = ref.read(authProvider).user;
    _fnameController = TextEditingController(text: u?.fname ?? '');
    _lnameController = TextEditingController(text: u?.lname ?? '');
    _emailController = TextEditingController(text: u?.email ?? '');
    _gender = (u?.gender != null && u!.gender!.isNotEmpty) ? u.gender!.toLowerCase() : null;
  }

  @override
  void dispose() {
    _fnameController.dispose();
    _lnameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final fname = _fnameController.text.trim();
    final lname = _lnameController.text.trim();
    final email = _emailController.text.trim();

    if (fname.isEmpty) {
      setState(() => _err = 'Please enter your first name.');
      return;
    }

    if (email.isNotEmpty) {
      final emailRegex = RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$');
      if (!emailRegex.hasMatch(email)) {
        setState(() => _err = 'Please enter a valid email address (e.g. name@example.com).');
        return;
      }
    }

    setState(() {
      _busy = true;
      _err = null;
    });

    try {
      final Map<String, dynamic> body = {
        'fname': fname,
        'lname': lname,
      };

      if (_gender != null && _gender!.isNotEmpty) {
        body['gender'] = _gender;
      }

      // Crucial: Only send email if non-empty to prevent backend 500 email validation errors
      if (email.isNotEmpty) {
        body['email'] = email;
      }

      final r = await ref.read(authProvider.notifier).updateUserProfile(body);
      if (r is ApiErr) {
        throw Exception(r.message);
      }

      if (!mounted) return;
      showSuccess(
        context,
        title: 'Profile Updated',
        message: 'Your profile details have been saved successfully.',
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final appErr = mapException(e);
      showError(
        context,
        title: 'Update Failed',
        message: appErr.userMessage,
        onRetry: _save,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final u = auth.user;
    final mobileNumber = (u?.mobile.isNotEmpty == true)
        ? u!.mobile
        : (auth.mobile ?? 'Not set');

    final initial = (u?.fname.isNotEmpty == true)
        ? u!.fname[0].toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Avatar Display
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x33059669),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x14000000),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person, color: Color(0xFF16A34A), size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Fields
            _buildInputField(
              controller: _fnameController,
              label: 'First Name *',
              hint: 'Enter your first name',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _lnameController,
              label: 'Last Name',
              hint: 'Enter your last name',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'Enter your email address',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // Gender Selector
            const Text(
              'Gender',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildGenderChip('male', 'Male'),
                const SizedBox(width: 10),
                _buildGenderChip('female', 'Female'),
                const SizedBox(width: 10),
                _buildGenderChip('other', 'Other'),
              ],
            ),
            const SizedBox(height: 20),

            // Phone Number (Read-only)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_android_rounded, color: Color(0xFF64748B), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Registered Phone Number',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mobileNumber,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 16),
                ],
              ),
            ),

            if (_err != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary, width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _err!,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Save Button
            AppButton(
              label: 'Save Changes',
              loading: _busy,
              fullWidth: true,
              onPressed: _save,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderChip(String value, String label) {
    final isSelected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _gender = isSelected ? null : value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF15803D) : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}
