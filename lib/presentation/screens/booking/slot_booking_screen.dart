import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/ui/app_feedback.dart';
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
      String? resolvedDate;
      if (_type == 'scheduled' && _date != null) {
        final now = DateTime.now();
        final dt = _date == 'Tomorrow'
            ? now.add(const Duration(days: 1))
            : (_date == 'Day after' ? now.add(const Duration(days: 2)) : now);
        resolvedDate = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
      await ref.read(bookingRepoProvider).schedule({
        'serviceId': widget.serviceId,
        'latitude': addr.lat,
        'longitude': addr.lng,
        'bookingType': _type,
        'addressId': addr.id,
        if (resolvedDate != null) 'date': resolvedDate,
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
        // Trust & Guarantee Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: const [
              Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '30-Day Service Guarantee • Free re-visit if unsatisfied',
                  style: TextStyle(
                    color: Color(0xFF15803D),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Booking type', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: ChoiceChip(
              label: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFF59E0B)),
                  SizedBox(width: 4),
                  Text('Instant (2 hrs)'),
                ],
              ),
              selected: _type == 'instant',
              onSelected: (_) => setState(() => _type = 'instant'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ChoiceChip(
              label: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.calendar_today_rounded, size: 14),
                  SizedBox(width: 4),
                  Text('Schedule slot'),
                ],
              ),
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
            return RadioGroup<String>(
              groupValue: cur.id,
              onChanged: (id) {
                if (id != null) {
                  final picked = list.firstWhere((a) => a.id == id, orElse: () => list.first);
                  ref.read(selectedAddressProvider.notifier).state = picked;
                }
              },
              child: Column(
                children: list.map((a) => Card(
                  child: RadioListTile<String>(
                    value: a.id,
                    title: Text('${a.type} • ${a.line}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: Text('${a.city} ${a.pincode}'),
                  ),
                )).toList(),
              ),
            );
          },
          loading: () => const Center(child: RtLoader()),
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
