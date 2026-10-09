import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/utils/format.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _S();
}

class _S extends ConsumerState<CheckoutScreen> {
  String _pay = 'online';
  bool _busy = false;

  Future<void> _payNow() async {
    final addr = ref.read(selectedAddressProvider);
    if (addr == null) {
      showError(
        context,
        title: 'Address Required',
        message: 'Please select or add a delivery address first.',
        onRetry: () => context.push('/addresses'),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(cartRepoProvider).checkout({
        'locationType': 'gps',
        'latitude': addr.lat,
        'longitude': addr.lng,
        'addressLine': '${addr.line}, ${addr.city}, ${addr.state} ${addr.pincode}',
        'addressId': addr.id,
        'paymentMethod': _pay,
      });
      ref.invalidate(cartProvider);
      ref.invalidate(myBookingsProvider);
      if (mounted) context.push('/booking-success');
    } catch (e) {
      if (mounted) {
        final appErr = mapException(e);
        showError(
          context,
          title: 'Checkout Failed',
          message: appErr.userMessage,
          onRetry: _payNow,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final addr = ref.watch(selectedAddressProvider);
    final total = cart.valueOrNull?.fold<num>(0, (p, e) => p + (e.price ?? 0) * e.qty) ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout & Confirmation')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // 1. Service Address Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Doorstep Service Address',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.push('/addresses'),
                        child: Text(addr == null ? 'Select' : 'Change', style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (addr != null) ...[
                    Text(addr.line, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${addr.city}, ${addr.state} - ${addr.pincode}', style: const TextStyle(color: AppColors.grey600, fontSize: 13)),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No address selected. Tap Select above to choose delivery location.',
                              style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Payment Method
          const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'online',
                  groupValue: _pay,
                  activeColor: AppColors.primary,
                  title: const Text('Online Payment (UPI / Cards / NetBanking)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Fast & secure doorstep instant payment', style: TextStyle(fontSize: 12, color: AppColors.grey600)),
                  onChanged: (v) => setState(() => _pay = v!),
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  value: 'cash',
                  groupValue: _pay,
                  activeColor: AppColors.primary,
                  title: const Text('Pay After Service (Cash / QR)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Pay technician directly once job is completed', style: TextStyle(fontSize: 12, color: AppColors.grey600)),
                  onChanged: (v) => setState(() => _pay = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Order Summary
          const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          cart.when(
            data: (items) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (final i in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${i.name} (×${i.qty})',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                            Text(
                              inr((i.price ?? 0) * i.qty),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Text('Doorstep Inspection / Delivery', style: TextStyle(color: AppColors.grey600, fontSize: 13)),
                        const Spacer(),
                        Text('FREE', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(child: Text('Grand Total', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                        Text(
                          inr(total),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            error: (e, _) => Text('$e'),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
          boxShadow: const [
            BoxShadow(color: Color(0x0C000000), blurRadius: 16, offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Payable', style: TextStyle(color: AppColors.grey600, fontSize: 11, fontWeight: FontWeight.w600)),
                  Text(
                    inr(total),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: AppButton(
                  label: _pay == 'online' ? 'Pay & Confirm' : 'Confirm Order',
                  loading: _busy,
                  onPressed: _payNow,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

