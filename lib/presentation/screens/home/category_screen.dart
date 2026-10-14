import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/cards.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/ui/app_feedback.dart';

class CategoryScreen extends ConsumerWidget {
  final String id;
  final String name;
  const CategoryScreen({super.key, required this.id, required this.name});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(serviceListProvider);
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: detail.when(
        data: (all) {
          final list = all.where((s) => s.categoryId == id || id.isEmpty).toList();
          final show = list.isEmpty ? all : list;
          if (show.isEmpty) return const EmptyState(icon: Icons.grid_view, title: 'No services yet', subtitle: 'Services in this category will appear here.');
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: show.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ServiceCard(
                s: show[i],
                onTap: () => context.push('/service/${show[i].id}'),
                onAdd: () async {
                  try {
                    await ref.read(cartRepoProvider).add(show[i].id, 'service', 1);
                    ref.invalidate(cartProvider);
                    if (context.mounted) {
                      showSuccess(
                        context,
                        title: 'Added to cart',
                        message: '${show[i].name} added to cart.',
                        actionLabel: 'View cart',
                        onAction: () => context.push('/cart'),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      final appErr = mapException(e);
                      showError(
                        context,
                        title: 'Could not add to cart',
                        message: appErr.userMessage,
                      );
                    }
                  }
                },
              ),
            ),
          );
        },
        loading: () => const Center(child: RtLoader()),
        error: (e, _) => ErrorView(message: '$e', onRetry: () => ref.invalidate(serviceListProvider)),
      ),
    );
  }
}
