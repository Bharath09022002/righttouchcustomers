import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/ui/app_feedback.dart';
import '../../providers/providers.dart';
import '../../widgets/cards.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _S();
}

class _S extends ConsumerState<SearchScreen> {
  final _c = TextEditingController();
  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      ref.read(serviceQueryProvider.notifier).state =
          ServiceQuery(_c.text.trim(), ref.read(serviceQueryProvider).categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(serviceListProvider);
    final cats = ref.watch(categoryListProvider);
    final q = ref.watch(serviceQueryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Search services')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _c,
            autofocus: true,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Try “AC repair”, “cleaning”…'),
          ),
        ),
        cats.when(
          data: (list) => SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: q.categoryId == null,
                  onSelected: (_) => ref.read(serviceQueryProvider.notifier).state = ServiceQuery(q.search, null),
                ),
                for (final c in list) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(c.name),
                    selected: q.categoryId == c.id,
                    onSelected: (_) => ref.read(serviceQueryProvider.notifier).state = ServiceQuery(q.search, c.id),
                  ),
                ],
              ],
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        Expanded(
          child: services.when(
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(icon: Icons.search_off_outlined, title: 'No services found', subtitle: 'Try another keyword or check serviceability for your GPS location.');
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ServiceCard(
                    s: list[i],
                    onTap: () => context.push('/service/${list[i].id}'),
                    onAdd: () async {
                      try {
                        await ref.read(cartRepoProvider).add(list[i].id, 'service', 1);
                        ref.invalidate(cartProvider);
                        if (!context.mounted) return;
                        showSuccess(
                          context,
                          title: 'Added to cart',
                          message: '${list[i].name} added to cart.',
                          actionLabel: 'View cart',
                          onAction: () => context.push('/cart'),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        final appErr = mapException(e);
                        showError(
                          context,
                          title: 'Could not add to cart',
                          message: appErr.userMessage,
                        );
                      }
                    },
                  ),
                ),
              );
            },
            loading: () => const Center(child: RtLoader()),
            error: (e, _) => ErrorView(message: '$e', onRetry: () => ref.invalidate(serviceListProvider)),
          ),
        ),
      ]),
    );
  }
}
