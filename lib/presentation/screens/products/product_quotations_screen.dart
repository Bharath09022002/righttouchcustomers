import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/ui.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/right_touch_header.dart';

class ProductQuotationsScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const ProductQuotationsScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<ProductQuotationsScreen> createState() => _ProductQuotationsScreenState();
}

class _ProductQuotationsScreenState extends ConsumerState<ProductQuotationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Request form state
  final _requirementCtrl = TextEditingController();
  String? _selectedAddressId;
  String _contactMethod = 'phone';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab.clamp(0, 3));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _requirementCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitQuoteRequest() async {
    final text = _requirementCtrl.text.trim();
    if (text.isEmpty) {
      showError(
        context,
        title: 'Requirement Required',
        message: 'Please describe the product or installation you need a quote for.',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final auth = ref.read(authProvider);
      if (auth.isGuest) {
        await Future.delayed(const Duration(milliseconds: 600));
        _requirementCtrl.clear();
        if (mounted) {
          showSuccess(
            context,
            title: 'Quote Requested',
            message: 'Your custom product quotation request has been submitted. Our technical team will prepare a proposal.',
            actionLabel: 'View My Requests',
            onAction: () => _tabController.animateTo(2),
          );
          _tabController.animateTo(2);
        }
        return;
      }

      await ref.read(supportRepoProvider).submitQuoteRequest(
            text,
            addressId: _selectedAddressId,
            contactMethod: _contactMethod,
          );
      ref.invalidate(quoteRequestListProvider);
      _requirementCtrl.clear();
      if (mounted) {
        showSuccess(
          context,
          title: 'Quote Requested',
          message: 'Your custom product quotation request has been submitted. Our technical team will prepare a proposal.',
          actionLabel: 'View My Requests',
          onAction: () => _tabController.animateTo(2),
        );
        _tabController.animateTo(2);
      }
    } catch (e) {
      if (mounted) {
        final appErr = mapException(e);
        showError(
          context,
          title: 'Submission Failed',
          message: appErr.userMessage,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _acceptQuotation(QuotationModel q) async {
    try {
      await ref.read(supportRepoProvider).acceptQuote(q.id);
      ref.invalidate(quotationListProvider);
      ref.invalidate(productBookingsProvider);
      if (mounted) {
        showSuccess(
          context,
          title: 'Quotation Accepted',
          message: 'Quotation accepted! A confirmed product order has been created.',
          actionLabel: 'View Orders',
          onAction: () => _tabController.animateTo(3),
        );
      }
    } catch (e) {
      if (mounted) {
        final appErr = mapException(e);
        showError(
          context,
          title: 'Failed to Accept',
          message: appErr.userMessage,
        );
      }
    }
  }

  Future<void> _declineQuotation(QuotationModel q) async {
    try {
      await ref.read(supportRepoProvider).rejectQuote(q.id);
      ref.invalidate(quotationListProvider);
      if (mounted) {
        showSuccess(
          context,
          title: 'Quotation Declined',
          message: 'You have declined this quotation.',
        );
      }
    } catch (e) {
      if (mounted) {
        final appErr = mapException(e);
        showError(
          context,
          title: 'Failed to Decline',
          message: appErr.userMessage,
        );
      }
    }
  }

  Future<void> _cancelRequest(QuoteRequestModel r) async {
    try {
      await ref.read(supportRepoProvider).cancelQuoteRequest(r.id);
      ref.invalidate(quoteRequestListProvider);
      if (mounted) {
        showSuccess(
          context,
          title: 'Request Cancelled',
          message: 'Your quote request has been cancelled.',
        );
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
    }
  }

  void _showQuotationDetailSheet(QuotationModel q) {
    // Mark quotation viewed via Stage 7 API
    ref.read(supportRepoProvider).viewQuotation(q.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isPending = q.status.toLowerCase() == 'pending';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.request_quote_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q.title ?? 'Custom Equipment Quotation',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Status: ${q.status.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isPending ? const Color(0xFFD97706) : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Quoted Total', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(
                            inr(q.amount),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
                          ),
                        ],
                      ),
                      if (q.createdAt != null) ...[
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Received On', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            Text(fmtDate(q.createdAt), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (isPending) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _acceptQuotation(q);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Accept & Order', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _declineQuotation(q);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: RightTouchTopAppBar(
        title: 'Product',
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: const [
            Tab(text: 'Request Quote'),
            Tab(text: 'Quotations'),
            Tab(text: 'My Requests'),
            Tab(text: 'Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestQuoteTab(),
          _buildQuotationsTab(),
          _buildMyRequestsTab(),
          _buildOrdersTab(),
        ],
      ),
    );
  }

  // --- TAB 1: Request Quote Form ---
  Widget _buildRequestQuoteTab() {
    final addressesAsync = ref.watch(addressListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informational Guarantee Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Row(
              children: const [
                Icon(Icons.verified_outlined, color: AppColors.primary, size: 26),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Custom proposals include genuine hardware specs, on-site survey, manufacturer warranty & subsidy guidance.',
                    style: TextStyle(color: AppColors.primaryDark, fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3-Step Visual Progress Stepper
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStepBadge('1', 'Describe', true),
                const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFFCBD5E1)),
                _buildStepBadge('2', 'Site Location', _selectedAddressId != null),
                const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFFCBD5E1)),
                _buildStepBadge('3', 'Receive Quote', false),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Requirement Description Header + Quick Selection Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Requirement Description *',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
              ),
              Text(
                'Tap to fill ⚡',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildQuickTag('☀️ 5kW Rooftop Solar'),
              _buildQuickTag('📹 4K CCTV Setup'),
              _buildQuickTag('❄️ Central AC Ducting'),
              _buildQuickTag('⚡ Inverter Backup'),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _requirementCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'e.g. 5kW On-Grid Rooftop Solar, 8 Channel 4K CCTV setup with DVR, Commercial AC ducting...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 18),

          // Address Selection
          const Text(
            'Installation / Delivery Address',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          addressesAsync.when(
            data: (addrs) {
              if (addrs.isEmpty) {
                return OutlinedButton.icon(
                  onPressed: () => context.push('/add-address'),
                  icon: const Icon(Icons.add_location_alt_outlined, color: AppColors.primary),
                  label: const Text('Add an address for quotation', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    side: const BorderSide(color: AppColors.primaryBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
              return DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedAddressId ?? addrs.first.id,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                items: addrs.map((a) {
                  return DropdownMenuItem<String>(
                    value: a.id,
                    child: Text(
                      '${a.type} • ${a.line}, ${a.city}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedAddressId = val),
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(8.0), child: RtLoader(size: 24))),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 18),

          // Preferred Contact Method
          const Text(
            'Preferred Contact Method',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final method in ['phone', 'whatsapp', 'email']) ...[
                ChoiceChip(
                  label: Text(method == 'whatsapp' ? 'WhatsApp' : method[0].toUpperCase() + method.substring(1)),
                  selected: _contactMethod == method,
                  selectedColor: AppColors.primarySoft,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: _contactMethod == method ? AppColors.primary : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  labelStyle: TextStyle(
                    color: _contactMethod == method ? AppColors.primaryDark : const Color(0xFF475569),
                    fontWeight: _contactMethod == method ? FontWeight.w800 : FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _contactMethod = method),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 28),

          // Submit Quote Request Button
          AppButton(
            label: 'Request Custom Quotation',
            loading: _submitting,
            fullWidth: true,
            icon: Icons.send_rounded,
            onPressed: _submitQuoteRequest,
          ),
        ],
      ),
    );
  }

  // --- TAB 2: Quotations Review ---
  Widget _buildQuotationsTab() {
    final q = ref.watch(quotationListProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(quotationListProvider),
      child: q.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.request_quote_outlined,
              title: 'No Quotations Yet',
              subtitle: 'Once you submit a quote request, proposals prepared by engineers will appear here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final x = list[i];
              final isPending = x.status.toLowerCase() == 'pending';
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
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
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            x.title ?? 'Custom Equipment Quotation',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPending ? const Color(0xFFFEF3C7) : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            x.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isPending ? const Color(0xFFD97706) : AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quoted Price', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            Text(
                              inr(x.amount),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
                            ),
                          ],
                        ),
                        OutlinedButton(
                          onPressed: () => _showQuotationDetailSheet(x),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('View Proposal', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                      ],
                    ),
                    if (isPending) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _acceptQuotation(x),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: const Text('Accept & Order', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _declineQuotation(x),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F172A),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
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

  // --- TAB 3: My Requests ---
  Widget _buildMyRequestsTab() {
    final reqs = ref.watch(quoteRequestListProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(quoteRequestListProvider),
      child: reqs.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.send_outlined,
              title: 'No Quote Requests',
              subtitle: 'Custom quotation requests you submit will appear here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final r = list[i];
              final isPending = r.status.toLowerCase() == 'pending';
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
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
                    if (isPending) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => _cancelRequest(r),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancel Request', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
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

  // --- TAB 4: Confirmed Orders ---
  Widget _buildOrdersTab() {
    final pb = ref.watch(productBookingsProvider);

    return RefreshIndicator(
      color: AppColors.primary,
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final b = list[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            b.productName ?? 'Custom Equipment Order',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                          ),
                        ),
                        Text(
                          b.status.toUpperCase(),
                          style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w900, fontSize: 11),
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

  Widget _buildStepBadge(String num, String title, bool active) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : const Color(0xFFCBD5E1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              num,
              style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTag(String label) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          final clean = label.replaceAll(RegExp(r'^[^\w]+'), '').trim();
          _requirementCtrl.text = clean;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
        ),
      ),
    );
  }
}

