import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _busy = false;

  // Schedule mode: 'instant' (Book Now in 30 mins) or 'schedule' (Set Schedule)
  String _scheduleMode = 'instant';

  // Selected Day & Time Slot
  int _selectedDayIndex = 0;
  String _selectedTimeSlot = '09:00 AM';
  String _timePeriodFilter = 'all'; // 'all', 'morning', 'afternoon', 'evening'

  static const List<String> _morningSlots = [
    '09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM',
  ];
  static const List<String> _afternoonSlots = [
    '12:00 PM', '12:30 PM', '01:00 PM', '01:30 PM', '02:00 PM', '02:30 PM', '03:00 PM', '03:30 PM',
  ];
  static const List<String> _eveningSlots = [
    '04:00 PM', '04:30 PM', '05:00 PM', '05:30 PM', '06:00 PM', '06:30 PM', '07:00 PM',
  ];


  List<DateTime> get _availableDays {
    final now = DateTime.now();
    return List.generate(7, (i) => now.add(Duration(days: i + 1)));
  }

  String _formatDayPill(DateTime d) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }

  String _getDayOfWeek(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    if (d.year == tomorrow.year && d.month == tomorrow.month && d.day == tomorrow.day) {
      return 'Tomorrow';
    }
    return days[d.weekday - 1];
  }

  String _getMonthName(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[d.month - 1];
  }

  Future<void> _handleBookNow() async {
    final auth = ref.read(authProvider);

    setState(() => _busy = true);
    HapticFeedback.mediumImpact();

    try {
      if (auth.isGuest) {
        // Guest mode simulated checkout
        await Future.delayed(const Duration(milliseconds: 700));
        ref.invalidate(cartProvider);
        ref.invalidate(myBookingsProvider);
        if (mounted) context.push('/booking-success');
        return;
      }

      // Authenticated customer checkout
      final addr = ref.read(selectedAddressProvider);
      final lat = addr?.lat ?? 12.9716;
      final lng = addr?.lng ?? 77.5946;
      final addressLine = addr != null
          ? '${addr.line}, ${addr.city}, ${addr.state} ${addr.pincode}'
          : 'Customer Default Address';

      final scheduledTime = _scheduleMode == 'instant'
          ? 'In 30 mins'
          : '${_formatDayPill(_availableDays[_selectedDayIndex])}, $_selectedTimeSlot';

      await ref.read(cartRepoProvider).checkout({
        'locationType': 'gps',
        'latitude': lat,
        'longitude': lng,
        'addressLine': addressLine,
        if (addr?.id != null) 'addressId': addr!.id,
        'paymentMethod': 'online',
        'bookingType': _scheduleMode,
        'scheduledSlot': scheduledTime,
      });

      ref.invalidate(cartProvider);
      ref.invalidate(myBookingsProvider);
      if (mounted) context.push('/booking-success');
    } catch (e) {
      if (mounted) {
        final appErr = mapException(e);
        showError(
          context,
          title: 'Booking Notice',
          message: appErr.userMessage,
          actionLabel: 'Try Again',
          onAction: _handleBookNow,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showPaymentMethodSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Select Payment Method',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8EE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF00A859)),
              ),
              title: const Text('UPI (GPay / PhonePe / Paytm)', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Instant & seamless doorstep payment', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF00A859)),
              onTap: () => Navigator.pop(ctx),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.credit_card_rounded, color: Color(0xFF475569)),
              ),
              title: const Text('Credit / Debit Cards', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Visa, Mastercard, RuPay', style: TextStyle(fontSize: 12)),
              onTap: () => Navigator.pop(ctx),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF475569)),
              ),
              title: const Text('Pay After Service (Cash / QR)', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Pay technician directly once job is done', style: TextStyle(fontSize: 12)),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final selectedTip = ref.watch(selectedCartTipProvider);
    final addr = ref.watch(selectedAddressProvider);
    final days = _availableDays;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/cart');
            }
          },
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: cart.when(
        data: (items) {
          final itemTotal = items.fold<num>(0, (sum, it) => sum + (it.price ?? 0) * it.qty);
          final grandTotal = itemTotal + selectedTip;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    // Heading: Order Summary
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),

                    // Card 1: Delivery Address (Matching Image 1)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Delivery Address',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              if (addr != null && addr.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F8EE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Default',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF00A859),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (addr == null) ...[
                            // Outline green button: [ 📍+ Add Delivery Address ]
                            InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.push('/addresses');
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF00A859),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.add_location_alt_outlined,
                                      color: Color(0xFF00A859),
                                      size: 22,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Add Delivery Address',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF00A859),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F8EE),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFF00A859),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        addr.type,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.5,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${addr.line}, ${addr.city}, ${addr.state} - ${addr.pincode}',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF64748B),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.push('/addresses'),
                                  child: const Text(
                                    'Change',
                                    style: TextStyle(
                                      color: Color(0xFF00A859),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.help_outline_rounded,
                                    size: 16,
                                    color: Color(0xFF00A859),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Are you ok with the default address or do you need to change the address?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF475569),
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => context.push('/addresses'),
                                    borderRadius: BorderRadius.circular(4),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      child: Text(
                                        'Change',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF00A859),
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card 2: When do you need this? (Matching Image 1 & Image 4)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'When do you need this?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Side-by-side selectable cards: Book Now vs Set Schedule
                          Row(
                            children: [
                              // ⚡ Book Now
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() => _scheduleMode = 'instant');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _scheduleMode == 'instant'
                                          ? const Color(0xFFE8F8EE)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _scheduleMode == 'instant'
                                            ? const Color(0xFF00A859)
                                            : const Color(0xFFE2E8F0),
                                        width: _scheduleMode == 'instant' ? 1.6 : 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.bolt_rounded,
                                          color: _scheduleMode == 'instant'
                                              ? const Color(0xFF00A859)
                                              : const Color(0xFF64748B),
                                          size: 24,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Book Now',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: _scheduleMode == 'instant'
                                                ? const Color(0xFF00A859)
                                                : const Color(0xFF475569),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'In 30 mins',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: _scheduleMode == 'instant'
                                                ? const Color(0xFF00A859).withValues(alpha: 0.8)
                                                : const Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 📅 Set Schedule
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() => _scheduleMode = 'schedule');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _scheduleMode == 'schedule'
                                          ? const Color(0xFFE8F8EE)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _scheduleMode == 'schedule'
                                            ? const Color(0xFF00A859)
                                            : const Color(0xFFE2E8F0),
                                        width: _scheduleMode == 'schedule' ? 1.6 : 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.calendar_month_outlined,
                                          color: _scheduleMode == 'schedule'
                                              ? const Color(0xFF00A859)
                                              : const Color(0xFF64748B),
                                          size: 24,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Set Schedule',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: _scheduleMode == 'schedule'
                                                ? const Color(0xFF00A859)
                                                : const Color(0xFF475569),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Choose date & time',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: _scheduleMode == 'schedule'
                                                ? const Color(0xFF00A859).withValues(alpha: 0.8)
                                                : const Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // If "Set Schedule" is picked, show day selector and time slot grid
                          if (_scheduleMode == 'schedule') ...[
                            _buildSchedulePicker(days),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card 3: Items in cart
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Items in cart',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '${items.length} items',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...items.map((it) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Thumbnail
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: AppImage(
                                      url: it.image,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Title + Qty + Service Badge
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          it.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              'Qty: ${it.qty}',
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8F8EE),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                it.itemType.toUpperCase() == 'PRODUCT' ? 'Product' : 'Service',
                                                style: const TextStyle(
                                                  color: Color(0xFF00A859),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Price
                                  Text(
                                    '₹${((it.price ?? 0) * it.qty).toInt()}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card 4: Payment Breakdown
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Breakdown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Item Total',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '₹${itemTotal.toInt()}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Taxes & Service Fee',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '₹0',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          if (selectedTip > 0) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tip for professional',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '₹$selectedTip',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF00A859),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '₹${grandTotal.toInt()}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card 5: Payment Method
                    GestureDetector(
                      onTap: _showPaymentMethodSheet,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F8EE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.credit_card_rounded,
                                color: Color(0xFF00A859),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Payment Method',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'UPI, Card or Net Banking — chosen securely at payment',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF94A3B8),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Disclaimer matching Image 1
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'By placing this order, you agree to our terms and conditions.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom Sticky Bar matching Image 1 & 4
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.05),
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Amount to Pay',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '₹${grandTotal.toInt()}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _busy ? null : _handleBookNow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A859),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.lock_rounded, size: 16, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'Book Now',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load checkout: $e'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(cartProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Modern, user-friendly schedule picker:
  /// - Calendar Date Carousel with Day name, bold date number & month
  /// - Time-of-day tabs: All, Morning, Afternoon, Evening
  /// - High-contrast 3-column rounded pill slot grid
  /// - Reassuring confirmation status badge
  Widget _buildSchedulePicker(List<DateTime> days) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // 1. SELECT A DAY HEADER
        Row(
          children: const [
            Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Text(
              'Select a day',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // CALENDAR DATE CARD CAROUSEL
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: days.length,
            itemBuilder: (context, i) {
              final d = days[i];
              final isDaySelected = _selectedDayIndex == i;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedDayIndex = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  margin: const EdgeInsets.only(right: 10, bottom: 4),
                  decoration: BoxDecoration(
                    color: isDaySelected ? const Color(0xFF16A34A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDaySelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                      width: isDaySelected ? 1.8 : 1.2,
                    ),
                    boxShadow: isDaySelected
                        ? const [
                            BoxShadow(
                              color: Color(0x3816A34A),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ]
                        : const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDayOfWeek(d),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDaySelected ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDaySelected ? Colors.white : const Color(0xFF0F172A),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _getMonthName(d),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDaySelected ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 22),

        // 2. SELECT TIME SLOT HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.schedule_rounded, size: 17, color: Color(0xFF16A34A)),
                SizedBox(width: 8),
                Text(
                  'Select time slot',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$_selectedTimeSlot selected',
                style: const TextStyle(
                  color: Color(0xFF16A34A),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // TIME PERIOD FILTER CHIPS (All, Morning, Afternoon, Evening)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildTimePeriodFilterChip('all', 'All slots (21)'),
              _buildTimePeriodFilterChip('morning', '🌅 Morning (6)'),
              _buildTimePeriodFilterChip('afternoon', '☀️ Afternoon (8)'),
              _buildTimePeriodFilterChip('evening', '🌆 Evening (7)'),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // TIME SLOTS LIST / GRID
        if (_timePeriodFilter == 'all') ...[
          _buildPeriodSection('🌅 Morning', '09:00 AM – 12:00 PM', _morningSlots),
          const SizedBox(height: 14),
          _buildPeriodSection('☀️ Afternoon', '12:00 PM – 04:00 PM', _afternoonSlots),
          const SizedBox(height: 14),
          _buildPeriodSection('🌆 Evening', '04:00 PM – 07:00 PM', _eveningSlots),
        ] else if (_timePeriodFilter == 'morning') ...[
          _buildSlotGrid(_morningSlots),
        ] else if (_timePeriodFilter == 'afternoon') ...[
          _buildSlotGrid(_afternoonSlots),
        ] else if (_timePeriodFilter == 'evening') ...[
          _buildSlotGrid(_eveningSlots),
        ],

        // CONFIRMATION REASSURANCE BADGE
        Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_available_rounded, color: Color(0xFF16A34A), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scheduled: ${_getDayOfWeek(days[_selectedDayIndex])}, ${_formatDayPill(days[_selectedDayIndex])} at $_selectedTimeSlot',
                      style: const TextStyle(
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Technician will arrive promptly at your address.',
                      style: TextStyle(
                        color: Color(0xFF166534),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimePeriodFilterChip(String key, String label) {
    final isSelected = _timePeriodFilter == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _timePeriodFilter = key);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSection(String title, String timing, List<String> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
              ),
            ),
            Text(
              timing,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSlotGrid(slots),
      ],
    );
  }

  Widget _buildSlotGrid(List<String> slots) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 16) / 3;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSlotSelected = _selectedTimeSlot == slot;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedTimeSlot = slot);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: itemWidth,
                height: 42,
                decoration: BoxDecoration(
                  color: isSlotSelected ? const Color(0xFF16A34A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSlotSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                    width: isSlotSelected ? 1.6 : 1.1,
                  ),
                  boxShadow: isSlotSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x3316A34A),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : const [
                          BoxShadow(
                            color: Color(0x04000000),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSlotSelected) ...[
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      slot,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSlotSelected ? FontWeight.w800 : FontWeight.w700,
                        color: isSlotSelected ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
