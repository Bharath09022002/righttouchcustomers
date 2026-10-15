import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/cards.dart';
import '../../widgets/right_touch_header.dart';
import '../../widgets/service_preview_dialog.dart';
import '../../../core/widgets/ui.dart';

class CategoryScreen extends ConsumerWidget {
  final String id;
  final String name;
  const CategoryScreen({super.key, required this.id, required this.name});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(serviceListProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: RightTouchTopAppBar(title: name),
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
                onAdd: () => showServicePreview(
                  context: context,
                  ref: ref,
                  service: show[i],
                ),
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
