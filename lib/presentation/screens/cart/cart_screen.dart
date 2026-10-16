import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/right_touch_header.dart';
import '../../widgets/guest_login_placeholder.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _tipController = TextEditingController();
  String? _updatingId;

  @override
  void dispose() {
    _tipController.dispose();
    super.dispose();
  }

  void _setTip(int tip) {
    HapticFeedback.lightImpact();
    final current = ref.read(selectedCartTipProvider);
    if (current == tip) {
      ref.read(selectedCartTipProvider.notifier).state = 0;
    } else {
      ref.read(selectedCartTipProvider.notifier).state = tip;
    }
  }

  void _showCustomTipDialog() {
    _tipController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Custom Tip', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: TextField(
          controller: _tipController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: '₹ ',
            hintText: 'Enter amount',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A859),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = int.tryParse(_tipController.text.trim());
              if (val != null && val > 0) {
                ref.read(selectedCartTipProvider.notifier).state = val;
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add Tip'),
          ),
        ],
      ),
    );
  }

  void _showCancellationPolicySheet() {
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
                  'Cancellation Policy',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Free cancellation up to 4 hours prior to the scheduled slot.\n'
              '• Cancellations within 4 hours may attract a nominal technician dispatch fee of ₹100.\n'
              '• In case of rescheduling, no fee is charged if notified at least 2 hours prior.\n'
              '• Full refunds for online payments are processed to source within 3-5 working days.',
              style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A859),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleIncrement(CartItemModel it) async {
    if (_updatingId != null) return;
    if (it.qty >= 10) {
      showError(context, title: 'Notice', message: 'Maximum quantity of 10 reached.');
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _updatingId = it.id);
    try {
      await ref.read(cartRepoProvider).updateQty(
            it.id,
            it.qty + 1,
            itemId: it.itemId,
            itemType: it.itemType,
          );
      ref.invalidate(cartProvider);
    } catch (e) {
      if (mounted) {
        final appErr = mapException(e);
        showError(context, title: 'Error', message: appErr.userMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _updatingId = null);
      }
    }
  }

  Future<void> _handleDecrement(CartItemModel it) async {
    if (_updatingId != null) return;
    HapticFeedback.lightImpact();
    if (it.qty <= 1) {
      final shouldRemove = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Remove Item',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: const Text(
            'Are you sure you want to remove this item from your cart?',
            style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (shouldRemove != true) return;
      setState(() => _updatingId = it.id);
      try {
        await ref.read(cartRepoProvider).remove(it.id);
        ref.invalidate(cartProvider);
      } catch (e) {
        if (mounted) {
          final appErr = mapException(e);
          showError(context, title: 'Error', message: appErr.userMessage);
        }
      } finally {
        if (mounted) {
          setState(() => _updatingId = null);
        }
      }
    } else {
      setState(() => _updatingId = it.id);
      try {
        await ref.read(cartRepoProvider).updateQty(
              it.id,
              it.qty - 1,
              itemId: it.itemId,
              itemType: it.itemType,
            );
        ref.invalidate(cartProvider);
      } catch (e) {
        if (mounted) {
          final appErr = mapException(e);
          showError(context, title: 'Error', message: appErr.userMessage);
        }
      } finally {
        if (mounted) {
          setState(() => _updatingId = null);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth.isGuest) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: const RightTouchTopAppBar(title: 'My Cart', showLeading: false),
        body: GuestLoginPlaceholder(
          icon: Icons.shopping_bag_outlined,
          title: 'Sign In to View Your Cart',
          subtitle: 'Please log in with your phone number to view your cart items, select address, and proceed to booking.',
          primaryButtonText: 'Log In to Continue',
          secondaryButtonText: 'Explore Services',
          onSecondaryAction: () => context.go('/services'),
        ),
      );
    }

    final cart = ref.watch(cartProvider);
    final selectedTip = ref.watch(selectedCartTipProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const RightTouchTopAppBar(title: 'My Cart', showLeading: false),
      body: cart.when(
        skipLoadingOnReload: true,
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              subtitle: 'Explore services and add them to book together.',
              cta: 'Browse services',
              onCta: () => context.go('/'),
            );
          }

          final itemTotal = items.fold<num>(0, (sum, it) => sum + (it.price ?? 0) * it.qty);
          final grandTotal = itemTotal + selectedTip;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // 1. Items in Cart
                    ...items.map((it) => _buildCartItemCard(it)),

                    const SizedBox(height: 14),

                    // 2. Payment summary card
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
                            'Payment summary',
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
                              const Expanded(
                                child: Text(
                                  'Item total',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '₹${itemTotal.toInt()}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          if (selectedTip > 0) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Tip for professional',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
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
                              const Expanded(
                                child: Text(
                                  'Amount to pay',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '₹${grandTotal.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3. Cancellation Policy card
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
                            'Cancellation Policy',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Free cancellation up to 4 hours before service. Cancellation charges may apply after that.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _showCancellationPolicySheet,
                            child: const Text(
                              'Read full policy',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF00A859),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 4. Add a tip to thank the professional
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
                            'Add a tip to thank the professional',
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
                              _buildTipChip(amount: 50, label: '₹50'),
                              _buildMostTippedChip(amount: 75),
                              _buildTipChip(amount: 100, label: '₹100'),
                              _buildCustomTipChip(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 5. Sticky Bottom Checkout Bar
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
                              'Total Amount',
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
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.push('/checkout');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A859),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                        ),
                        child: const Text(
                          'CHECKOUT',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
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
              Text('Failed to load cart: $e'),
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

  Widget _buildCartItemCard(CartItemModel it) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: AppImage(
              url: it.image,
              width: 60,
              height: 60,
              fit: BoxFit.contain,
              errorWidget: Center(
                child: Icon(
                  it.itemType.toUpperCase() == 'PRODUCT'
                      ? Icons.inventory_2_outlined
                      : Icons.build_circle_outlined,
                  color: const Color(0xFF94A3B8),
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  it.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
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
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (it.duration != null && it.duration!.isNotEmpty)
                      Text(
                        it.duration!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  it.price != null ? '₹${it.price!.toInt()}' : '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Green Stepper: [-] 1 [+]
          Builder(
            builder: (context) {
              final isItemUpdating = _updatingId == it.id;
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00A859),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      button: true,
                      label: 'Decrease quantity',
                      child: InkWell(
                        onTap: isItemUpdating ? null : () => _handleDecrement(it),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Icon(
                            Icons.remove,
                            color: isItemUpdating ? Colors.white38 : Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: isItemUpdating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              '${it.qty}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Increase quantity',
                      child: InkWell(
                        onTap: isItemUpdating ? null : () => _handleIncrement(it),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Icon(
                            Icons.add,
                            color: isItemUpdating ? Colors.white38 : Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTipChip({required int amount, required String label}) {
    final selectedTip = ref.watch(selectedCartTipProvider);
    final isSelected = selectedTip == amount;

    return GestureDetector(
      onTap: () => _setTip(amount),
      child: Container(
        width: 66,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00A859) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: isSelected ? const Color(0xFF00A859) : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  Widget _buildMostTippedChip({required int amount}) {
    final selectedTip = ref.watch(selectedCartTipProvider);
    final isSelected = selectedTip == amount;

    return GestureDetector(
      onTap: () => _setTip(amount),
      child: Container(
        width: 72,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00A859) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  '₹$amount',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              decoration: const BoxDecoration(
                color: Color(0xFF00A859),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: const Text(
                'Most\nTipped',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTipChip() {
    final selectedTip = ref.watch(selectedCartTipProvider);
    final isCustom = selectedTip > 0 && selectedTip != 50 && selectedTip != 75 && selectedTip != 100;

    return GestureDetector(
      onTap: _showCustomTipDialog,
      child: Container(
        width: 76,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCustom ? const Color(0xFF00A859) : const Color(0xFFE2E8F0),
            width: isCustom ? 1.8 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          isCustom ? '₹$selectedTip' : 'Custom',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isCustom ? const Color(0xFF00A859) : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}
