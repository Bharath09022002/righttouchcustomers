import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/ui.dart';
import '../../../data/models/models.dart';
import '../../../core/services/razorpay_service.dart';
import '../../providers/providers.dart';
import '../../widgets/right_touch_header.dart';
import '../../widgets/review_bottom_sheet.dart';

class ProductQuotationsScreen extends ConsumerStatefulWidget {
  final int initialTab;
  final String? preselectedProductId;
  const ProductQuotationsScreen({super.key, this.initialTab = 0, this.preselectedProductId});

  @override
  ConsumerState<ProductQuotationsScreen> createState() => _ProductQuotationsScreenState();
}

class _ProductQuotationsScreenState extends ConsumerState<ProductQuotationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Request form state
  final _requirementCtrl = TextEditingController();
  String? _selectedProductId;
  String? _selectedAddressId;
  String _contactMethod = 'whatsapp';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab.clamp(0, 3));
    _selectedProductId = widget.preselectedProductId;
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
      if (auth.isGuest || !auth.loggedIn) {
        setState(() => _submitting = false);
        if (mounted) {
          showError(
            context,
            title: 'Sign In Required',
            message: 'Please sign in to submit a product quote request and track proposals.',
            actionLabel: 'Sign In',
            onAction: () => context.push('/login'),
          );
        }
        return;
      }

      String? addressId = _selectedAddressId;
      if (addressId == null || addressId.isEmpty) {
        final addrs = ref.read(addressListProvider).valueOrNull ?? [];
        if (addrs.isNotEmpty) {
          addressId = addrs.firstWhere((a) => a.isDefault, orElse: () => addrs.first).id;
        }
      }
      if (addressId == null || addressId.isEmpty) {
        final defAddr = await ref.read(addressRepoProvider).getDefault();
        addressId = defAddr?.id;
      }

      await ref.read(supportRepoProvider).submitQuoteRequest(
            text,
            productId: _selectedProductId,
            addressId: addressId,
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

  Future<void> _rateProduct(ProductBookingModel b) async {
    final myRatings = ref.read(myRatingsProvider).valueOrNull ?? [];
    final existingRating = myRatings.where((r) => r.bookingId == b.id).firstOrNull;

    await showReviewBottomSheet(
      context,
      bookingId: b.id,
      serviceTitle: b.productName ?? 'Custom Equipment',
      bookingType: 'product',
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
              bookingType: 'product',
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

  Future<void> _acceptQuotation(QuotationModel q) async {
    try {
      await ref.read(supportRepoProvider).acceptQuote(q.id);
      ref.invalidate(quotationListProvider);
      ref.invalidate(productBookingsProvider);
      if (mounted) {
        showSuccess(
          context,
          title: 'Quotation Accepted',
          message: 'Quotation accepted! A confirmed product order has been created. Proceeding to orders...',
          actionLabel: 'View Orders',
          onAction: () => _tabController.animateTo(3),
        );
        _tabController.animateTo(3);
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
    final reasonCtrl = TextEditingController(text: 'Price is higher than expected.');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Decline Quotation', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason so our team can revise the proposal for you:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('Decline Quote', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(supportRepoProvider).rejectQuote(q.id, reasonCtrl.text);
      ref.invalidate(quotationListProvider);
      if (mounted) {
        showSuccess(
          context,
          title: 'Quotation Declined',
          message: 'You have declined this quotation. Our team will review your feedback.',
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

  Future<void> _payForProductBooking(ProductBookingModel b) async {
    if (b.paymentStatus?.toLowerCase() == 'paid') {
      showError(context, title: 'Already Paid', message: 'This product order is already marked as paid.');
      return;
    }
    showLoading(context, message: 'Preparing payment...');
    try {
      final repo = ref.read(paymentRepoProvider);
      final res = await repo.createOrder(b.id);
      if (res.free) {
        await hideLoading();
        ref.invalidate(productBookingsProvider);
        ref.invalidate(paymentListProvider);
        if (mounted) {
          showSuccess(
            context,
            title: 'Order Paid',
            message: 'This order required no payment and is marked paid.',
          );
        }
        return;
      }

      await hideLoading();
      // Open Razorpay Checkout Screen
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
            ref.invalidate(productBookingsProvider);
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
      await hideLoading();
      if (mounted) {
        final appErr = mapException(e);
        showError(context, title: 'Payment Failed', message: appErr.userMessage);
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
        final st = q.status.toLowerCase();
        final isActionable = st == 'sent' || st == 'viewed' || st == 'pending';
        final fin = q.financialSnapshot;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: SingleChildScrollView(
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
                            Row(
                              children: [
                                if (q.quotationNumber != null) ...[
                                  Text(
                                    q.quotationNumber!,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isActionable ? const Color(0xFFFEF3C7) : AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    q.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isActionable ? const Color(0xFFD97706) : AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Financial Breakdown Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        if (fin != null) ...[
                          if (fin['baseAmountPaise'] is num)
                            _buildPriceLine('Base Equipment', '₹${((fin['baseAmountPaise'] as num) / 100).toStringAsFixed(0)}'),
                          if ((fin['installationAmountPaise'] is num) && (fin['installationAmountPaise'] as num) > 0)
                            _buildPriceLine('Installation & Setup', '₹${((fin['installationAmountPaise'] as num) / 100).toStringAsFixed(0)}'),
                          if ((fin['additionalChargesPaise'] is num) && (fin['additionalChargesPaise'] as num) > 0)
                            _buildPriceLine('Additional Charges', '₹${((fin['additionalChargesPaise'] as num) / 100).toStringAsFixed(0)}'),
                          if ((fin['discountPaise'] is num) && (fin['discountPaise'] as num) > 0)
                            _buildPriceLine('Discount Applied', '- ₹${((fin['discountPaise'] as num) / 100).toStringAsFixed(0)}', isDiscount: true),
                          if (fin['gstAmountPaise'] is num)
                            _buildPriceLine('GST (${fin['gstPercent'] ?? 18}%)', '₹${((fin['gstAmountPaise'] as num) / 100).toStringAsFixed(0)}'),
                          const Divider(height: 20),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Authoritative Total', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w800)),
                            Text(
                              inr(q.amount),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
                            ),
                          ],
                        ),
                        if (q.validUntil != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Valid Until', style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
                              Text(fmtDate(q.validUntil), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: Color(0xFFD97706))),
                            ],
                          ),
                        ],
                        if (q.createdAt != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Received On', style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
                              Text(fmtDate(q.createdAt), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (q.adminNotes != null && q.adminNotes!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Technician Notes:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                          const SizedBox(height: 4),
                          Text(q.adminNotes!, style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569))),
                        ],
                      ),
                    ),
                  ],

                  if (q.termsAndConditions != null && q.termsAndConditions!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Terms: ${q.termsAndConditions}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],

                  if (isActionable) ...[
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
          ),
        );
      },
    );
  }

  Widget _buildPriceLine(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDiscount ? const Color(0xFF16A34A) : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuoteRequestDetailSheet(QuoteRequestModel r) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return FutureBuilder<QuoteRequestModel>(
          future: ref.read(supportRepoProvider).quoteRequest(r.id).catchError((_) => r),
          initialData: r,
          builder: (fbCtx, snapshot) {
            final item = snapshot.data ?? r;
            final isPending = item.status.toLowerCase() == 'pending';
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                          child: const Icon(Icons.request_quote_outlined, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quote Request Details',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Status: ${item.status.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isPending ? const Color(0xFFD97706) : AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Requirement', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text(item.requirement, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                          if (item.quantity != null) ...[
                            const SizedBox(height: 12),
                            const Text('Quantity', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text('${item.quantity} units', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                          ],
                          if (item.additionalNotes != null && item.additionalNotes!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text('Additional Notes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text(item.additionalNotes!, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                          ],
                          if (item.preferredContactMethod != null) ...[
                            const SizedBox(height: 12),
                            const Text('Preferred Contact', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text(item.preferredContactMethod!, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                          ],
                          if (item.addressLine != null && item.addressLine!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text('Location', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text(item.addressLine!, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                          ],
                        ],
                      ),
                    ),
                    if (isPending) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showEditQuoteRequestModal(item);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Edit Request', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _cancelRequest(item);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(color: Color(0xFFFCA5A5)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancel Request', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
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
      },
    );
  }

  void _showEditQuoteRequestModal(QuoteRequestModel r) {
    final reqCtrl = TextEditingController(text: r.requirement);
    final notesCtrl = TextEditingController(text: r.additionalNotes ?? '');
    int qty = r.quantity ?? 1;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (mCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(mCtx).viewInsets.bottom + 24),
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
                  const Text(
                    'Edit Quote Request',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Requirement Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reqCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: 'Describe required model or specification...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF64748B)),
                            onPressed: qty > 1 ? () => setModalState(() => qty--) : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                            onPressed: qty < 99 ? () => setModalState(() => qty++) : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Additional Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: 'Any special installation or delivery notes...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : () async {
                        if (reqCtrl.text.trim().isEmpty) return;
                        setModalState(() => saving = true);
                        try {
                          await ref.read(supportRepoProvider).updateQuoteRequest(r.id, {
                            'requirementDescription': reqCtrl.text.trim(),
                            'quantity': qty,
                            'additionalNotes': notesCtrl.text.trim(),
                          });
                          ref.invalidate(quoteRequestListProvider);
                          if (mCtx.mounted) Navigator.pop(mCtx);
                          if (!mounted) return;
                          showSuccess(context, title: 'Request Updated', message: 'Your quote request has been updated.');
                        } catch (e) {
                          setModalState(() => saving = false);
                          if (!mounted) return;
                          showError(context, title: 'Update Failed', message: mapException(e).userMessage);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showProductBookingDetailSheet(ProductBookingModel b) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return FutureBuilder<ProductBookingModel>(
          future: ref.read(supportRepoProvider).productBooking(b.id).catchError((_) => b),
          initialData: b,
          builder: (fbCtx, snapshot) {
            final item = snapshot.data ?? b;
            final isCancelled = item.status.toLowerCase() == 'cancelled';
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                          child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName ?? 'Custom Equipment Order',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Status: ${item.status.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isCancelled ? const Color(0xFFDC2626) : AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
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
                              const Text('Order ID', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                              Text(item.id.length > 10 ? '${item.id.substring(0, 10)}...' : item.id, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            ],
                          ),
                          const Divider(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Quantity', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                              Text('${item.quantity ?? 1} units', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                            ],
                          ),
                          if (item.amount != null) ...[
                            const Divider(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Amount', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                Text(inr(item.amount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary)),
                              ],
                            ),
                          ],
                          if (item.paymentStatus != null) ...[
                            const Divider(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Payment Status', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (item.paymentStatus!.toLowerCase() == 'paid')
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    (item.paymentStatus!.toLowerCase() == 'paid') ? 'PAID' : 'PAYMENT PENDING',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                      color: (item.paymentStatus!.toLowerCase() == 'paid')
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFD97706),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (item.createdAt != null) ...[
                            const Divider(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Ordered On', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                Text(fmtDate(item.createdAt), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!isCancelled && item.paymentStatus?.toLowerCase() != 'paid') ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _payForProductBooking(item);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.payment_rounded, size: 18),
                          label: Text(
                            'Pay Now (${inr(item.amount ?? 0)})',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                    if (!isCancelled) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showUpdateBookingQuantityModal(item);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Update Qty', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                try {
                                  await ref.read(supportRepoProvider).cancelProductBooking(item.id);
                                  ref.invalidate(productBookingsProvider);
                                  if (!mounted) return;
                                  showSuccess(context, title: 'Order Cancelled', message: 'Product order cancelled successfully.');
                                } catch (e) {
                                  if (!mounted) return;
                                  showError(context, title: 'Cancellation Failed', message: mapException(e).userMessage);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(color: Color(0xFFFCA5A5)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
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
      },
    );
  }

  void _showUpdateBookingQuantityModal(ProductBookingModel b) {
    int qty = b.quantity ?? 1;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (mCtx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Update Quantity - ${b.productName ?? 'Product'}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filled(
                          onPressed: qty > 1 ? () => setModalState(() => qty--) : null,
                          icon: const Icon(Icons.remove, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Text(
                          '$qty',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primary),
                        ),
                        const SizedBox(width: 24),
                        IconButton.filled(
                          onPressed: qty < 99 ? () => setModalState(() => qty++) : null,
                          icon: const Icon(Icons.add, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving ? null : () async {
                          setModalState(() => saving = true);
                          try {
                            await ref.read(supportRepoProvider).updateProductBookingQuantity(b.id, qty);
                            ref.invalidate(productBookingsProvider);
                            if (mCtx.mounted) Navigator.pop(mCtx);
                            if (!mounted) return;
                            showSuccess(context, title: 'Quantity Updated', message: 'Product order quantity updated to $qty.');
                          } catch (e) {
                            setModalState(() => saving = false);
                            if (!mounted) return;
                            showError(context, title: 'Update Failed', message: mapException(e).userMessage);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Confirm Update', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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

          // Target Product Selection (Optional)
          Consumer(
            builder: (context, ref, _) {
              final productsAsync = ref.watch(productListProvider);
              return productsAsync.when(
                data: (products) {
                  if (products.isEmpty) return const SizedBox();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Target Product (Optional)',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        initialValue: _selectedProductId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Select a product or leave for custom',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Custom / Not specific', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                          ),
                          ...products.map((p) => DropdownMenuItem<String?>(
                                value: p.id,
                                child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                              )),
                        ],
                        onChanged: (val) => setState(() => _selectedProductId = val),
                      ),
                      const SizedBox(height: 18),
                    ],
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              );
            },
          ),

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
              for (final entry in [
                {'label': 'WhatsApp', 'val': 'whatsapp'},
                {'label': 'Call', 'val': 'call'},
                {'label': 'Both', 'val': 'both'},
              ]) ...[
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _contactMethod = entry['val']!);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _contactMethod == entry['val']
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _contactMethod == entry['val']
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                      boxShadow: _contactMethod == entry['val']
                          ? const [
                              BoxShadow(
                                color: Color(0x3316A34A),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_contactMethod == entry['val']) ...[
                          const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          entry['label']!,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _contactMethod == entry['val']
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
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
              final st = x.status.toLowerCase();
              final isActionable = st == 'sent' || st == 'viewed' || st == 'pending';
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                x.title ?? 'Custom Equipment Quotation',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                              ),
                              if (x.quotationNumber != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  x.quotationNumber!,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActionable ? const Color(0xFFFEF3C7) : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            x.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isActionable ? const Color(0xFFD97706) : AppColors.primaryDark,
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
                            const Text('Quoted Total', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            Text(
                              inr(x.amount),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
                            ),
                            if (x.validUntil != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Valid until ${fmtDate(x.validUntil)}',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Color(0xFFD97706)),
                              ),
                            ],
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
                    if (isActionable) ...[
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => _showQuoteRequestDetailSheet(r),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          child: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                        if (isPending) ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _showEditQuoteRequestModal(r),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            child: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _cancelRequest(r),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFFCA5A5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (b.paymentStatus?.toLowerCase() == 'paid')
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (b.paymentStatus?.toLowerCase() == 'paid') ? 'PAID' : 'PAYMENT PENDING',
                            style: TextStyle(
                              color: (b.paymentStatus?.toLowerCase() == 'paid')
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFD97706),
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (b.amount != null)
                      Text(
                        inr(b.amount),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => _showProductBookingDetailSheet(b),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: const Text('View Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                          if (b.status.toLowerCase() != 'cancelled' && b.paymentStatus?.toLowerCase() != 'paid') ...[
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () => _payForProductBooking(b),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.payment_rounded, size: 14),
                              label: const Text('Pay Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            ),
                          ],
                          if (b.status.toLowerCase() != 'cancelled') ...[
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => _showUpdateBookingQuantityModal(b),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: const Text('Update Qty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Builder(
                            builder: (context) {
                              final myRatings = ref.watch(myRatingsProvider).valueOrNull ?? [];
                              final hasRated = myRatings.any((r) => r.bookingId == b.id);
                              return OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: hasRated ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
                                  side: BorderSide(color: hasRated ? const Color(0xFFBBF7D0) : const Color(0xFFCBD5E1)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: Icon(hasRated ? Icons.star_rounded : Icons.star_outline_rounded, size: 16, color: hasRated ? const Color(0xFFF59E0B) : null),
                                label: Text(hasRated ? 'Edit Review' : 'Rate Product', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                onPressed: () => _rateProduct(b),
                              );
                            },
                          ),
                        ],
                      ),
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

