import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ui.dart';
import '../../providers/providers.dart';
import '../../widgets/cards.dart';
import '../../widgets/service_preview_dialog.dart';

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
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(
                  label: 'All',
                  isSelected: q.categoryId == null,
                  onTap: () => ref.read(serviceQueryProvider.notifier).state = ServiceQuery(q.search, null),
                ),
                for (final c in list) ...[
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: c.name,
                    isSelected: q.categoryId == c.id,
                    onTap: () => ref.read(serviceQueryProvider.notifier).state = ServiceQuery(q.search, c.id),
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
                    onAdd: () => showServicePreview(
                      context: context,
                      ref: ref,
                      service: list[i],
                    ),
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

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8F8EE) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF00A859) : const Color(0xFFCBD5E1),
              width: isSelected ? 1.4 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0x1F00A859)
                    : const Color(0x08000000),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Color(0xFF00A859),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF00A859) : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
