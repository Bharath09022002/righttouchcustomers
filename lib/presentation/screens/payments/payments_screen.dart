import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/utils/format.dart';
import '../../../core/ui/app_feedback.dart';
import '../../providers/providers.dart';
import '../../widgets/guest_login_placeholder.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth.isGuest) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Payments & Invoices', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ),
        body: const GuestLoginPlaceholder(
          icon: Icons.receipt_long_outlined,
          title: 'Sign In to View Payments',
          subtitle: 'Please log in with your phone number to access payment receipts, invoices, and transaction history.',
          primaryButtonText: 'Log In / Sign Up',
        ),
      );
    }

    final paymentsAsync = ref.watch(paymentListProvider);
    final summaryAsync = ref.watch(paymentSummaryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Payments & Invoices', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF16A34A),
        onRefresh: () async {
          ref.invalidate(paymentListProvider);
          ref.invalidate(paymentSummaryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary Card
            summaryAsync.maybeWhen(
              data: (s) {
                final paid = s.lifetimeSpentRupees;
                final pending = s.amountDueRupees;
                final refunded = s.refundedRupees;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Total Paid', inr(paid), const Color(0xFF16A34A)),
                      Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
                      _buildStatItem('Amount Due', inr(pending), const Color(0xFFD97706)),
                      Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
                      _buildStatItem('Refunds', inr(refunded), const Color(0xFF64748B)),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),

            // RightTouch Rewards Information Banner
            InkWell(
              onTap: () => context.push('/rewards'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF3C7), Color(0xFFFFFBEB)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.stars_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RightTouch Rewards Active',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Earn coins automatically on completed services. 100 Coins = ₹1.00 (1 Coin = 1 Paise). Tap to view wallet.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFFD97706)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              'Transaction History',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),

            // Payments List
            paymentsAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.payments_outlined,
                    title: 'No payments yet',
                    subtitle: 'Service bookings and completed transactions will appear here.',
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final x = list[i];
                    final isPaid = x.isPaid;
                    final isDue = x.isDue;
                    final isCashDue = x.isCashDue;
                    final isProcessing = x.isProcessing;
                    final isUnderReview = x.isUnderReview;
                    final isFailed = x.isFailed;

                    // Display status badge styling
                    Color statusBgColor = const Color(0xFFF1F5F9);
                    Color statusTextColor = const Color(0xFF475569);
                    String statusLabel = x.customerState.replaceAll('_', ' ').toUpperCase();

                    if (isPaid) {
                      statusBgColor = const Color(0xFFDCFCE7);
                      statusTextColor = const Color(0xFF16A34A);
                      statusLabel = 'PAID';
                    } else if (isCashDue) {
                      statusBgColor = const Color(0xFFFEF3C7);
                      statusTextColor = const Color(0xFFD97706);
                      statusLabel = 'CASH DUE';
                    } else if (isProcessing) {
                      statusBgColor = const Color(0xFFE0F2FE);
                      statusTextColor = const Color(0xFF0284C7);
                      statusLabel = 'PROCESSING';
                    } else if (isUnderReview) {
                      statusBgColor = const Color(0xFFF3E8FF);
                      statusTextColor = const Color(0xFF7E22CE);
                      statusLabel = 'UNDER REVIEW';
                    } else if (isFailed) {
                      statusBgColor = const Color(0xFFFEE2E2);
                      statusTextColor = const Color(0xFFDC2626);
                      statusLabel = 'FAILED';
                    } else if (isDue) {
                      statusBgColor = const Color(0xFFFEF3C7);
                      statusTextColor = const Color(0xFFD97706);
                      statusLabel = 'DUE';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isPaid ? const Color(0xFFECFDF5) : (isFailed ? const Color(0xFFFEF2F2) : const Color(0xFFFEF3C7)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPaid
                                  ? Icons.check_circle_outlined
                                  : (isFailed
                                      ? Icons.error_outline_rounded
                                      : (isProcessing ? Icons.sync_rounded : Icons.schedule)),
                              color: isPaid
                                  ? const Color(0xFF16A34A)
                                  : (isFailed ? const Color(0xFFDC2626) : const Color(0xFFD97706)),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inr(x.amount ?? 0),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${x.bookingSummary?['title'] ?? (x.itemType == 'service' ? 'Service Booking' : 'Order')} • #${x.bookingId.length > 8 ? x.bookingId.substring(0, 8) : x.bookingId}',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                ),
                                if (x.paymentDetailsSummary != null && x.paymentDetailsSummary!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      x.paymentDetailsSummary!,
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: statusTextColor,
                                  ),
                                ),
                              ),
                              if (isDue || isFailed) ...[
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    try {
                                      final res = await ref.read(paymentRepoProvider).createOrder(x.bookingId);
                                      if (res.free) {
                                        if (context.mounted) {
                                          showSuccess(
                                            context,
                                            title: 'Booking Free',
                                            message: 'No payment needed — booking marked paid.',
                                          );
                                          ref.invalidate(paymentListProvider);
                                          ref.invalidate(paymentSummaryProvider);
                                        }
                                        return;
                                      }
                                      if (context.mounted) {
                                        showSuccess(
                                          context,
                                          title: 'Payment Order Ready',
                                          message: 'Order ID: ${res.providerOrderId ?? "created"} (₹${res.amountInRupees})',
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        final appErr = mapException(e);
                                        showError(
                                          context,
                                          title: 'Payment Notice',
                                          message: appErr.userMessage,
                                        );
                                      }
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Text(
                                      isFailed ? 'Retry Now' : 'Pay Now',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF16A34A),
                                      ),
                                    ),
                                  ),
                                ),
                              ] else if (isCashDue) ...[
                                const SizedBox(height: 4),
                                const Text(
                                  'Awaiting Tech',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
                                ),
                              ] else if (isUnderReview) ...[
                                const SizedBox(height: 4),
                                const Text(
                                  'Contact Support',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF7E22CE)),
                                ),
                              ] else if (x.receiptAvailable) ...[
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    try {
                                      final rcpt = await ref.read(paymentRepoProvider).receipt(x.bookingId);
                                      if (rcpt != null && context.mounted) {
                                        showSuccess(
                                          context,
                                          title: 'Receipt ${rcpt.receiptNumber}',
                                          message: rcpt.invoiceUrl ?? 'Invoice available for booking',
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        showError(context, title: 'Receipt', message: 'Unable to fetch receipt at this moment.');
                                      }
                                    }
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Text(
                                      'View Receipt',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0284C7),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: RtLoader()),
              error: (e, _) => ErrorView(message: '$e', onRetry: () => ref.invalidate(paymentListProvider)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: valueColor),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}
