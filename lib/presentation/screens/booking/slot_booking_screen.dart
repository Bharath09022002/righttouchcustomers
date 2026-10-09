import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/providers.dart';

class SlotBookingScreen extends ConsumerStatefulWidget {
  final String serviceId;
  const SlotBookingScreen({super.key, required this.serviceId});
  @override
  ConsumerState<SlotBookingScreen> createState() => _S();
}

class _S extends ConsumerState<SlotBookingScreen> {
  String _type = 'instant';
  String? _date;
  String? _time;
  bool _busy = false;

  final _dates = ['Today', 'Tomorrow', 'Day after'];
  final _times = ['09:00 AM', '11:00 AM', '01:00 PM', '03:00 PM', '05:00 PM'];

  Future<void> _continue() async {
    final addr = ref.read(selectedAddressProvider);
    if (addr == null) {
      showError(
        context,
        title: 'Address Required',
        message: 'Select a service address first',
        onRetry: () => context.push('/addresses'),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(bookingRepoProvider).schedule({
        'serviceId': widget.serviceId,
        'latitude': addr.lat,
        'longitude': addr.lng,
        'bookingType': _type,
        'addressId': addr.id,
        if (_date != null) 'date': _date,
        if (_time != null) 'slot': _time,
      });
      ref.invalidate(myBookingsProvider);
      if (mounted) context.push('/booking-success');
    } catch (e) {
      if (mounted) {
        final appErr = mapException(e);
        showError(
          context,
          title: 'Booking Failed',
          message: appErr.userMessage,
          onRetry: _continue,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addrs = ref.watch(addressListProvider);
    final sel = ref.watch(selectedAddressProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule service')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Booking type', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: ChoiceChip(
              label: const Text('Instant'),
              selected: _type == 'instant',
              onSelected: (_) => setState(() => _type = 'instant'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ChoiceChip(
              label: const Text('Scheduled'),
              selected: _type == 'scheduled',
              onSelected: (_) => setState(() => _type = 'scheduled'),
            ),
          ),
        ]),
        if (_type == 'scheduled') ...[
          const SizedBox(height: 16),
          const Text('Preferred day', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _dates.map((d) => ChoiceChip(label: Text(d), selected: _date == d, onSelected: (_) => setState(() => _date = d))).toList(),
          ),
          const SizedBox(height: 12),
          const Text('Time slot', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _times.map((t) => ChoiceChip(label: Text(t), selected: _time == t, onSelected: (_) => setState(() => _time = t))).toList(),
          ),
          const Text('Slots API: GET /api/user/booking/slots', style: TextStyle(color: AppColors.grey400, fontSize: 11)),
        ],
        const SizedBox(height: 16),
        Row(children: [
          const Expanded(child: Text('Service address', style: TextStyle(fontWeight: FontWeight.w800))),
          TextButton(onPressed: () => context.push('/addresses'), child: const Text('Change')),
        ]),
        addrs.when(
          data: (list) {
            if (list.isEmpty) {
              return Card(child: ListTile(title: const Text('No address saved'), subtitle: const Text('Add your home address to check serviceability'), trailing: const Icon(Icons.add), onTap: () => context.push('/add-address')));
            }
            final cur = sel ?? list.firstWhere((a) => a.isDefault, orElse: () => list.first);
            return Column(
              children: list.map((a) => Card(
                child: RadioListTile(
                  value: a.id,
                  groupValue: cur.id,
                  title: Text('${a.type} • ${a.line}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  subtitle: Text('${a.city} ${a.pincode}'),
                  onChanged: (_) => ref.read(selectedAddressProvider.notifier).state = a,
                ),
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
        ),
        const SizedBox(height: 90),
      ]),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        color: Colors.white,
        child: AppButton(label: 'Confirm booking', loading: _busy, fullWidth: true, onPressed: _continue),
      ),
    );
  }
}
