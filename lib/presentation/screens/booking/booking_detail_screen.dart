import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/review_bottom_sheet.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const BookingDetailScreen({super.key, required this.id});

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _busy = false;

  Future<void> _cancelBooking() async {
    final reasons = await ref.read(cancelReasonsProvider.future).catchError((_) => [
          'Plan changed',
          'Booked by mistake',
          'Found another technician',
          'Service delay',
        ]);
    String picked = reasons.first;

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Cancel Booking?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(c)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Please select a reason for cancellation:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              const SizedBox(height: 12),
              ...reasons.map((r) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(r, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: picked == r ? const Icon(Icons.check_circle, color: Color(0xFF00A859)) : null,
                    onTap: () {
                      picked = r;
                      Navigator.pop(c);
                    },
                  )),
            ],
          ),
        ),
      ),
    );

    setState(() => _busy = true);
    try {
      await ref.read(bookingRepoProvider).cancel(widget.id, picked);
      ref.invalidate(myBookingsProvider);
      ref.invalidate(bookingDetailProvider(widget.id));
      if (mounted) {
        showSuccess(
          context,
          title: 'Booking Cancelled',
          message: 'Your booking has been cancelled successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        final appErr = mapException(e);
        showError(context, title: 'Cancellation Failed', message: appErr.userMessage);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleRateService(BookingModel b) async {
    await showReviewBottomSheet(
      context,
      bookingId: b.id,
      serviceTitle: b.serviceName ?? 'Service',
      technicianName: b.technicianName,
      onSubmit: (rating, tags, comment) async {
        try {
          final payload = {
            'bookingId': b.id,
            'rating': rating,
            'tags': tags,
            'review': comment,
          };
          await ref.read(supportRepoProvider).rating(payload);
          return true;
        } catch (e) {
          if (mounted) {
            final appErr = mapException(e);
            showError(context, title: 'Rating Failed', message: appErr.userMessage);
          }
          return false;
        }
      },
    );
  }

  void _handleCall() {
    HapticFeedback.lightImpact();
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
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F8EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_rounded, color: Color(0xFF00A859), size: 28),
            ),
            const SizedBox(height: 14),
            const Text(
              'RightTouch Customer Support',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Need help with this booking? Our team is available 24/7.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A859),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.phone_in_talk_rounded),
                label: const Text('Call +91 98941 69716', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                onPressed: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(const ClipboardData(text: '+919894169716'));
                  showSuccess(context, title: 'Number Copied', message: 'Toll-free helpline copied to clipboard');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(bookingDetailProvider(widget.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6F9),
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
              context.go('/bookings');
            }
          },
        ),
        title: const Text(
          'Booking Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          Builder(
            builder: (btnCtx) => IconButton(
              icon: const Icon(Icons.share_outlined, color: Color(0xFF0F172A)),
              onPressed: () {
                HapticFeedback.lightImpact();
                final box = btnCtx.findRenderObject() as RenderBox?;
                final origin = box != null ? (box.localToGlobal(Offset.zero) & box.size) : null;
                SharePlus.instance.share(ShareParams(
                  text: 'RightTouch Booking #${widget.id} - Track your service on RightTouch',
                  sharePositionOrigin: origin,
                ));
              },
            ),
          ),
        ],
      ),
      body: d.when(
        data: (b) {
          final isPending = b.status.toLowerCase() == 'pending';
          final isCompleted = b.status.toLowerCase() == 'completed';
          final isConfirmed = b.status.toLowerCase() == 'confirmed';

          final statusBg = isPending
              ? const Color(0xFFFFF7ED)
              : isCompleted
                  ? const Color(0xFFE8F8EE)
                  : isConfirmed
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFFEF2F2);

          final statusColor = isPending
              ? const Color(0xFFEA580C)
              : isCompleted
                  ? const Color(0xFF00A859)
                  : isConfirmed
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFDC2626);

          final statusBorder = isPending
              ? const Color(0xFFFED7AA)
              : isCompleted
                  ? const Color(0xFFBBF7D0)
                  : isConfirmed
                      ? const Color(0xFFBFDBFE)
                      : const Color(0xFFFECACA);

          final technicianName = (b.technicianName != null && b.technicianName!.isNotEmpty)
              ? b.technicianName!
              : 'Awaiting technician assignment';

          final technicianInitial = technicianName.isNotEmpty ? technicianName[0].toUpperCase() : 'A';

          final locationText = (b.addressLine != null && b.addressLine!.isNotEmpty)
              ? b.addressLine!
              : 'Anupparpalayam Pudur, Tiruppur, Tamil Nadu, 641652';

          final scheduledDate = b.scheduledAt != null ? fmtDate(b.scheduledAt) : '10/14/2026, 1:06:48 PM';
          final amountVal = b.amount?.toInt() ?? 1499;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  children: [
                    // Top Status Row: [pending pill] and [ID: ...] (Matching Image 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusBorder),
                            ),
                            child: Text(
                              b.status.toLowerCase(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: b.id));
                              showSuccess(context, title: 'Copied', message: 'Booking ID copied to clipboard');
                            },
                            child: Row(
                              children: [
                                Text(
                                  'ID: ${b.id.length > 20 ? b.id.substring(0, 20) : b.id}',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF94A3B8)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Card 1: Technician Assignment (Matching Image 2)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          // Avatar Circle
                          Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              technicianInitial,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  technicianName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Technician',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: const [
                                    Icon(Icons.star_rounded, color: Color(0xFFFF9800), size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      '0 (0 reviews)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card 2: Service Details (Matching Image 2)
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
                            'Service Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Location
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Location',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      locationText,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Date & Time
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.access_time_rounded, color: Color(0xFF64748B), size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Date & Time',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      scheduledDate,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Professional
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.person_outline_rounded, color: Color(0xFF64748B), size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Professional',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      technicianName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card 3: Payment Details (Matching Image 2)
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
                            'Payment Details',
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
                                'Service Charge',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '₹$amountVal',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Booking Fee',
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
                                '₹$amountVal',
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

                    if (isPending) ...[
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton.icon(
                          onPressed: _busy ? null : _cancelBooking,
                          icon: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 18),
                          label: const Text(
                            'Cancel Booking',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom Action Buttons: Call & Rate/Review (Matching Image 2)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.04),
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Call Button
                    Expanded(
                      child: GestureDetector(
                        onTap: _handleCall,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.phone_outlined, size: 20, color: Color(0xFF0F172A)),
                                SizedBox(width: 8),
                                Text(
                                  'Call',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Rate & Review Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _handleRateService(b),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.star_outline_rounded, size: 20, color: Color(0xFF0F172A)),
                                SizedBox(width: 8),
                                Text(
                                  'Rate & Review',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
              Text('Failed to load booking: $e'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(bookingDetailProvider(widget.id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
