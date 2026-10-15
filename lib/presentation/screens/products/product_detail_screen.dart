import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/right_touch_header.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ProductDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  bool _isAdding = false;

  void _showQuoteModal(ProductModel p) {
    final noteCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Request Quote',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                p.name,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Our technical engineer will prepare a customized proposal with installation and subsidy details.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add site specifications (e.g. 5kW rooftop, 3-phase connection, battery backup...)',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final note = noteCtrl.text.trim();
                    Navigator.pop(ctx);
                    try {
                      await ref.read(supportRepoProvider).submitQuoteRequest(
                            note.isEmpty ? 'Quote requested for ${p.name}' : '${p.name}: $note',
                          );
                      ref.invalidate(quotationListProvider);
                      if (mounted) {
                        showSuccess(
                          context,
                          title: 'Quote Requested',
                          message: 'Your quote request for ${p.name} has been submitted.',
                          actionLabel: 'View Quotes',
                          onAction: () => context.push('/quotations'),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        final appErr = mapException(e);
                        showError(
                          context,
                          title: 'Quote Request Failed',
                          message: appErr.userMessage,
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() => noteCtrl.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.id));
    final cartItems = ref.watch(cartProvider).valueOrNull ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: const RightTouchTopAppBar(title: 'Product Details'),
      body: productAsync.when(
        data: (p) {
          final inCart = cartItems.any((it) => it.itemId == p.id || it.id == p.id);
          final hasPrice = p.price != null && p.price! > 0 && !p.quoteRequired;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Display Card
                      Container(
                        width: double.infinity,
                        height: 240,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Center(
                              child: AppImage(
                                url: p.image,
                                width: double.infinity,
                                height: 240,
                                fit: BoxFit.contain,
                                errorWidget: Center(
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    size: 56,
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ),
                            if (p.brand != null && p.brand!.isNotEmpty)
                              Positioned(
                                left: 12,
                                top: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    p.brand!.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Rating & Guarantee Row
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Wrap(
                            spacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Icon(Icons.star_rounded, size: 20, color: Color(0xFFFBBF24)),
                              Text(
                                p.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '(${p.ratingCount} reviews)',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.verified_rounded, size: 13, color: Color(0xFF16A34A)),
                                SizedBox(width: 4),
                                Text(
                                  'Genuine Product',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Title
                      Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          height: 1.25,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Price / Quote Section
                      if (hasPrice) ...[
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              '₹${p.price!.toInt()}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            if (p.mrp != null && p.mrp! > p.price!) ...[
                              Text(
                                '₹${p.mrp!.toInt()}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  decoration: TextDecoration.lineThrough,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${(((p.mrp! - p.price!) / p.mrp!) * 100).toInt()}% OFF',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Inclusive of all taxes • Delivery & installation available',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.request_quote_rounded, color: Color(0xFF16A34A), size: 22),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Custom Quote Required\nProposal includes equipment sizing, site visit & subsidy guidance.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF166534),
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Warranty Card
                      if (p.warranty.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Manufacturer Warranty',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      p.warranty,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Description
                      if (p.description != null && p.description!.isNotEmpty) ...[
                        Text(
                          'Product Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.description!,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // RightTouch Advantage
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'The RightTouch Advantage',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _advantageRow(Icons.check_circle_rounded, '100% Genuine Certified Equipment'),
                            _advantageRow(Icons.handyman_rounded, 'Professional On-Site Installation Available'),
                            _advantageRow(Icons.headset_mic_rounded, 'Dedicated Customer & Warranty Support'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Fixed Bottom Action Bar
              Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: hasPrice
                      ? Row(
                          children: [
                            // Quantity selector
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    onPressed: _quantity > 1
                                        ? () => setState(() => _quantity--)
                                        : null,
                                  ),
                                  Text(
                                    '$_quantity',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    onPressed: () => setState(() => _quantity++),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Add to cart / Buy button
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isAdding
                                      ? null
                                      : () async {
                                          setState(() => _isAdding = true);
                                          HapticFeedback.lightImpact();
                                          try {
                                            await ref.read(cartRepoProvider).add(p.id, 'product', _quantity);
                                            ref.invalidate(cartProvider);
                                            if (context.mounted) {
                                              showSuccess(
                                                context,
                                                title: 'Added to cart',
                                                message: '$_quantity x ${p.name} added to cart.',
                                                actionLabel: 'View Cart',
                                                onAction: () => context.push('/cart'),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              final appErr = mapException(e);
                                              showError(
                                                context,
                                                title: 'Notice',
                                                message: appErr.userMessage,
                                              );
                                            }
                                          } finally {
                                            if (mounted) setState(() => _isAdding = false);
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16A34A),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isAdding
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : Text(
                                          inCart ? 'Add More' : 'Add to Cart',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => _showQuoteModal(p),
                            icon: const Icon(Icons.request_quote_rounded, size: 20),
                            label: const Text(
                              'Request Customized Quote',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF16A34A)),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
                const SizedBox(height: 12),
                Text(
                  'Could not load product details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(productDetailProvider(widget.id)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _advantageRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF16A34A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
