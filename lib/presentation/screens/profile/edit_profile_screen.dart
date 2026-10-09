import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/network/api_result.dart';
import '../../../core/ui/app_feedback.dart';
import '../../providers/providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _S();
}

class _S extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _f;
  late final TextEditingController _l;
  late final TextEditingController _e;
  bool _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    final u = ref.read(authProvider).user;
    _f = TextEditingController(text: u?.fname ?? '');
    _l = TextEditingController(text: u?.lname ?? '');
    _e = TextEditingController(text: u?.email ?? '');
  }

  Future<void> _save() async {
    setState(() { _busy = true; _err = null; });
    try {
      final r = await ref.read(authRepoProvider).updateProfile({'fname': _f.text.trim(), 'lname': _l.text.trim(), 'email': _e.text.trim()});
      if (r is ApiErr) throw Exception(r.message);
      // Invalidate authProvider / refresh user
      await ref.read(authProvider.notifier).bootstrap();
      if (!mounted) return;
      showSuccess(
        context,
        title: 'Profile Updated',
        message: 'Your profile changes have been saved.',
      );
      Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _f, decoration: const InputDecoration(labelText: 'First name')),
        const SizedBox(height: 12),
        TextField(controller: _l, decoration: const InputDecoration(labelText: 'Last name')),
        const SizedBox(height: 12),
        TextField(controller: _e, decoration: const InputDecoration(labelText: 'Email')),
        if (_err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_err!, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 16),
        AppButton(label: 'Save changes', loading: _busy, fullWidth: true, onPressed: _save),
      ]),
    );
  }
}
