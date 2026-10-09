import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  const AddAddressScreen({super.key});
  @override
  ConsumerState<AddAddressScreen> createState() => _S();
}

class _S extends ConsumerState<AddAddressScreen> {
  String _type = 'Home';
  final _line = TextEditingController(text: '123 Main St, Near Bus Stand');
  final _city = TextEditingController(text: 'Tirupur');
  final _state = TextEditingController(text: 'Tamil Nadu');
  final _pin = TextEditingController(text: '641601');
  final _lat = TextEditingController(text: '11.1085');
  final _lng = TextEditingController(text: '77.3411');
  bool _busy = false;
  String? _err;
  String? _zoneMsg;

  Future<void> _checkZone() async {
    final lat = double.tryParse(_lat.text) ?? 0;
    final lng = double.tryParse(_lng.text) ?? 0;
    try {
      final z = await ref.read(supportRepoProvider).zoneCheck(lat, lng);
      setState(() => _zoneMsg = z == null ? 'Zone check failed' : 'Serviceable: ${z['serviceable'] ?? z}');
    } catch (e) {
      setState(() => _zoneMsg = '$e');
    }
  }

  Future<void> _save() async {
    setState(() { _busy = true; _err = null; });
    try {
      await ref.read(addressRepoProvider).create(AddressModel(
        id: '', type: _type, line: _line.text.trim(), city: _city.text.trim(),
        state: _state.text.trim(), pincode: _pin.text.trim(),
        lat: double.tryParse(_lat.text) ?? 0, lng: double.tryParse(_lng.text) ?? 0,
      ));
      ref.invalidate(addressListProvider);
      if (mounted) {
        showSuccess(
          context,
          title: 'Address Saved',
          message: 'Your address has been saved successfully.',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final appErr = mapException(e);
        setState(() => _err = appErr.userMessage);
        showError(
          context,
          title: 'Failed to Save Address',
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
      appBar: AppBar(title: const Text('Add address')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Wrap(
          spacing: 8,
          children: ['Home', 'Work', 'Other'].map((t) => ChoiceChip(label: Text(t), selected: _type == t, onSelected: (_) => setState(() => _type = t))).toList(),
        ),
        const SizedBox(height: 12),
        TextField(controller: _line, decoration: const InputDecoration(labelText: 'Address line')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: _city, decoration: const InputDecoration(labelText: 'City'))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: _state, decoration: const InputDecoration(labelText: 'State'))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: _pin, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pincode'))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: _lat, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Latitude'))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: _lng, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Longitude'))),
        ]),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: _checkZone, icon: const Icon(Icons.radar), label: const Text('Check serviceability (GPS zone)')),
        if (_zoneMsg != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_zoneMsg!, style: const TextStyle(fontSize: 12))),
        if (_err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_err!, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 16),
        AppButton(label: 'Save address', loading: _busy, fullWidth: true, onPressed: _save),
      ]),
    );
  }
}
