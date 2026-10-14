import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/utils/format.dart';
import '../../../core/ui/app_feedback.dart';
import '../../providers/providers.dart';

class QuotationsScreen extends ConsumerStatefulWidget {
  const QuotationsScreen({super.key});

  @override
  ConsumerState<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends ConsumerState<QuotationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Quotations & Custom Orders',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF16A34A),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF16A34A),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: const [
            Tab(text: 'Quotations'),
            Tab(text: 'My Requests'),
            Tab(text: 'Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuotationsTab(),
          _buildRequestsTab(),
          _buildProductBookingsTab(),
        ],
      ),
    );
  }

  Widget _buildQuotationsTab() {
    final q = ref.watch(quotationListProvider);
    return RefreshIndicator(
      color: const Color(0xFF16A34A),
      onRefresh: () async => ref.invalidate(quotationListProvider),
      child: q.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.request_quote_outlined,
              title: 'No quotations yet',
              subtitle: 'Request a custom quote for solar installation or CCTV setup to receive competitive pricing from our team.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final x = list[i];
              final isPending = x.status.toLowerCase() == 'pending';
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.description_outlined, color: Color(0xFF16A34A), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            x.title ?? 'Custom Installation Quotation',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPending ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            x.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isPending ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      inr(x.amount),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                    ),
                    if (isPending) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  await ref.read(supportRepoProvider).acceptQuote(x.id);
                                  ref.invalidate(quotationListProvider);
                                  ref.invalidate(productBookingsProvider);
                                  if (mounted) {
                                    showSuccess(
                                      context,
                                      title: 'Quotation Accepted',
                                      message: 'Quotation accepted! Product booking created.',
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    final appErr = mapException(e);
                                    showError(
                                      context,
                                      title: 'Failed to Accept Quote',
                                      message: appErr.userMessage,
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Accept Quote', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                try {
                                  await ref.read(supportRepoProvider).rejectQuote(x.id);
                                  ref.invalidate(quotationListProvider);
                                  if (mounted) {
                                    showSuccess(
                                      context,
                                      title: 'Quotation Declined',
                                      message: 'Quotation declined.',
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    final appErr = mapException(e);
                                    showError(
                                      context,
                                      title: 'Failed to Decline Quote',
                                      message: appErr.userMessage,
                                    );
                                  }
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                                side: const BorderSide(color: Color(0xFFFCA5A5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: RtLoader()),
        error: (e, _) => ErrorView(message: '$e', onRetry: () => ref.invalidate(quotationListProvider)),
      ),
    );
  }

  Widget _buildRequestsTab() {
    final reqs = ref.watch(quoteRequestListProvider);
    return RefreshIndicator(
      color: const Color(0xFF16A34A),
      onRefresh: () async => ref.invalidate(quoteRequestListProvider),
      child: reqs.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.send_outlined,
              title: 'No Quote Requests',
              subtitle: 'Custom quotation requests submitted from product catalog will appear here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final r = list[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.requirement,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            r.status.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                    if (r.preferredContactMethod != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Contact via: ${r.preferredContactMethod}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton(
                        onPressed: () async {
                          try {
                            await ref.read(supportRepoProvider).cancelQuoteRequest(r.id);
                            ref.invalidate(quoteRequestListProvider);
                            if (mounted) {
                              showSuccess(
                                context,
                                title: 'Request Cancelled',
                                message: 'Quote request cancelled.',
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              final appErr = mapException(e);
                              showError(
                                context,
                                title: 'Failed to Cancel Request',
                                message: appErr.userMessage,
                              );
                            }
                          }
                        },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel Request', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: RtLoader()),
        error: (e, _) => ErrorView(message: '$e', onRetry: () => ref.invalidate(quoteRequestListProvider)),
      ),
    );
  }

  Widget _buildProductBookingsTab() {
    final pb = ref.watch(productBookingsProvider);
    return RefreshIndicator(
      color: const Color(0xFF16A34A),
      onRefresh: () async => ref.invalidate(productBookingsProvider),
      child: pb.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No Product Orders',
              subtitle: 'When you accept custom quotations, confirmed equipment bookings appear here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final b = list[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            b.productName ?? 'Custom Equipment Order',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                        Text(
                          b.status.toUpperCase(),
                          style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w900, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (b.amount != null)
                      Text(
                        inr(b.amount),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: RtLoader()),
        error: (e, _) => ErrorView(message: '$e', onRetry: () => ref.invalidate(productBookingsProvider)),
      ),
    );
  }
}
