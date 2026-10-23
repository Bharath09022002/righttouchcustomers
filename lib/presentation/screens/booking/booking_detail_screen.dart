import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/env.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../../core/services/razorpay_service.dart';
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

  Future<void> _deleteBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Booking?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: const Text(
          'This will permanently remove this cancelled booking from your account history.',
          style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _busy = true);
      try {
        await ref.read(bookingRepoProvider).delete(widget.id);
        ref.invalidate(myBookingsProvider);
        if (mounted) {
          showSuccess(
            context,
            title: 'Booking Deleted',
            message: 'Booking history record removed.',
          );
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/bookings');
          }
        }
      } catch (e) {
        if (mounted) {
          showError(context, title: 'Delete Failed', message: mapException(e).userMessage);
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  Future<void> _handleRateService(BookingModel b) async {
    // 1. Completion Gate
    if (b.status.toLowerCase() != 'completed') {
      showError(
        context,
        title: 'Rating Unavailable',
        message: 'You can rate a service only after completion.',
      );
      return;
    }

    // 2. Check if already rated in customer history
    final myRatings = ref.read(myRatingsProvider).valueOrNull ?? [];
    final existingRating = myRatings.where((r) => r.bookingId == b.id).firstOrNull;

    await showReviewBottomSheet(
      context,
      bookingId: b.id,
      serviceTitle: b.serviceName ?? 'Service',
      technicianName: b.technicianName,
      bookingType: 'service',
      isEditing: existingRating != null,
      initialRating: existingRating?.rates ?? 5,
      initialComment: existingRating?.comment ?? '',
      onSubmit: (rates, comment) async {
        try {
          if (existingRating != null) {
            await ref.read(ratingRepoProvider).updateRating(
              id: existingRating.id,
              rates: rates,
              comment: comment,
            );
          } else {
            await ref.read(ratingRepoProvider).submitRating(
              bookingId: b.id,
              bookingType: 'service',
              rates: rates,
              comment: comment,
            );
          }
          ref.invalidate(myRatingsProvider);
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

  Future<void> _handlePayOnline(BookingModel b) async {
    if (b.status.toLowerCase() != 'completed') {
      showError(context, title: 'Payment Unavailable', message: 'Payment allowed only after service completion');
      return;
    }
    final amountVal = b.amount?.toDouble() ?? 0.0;
    if (amountVal < 1.0) {
      showError(context, title: 'Invalid Amount', message: 'Minimum payment amount is ₹1');
      return;
    }
    if ((b.paymentStatus ?? '').toLowerCase() == 'paid') {
      showError(context, title: 'Already Paid', message: 'Booking already paid');
      return;
    }

    setState(() => _busy = true);
    try {
      final repo = ref.read(paymentRepoProvider);
      final res = await repo.createOrder(b.id);
      if (res.free) {
        if (mounted) {
          showSuccess(
            context,
            title: 'Booking Free',
            message: 'No payment needed — booking marked paid.',
          );
        }
        ref.invalidate(bookingDetailProvider(widget.id));
        ref.invalidate(paymentListProvider);
        return;
      }

      // Open Razorpay Native Checkout
      RazorpayService.instance.initialize(repo);
      final user = ref.read(authProvider).user;
      if (mounted) {
        await RazorpayService.instance.openCheckout(
          context: context,
          bookingId: b.id,
          order: res,
          userPhone: user?.mobile,
          userEmail: user?.email,
          onComplete: (success, message) {
            ref.invalidate(bookingDetailProvider(widget.id));
            ref.invalidate(paymentListProvider);
            ref.invalidate(paymentSummaryProvider);
            if (mounted) {
              if (success) {
                showSuccess(context, title: 'Payment Successful', message: message);
              } else {
                showError(context, title: 'Payment Notice', message: message);
              }
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        final appErr = mapException(e);
        showError(context, title: 'Payment Failed', message: appErr.userMessage);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleDeclareCash(BookingModel b) async {
    if (b.status.toLowerCase() != 'completed') {
      showError(context, title: 'Cash Payment Unavailable', message: 'Payment allowed only after service completion');
      return;
    }
    if ((b.paymentStatus ?? '').toLowerCase() == 'paid') {
      showError(context, title: 'Already Paid', message: 'Booking already paid');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pay Cash to Technician?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Text(
          'Please confirm that you are handing ₹${b.amount?.toInt() ?? 0} in cash directly to ${b.technicianName ?? 'the service technician'}.',
          style: const TextStyle(fontSize: 14, color: AppColors.grey700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.grey600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Cash Payment'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(paymentRepoProvider).declareCash(b.id);
      if (mounted) {
        showSuccess(
          context,
          title: 'Cash Payment Recorded',
          message: 'Cash payment submitted for technician confirmation.',
        );
      }
      ref.invalidate(bookingDetailProvider(widget.id));
      ref.invalidate(paymentListProvider);
    } catch (e) {
      if (mounted) {
        final appErr = mapException(e);
        showError(context, title: 'Cash Declaration Failed', message: appErr.userMessage);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
                label: Text('Call ${Env.supportPhone}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final cleanPhone = Env.supportPhone.replaceAll(' ', '');
                  final uri = Uri.parse('tel:$cleanPhone');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    Clipboard.setData(ClipboardData(text: cleanPhone));
                    if (mounted) {
                      showSuccess(context, title: 'Number Copied', message: 'Support helpline copied to clipboard');
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.email_outlined),
                label: Text('Email ${Env.supportEmail}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse('mailto:${Env.supportEmail}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    Clipboard.setData(const ClipboardData(text: Env.supportEmail));
                    if (mounted) {
                      showSuccess(context, title: 'Email Copied', message: 'Support email copied to clipboard');
                    }
                  }
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
              : 'Address provided during booking';

          final scheduledDate = b.scheduledAt != null ? fmtDate(b.scheduledAt) : 'Slot will be confirmed';
          final amountVal = b.amount?.toInt() ?? 0;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  children: [
                    // Top Status Row: [Pending pill]
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
                              b.status.isNotEmpty
                                  ? (b.status[0].toUpperCase() + b.status.substring(1).toLowerCase())
                                  : 'Pending',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
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

                          // Payment Status Badge & Due Actions
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: (b.paymentStatus ?? '').toLowerCase() == 'paid'
                                  ? const Color(0xFFECFDF5)
                                  : ((b.paymentStatus ?? '').toLowerCase() == 'under_review'
                                      ? const Color(0xFFFFFBEB)
                                      : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: (b.paymentStatus ?? '').toLowerCase() == 'paid'
                                    ? const Color(0xFFBBF7D0)
                                    : ((b.paymentStatus ?? '').toLowerCase() == 'under_review'
                                        ? const Color(0xFFFDE68A)
                                        : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  (b.paymentStatus ?? '').toLowerCase() == 'paid'
                                      ? Icons.check_circle_rounded
                                      : ((b.paymentStatus ?? '').toLowerCase() == 'under_review'
                                          ? Icons.hourglass_top_rounded
                                          : Icons.payment_rounded),
                                  size: 18,
                                  color: (b.paymentStatus ?? '').toLowerCase() == 'paid'
                                      ? const Color(0xFF16A34A)
                                      : ((b.paymentStatus ?? '').toLowerCase() == 'under_review'
                                          ? const Color(0xFFD97706)
                                          : const Color(0xFF64748B)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    (b.paymentStatus ?? '').toLowerCase() == 'paid'
                                        ? 'Payment Completed (Paid)'
                                        : ((b.paymentStatus ?? '').toLowerCase() == 'under_review'
                                            ? 'Payment Under Review'
                                            : 'Payment Status: ${(b.paymentStatus ?? '').isNotEmpty ? b.paymentStatus!.toUpperCase() : "PENDING"}'),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: (b.paymentStatus ?? '').toLowerCase() == 'paid'
                                          ? const Color(0xFF16A34A)
                                          : ((b.paymentStatus ?? '').toLowerCase() == 'under_review'
                                              ? const Color(0xFFB45309)
                                              : const Color(0xFF334155)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // If completed and unpaid: provide Pay Online & Pay Cash buttons
                          if (b.status.toLowerCase() == 'completed' && (b.paymentStatus ?? '').toLowerCase() != 'paid') ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF16A34A),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 11),
                                    ),
                                    icon: const Icon(Icons.credit_card, size: 16),
                                    label: const Text('Pay Online', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                    onPressed: _busy ? null : () => _handlePayOnline(b),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF0F172A),
                                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 11),
                                    ),
                                    icon: const Icon(Icons.payments_outlined, size: 16),
                                    label: const Text('Pay Cash', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                    onPressed: _busy ? null : () => _handleDeclareCash(b),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // RightTouch Rewards Banner (Completed + Paid, 100 Coins = ₹1.00)
                          if (b.status.toLowerCase() == 'completed' && (b.paymentStatus ?? '').toLowerCase() == 'paid') ...[
                            InkWell(
                              onTap: () => context.push('/rewards'),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                margin: const EdgeInsets.only(top: 14),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFEF3C7), Color(0xFFFFFBEB)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF59E0B),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.stars_rounded, color: Colors.white, size: 22),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '+${(amountVal * 1.5).round()} RightTouch Coins Earned!',
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF92400E)),
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            '100 Coins = ₹1.00 • Tap to view customer rewards',
                                            style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: Color(0xFFD97706), size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Completion Status Card
                    Consumer(
                      builder: (context, ref, _) {
                        final statusAsync = ref.watch(bookingCompletionStatusProvider(widget.id));
                        return statusAsync.maybeWhen(
                          data: (data) {
                            if (data.isEmpty) return const SizedBox.shrink();
                            final isVerified = data['verified'] == true ||
                                data['isCompleted'] == true ||
                                data['completed'] == true;
                            final completionTime = data['completedAt'] ?? data['time'];
                            final notes = data['notes'] ?? data['message'];
                            return Container(
                              margin: const EdgeInsets.only(top: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: isVerified
                                        ? const Color(0xFFBBF7D0)
                                        : const Color(0xFFE2E8F0)),
                              ),
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isVerified
                                            ? Icons.verified_rounded
                                            : Icons.pending_actions_rounded,
                                        color: isVerified
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFFD97706),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Service Verification Status',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: isVerified
                                              ? const Color(0xFF16A34A)
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isVerified
                                              ? const Color(0xFFDCFCE7)
                                              : const Color(0xFFFEF3C7),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isVerified ? 'VERIFIED' : 'PENDING',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: isVerified
                                                ? const Color(0xFF15803D)
                                                : const Color(0xFFB45309),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (completionTime != null) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      'Verified on: ${fmtDate(completionTime)}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                  if (notes != null &&
                                      notes.toString().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      notes.toString(),
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF334155)),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                          orElse: () => const SizedBox.shrink(),
                        );
                      },
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
                    ] else if (b.status.toLowerCase() == 'cancelled') ...[
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton.icon(
                          onPressed: _busy ? null : _deleteBooking,
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                          label: const Text(
                            'Delete Booking Record',
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
                    // Rate & Review Button (with completion and already-rated state)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final myRatings = ref.watch(myRatingsProvider).valueOrNull ?? [];
                          final hasRated = myRatings.any((r) => r.bookingId == b.id);
                          final isCompleted = b.status.toLowerCase() == 'completed';

                          return GestureDetector(
                            onTap: () => _handleRateService(b),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? (hasRated ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC))
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCompleted
                                      ? (hasRated ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0))
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      hasRated ? Icons.star_rounded : Icons.star_outline_rounded,
                                      size: 20,
                                      color: hasRated
                                          ? const Color(0xFFF59E0B)
                                          : (isCompleted ? const Color(0xFF0F172A) : const Color(0xFF94A3B8)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      hasRated
                                          ? 'Edit Review'
                                          : (isCompleted ? 'Rate & Review' : 'Rate (Completed)'),
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: isCompleted ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
