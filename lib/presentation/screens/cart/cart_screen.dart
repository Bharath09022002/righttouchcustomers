import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/utils/format.dart';
import '../../providers/providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My cart')),
      body: cart.when(
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(icon: Icons.shopping_cart_outlined, title: 'Cart is empty', subtitle: 'Add services to book them together.', cta: 'Browse services', onCta: () => context.go('/'));
          }
          final total = items.fold<num>(0, (p, e) => p + (e.price ?? 0) * e.qty);
          return Column(children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final it = items[i];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          if (it.image != null && it.image!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                it.image!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 56,
                                  height: 56,
                                  color: const Color(0xFFF1F5F9),
                                  child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  it.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${it.itemType.toUpperCase()} • ${it.price != null ? inr(it.price) : 'Get a quote'}',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('×${it.qty}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                                onPressed: () async {
                                  await ref.read(cartRepoProvider).remove(it.id);
                                  ref.invalidate(cartProvider);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      const Text('Subtotal', style: TextStyle(color: Color(0xFF64748B))),
                      const Spacer(),
                      Text(inr(total), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const Spacer(),
                      Text(inr(total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF059669))),
                    ]),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Proceed to checkout',
                      fullWidth: true,
                      onPressed: total > 0 ? () => context.push('/checkout') : null,
                    ),
                  ],
                ),
              ),
            ),
          ]);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: '$e', onRetry: () => ref.invalidate(cartProvider)),
      ),
    );
  }
}
