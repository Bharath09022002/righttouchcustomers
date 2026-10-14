import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/utils/format.dart';
import '../../../core/ui/app_feedback.dart';
import '../../providers/providers.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                final paid = s['totalPaid'] ?? s['paid'] ?? 0;
                final pending = s['pending'] ?? 0;
                final refunded = s['refunded'] ?? 0;
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
                      _buildStatItem('Pending', inr(pending), const Color(0xFFD97706)),
                      Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
                      _buildStatItem('Refunds', inr(refunded), const Color(0xFF64748B)),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
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
                    final isPaid = x.status.toLowerCase() == 'completed' || x.status.toLowerCase() == 'paid';
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
                              color: isPaid ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPaid ? Icons.check_circle_outlined : Icons.schedule,
                              color: isPaid ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inr(x.amount),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${x.method ?? 'Online (Razorpay)'} • Booking ID: ${x.bookingId.length > 8 ? x.bookingId.substring(0, 8) : x.bookingId}',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
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
                                  color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  x.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: isPaid ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                  ),
                                ),
                              ),
                              if (!isPaid) ...[
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    try {
                                      await ref.read(paymentRepoProvider).retryPayment(x.bookingId);
                                      if (context.mounted) {
                                        showSuccess(
                                          context,
                                          title: 'Payment Retry Initiated',
                                          message: 'Payment retry has been initiated.',
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        final appErr = mapException(e);
                                        showError(
                                          context,
                                          title: 'Payment Retry Failed',
                                          message: appErr.userMessage,
                                        );
                                      }
                                    }
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Text(
                                      'Retry Now',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF16A34A),
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
