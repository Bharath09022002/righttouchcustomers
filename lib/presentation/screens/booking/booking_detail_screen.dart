import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/utils/format.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/providers.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const BookingDetailScreen({super.key, required this.id});
  @override
  ConsumerState<BookingDetailScreen> createState() => _S();
}

class _S extends ConsumerState<BookingDetailScreen> {
  bool _busy = false;

  Future<void> _cancel() async {
    final reasons = await ref.read(cancelReasonsProvider.future).catchError((_) => ['Plan changed']);
    String? picked = reasons.first;
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Cancel booking?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            for (final r in reasons)
              RadioListTile<String>(value: r, groupValue: picked, title: Text(r), onChanged: (v) { picked = v; Navigator.pop(c); }),
          ]),
        ),
      ),
    );
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(bookingRepoProvider).cancel(widget.id, picked);
      ref.invalidate(myBookingsProvider);
      if (mounted) {
        showSuccess(
          context,
          title: 'Booking Cancelled',
          message: 'Your booking has been cancelled.',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final appErr = mapException(e);
        showError(
          context,
          title: 'Cancellation Failed',
          message: appErr.userMessage,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _bookAgain(String bookingId) async {
    setState(() => _busy = true);
    try {
      await ref.read(bookingRepoProvider).bookAgain(bookingId);
      ref.invalidate(myBookingsProvider);
      if (mounted) {
        showSuccess(
          context,
          title: 'Booking Confirmed',
          message: 'Your service has been re-booked successfully!',
          actionLabel: 'View Bookings',
          onAction: () => context.go('/bookings'),
        );
      }
    } catch (e) {
      if (mounted) {
        final appErr = mapException(e);
        showError(
          context,
          title: 'Could Not Re-book',
          message: appErr.userMessage,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rate() async {
    int stars = 5;
    final c = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Rate this service', style: TextStyle(fontWeight: FontWeight.w800)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (int i = 1; i <= 5; i++)
              IconButton(onPressed: () => setState(() => stars = i), icon: Icon(Icons.star, color: i <= stars ? AppColors.star : AppColors.grey200)),
          ]),
          TextField(controller: c, decoration: const InputDecoration(hintText: 'Write a review (optional)')),
          const SizedBox(height: 12),
          AppButton(label: 'Submit rating', onPressed: () async {
            try {
              await ref.read(supportRepoProvider).rating({'bookingId': widget.id, 'rating': stars, 'review': c.text});
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                showSuccess(
                  context,
                  title: 'Rating Submitted',
                  message: 'Thank you for your rating and feedback!',
                );
              }
            } catch (e) {
              if (ctx.mounted) {
                final appErr = mapException(e);
                showError(
                  ctx,
                  title: 'Rating Failed',
                  message: appErr.userMessage,
                );
              }
            }
          }),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(bookingDetailProvider(widget.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Booking details')),
      body: d.when(
        data: (b) => ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.serviceName ?? 'Service', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                const SizedBox(height: 4),
                Text('Status: ${b.status.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(fmtDate(b.scheduledAt), style: const TextStyle(color: AppColors.grey600)),
                if ((b.addressLine ?? '').isNotEmpty) Text(b.addressLine!, style: const TextStyle(color: AppColors.grey600)),
                const Divider(),
                Row(children: [const Text('Amount'), const Spacer(), Text(inr(b.amount), style: const TextStyle(fontWeight: FontWeight.w900))]),
                Row(children: [const Text('Payment'), const Spacer(), Text(b.paymentStatus ?? '--')]),
                if ((b.technicianName ?? '').isNotEmpty) Row(children: [const Text('Technician'), const Spacer(), Text(b.technicianName!)]),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          if (b.status.toLowerCase() == 'completed' || b.status.toLowerCase() == 'cancelled') ...[
            AppButton(
              label: 'Book again',
              fullWidth: true,
              loading: _busy,
              icon: Icons.repeat,
              onPressed: () => _bookAgain(b.id),
            ),
            const SizedBox(height: 8),
          ],
          AppButton(label: 'Rate service', outlined: true, fullWidth: true, icon: Icons.star_outline, onPressed: _rate),
          const SizedBox(height: 8),
          AppButton(label: 'Cancel booking', outlined: true, fullWidth: true, loading: _busy, onPressed: _cancel),
        ]),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: '$e', onRetry: () => ref.invalidate(bookingDetailProvider(widget.id))),
      ),
    );
  }
}
