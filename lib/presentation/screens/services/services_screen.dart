import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/cards.dart';
import '../../widgets/right_touch_header.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const ServicesScreen({super.key, this.initialCategory});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  String? _selectedCategory;
  final String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  void _selectCategory(String? catName) {
    setState(() {
      _selectedCategory = catName;
    });
    ref.read(serviceQueryProvider.notifier).state =
        ServiceQuery(_searchQuery, _selectedCategory);
  }

  void _bookService(ServiceModel s) async {
    try {
      await ref.read(cartRepoProvider).add(s.id, 'service', 1);
      ref.invalidate(cartProvider);
      if (mounted) {
        showSuccess(
          context,
          title: 'Added to cart',
          message: '${s.name} added to cart.',
          actionLabel: 'View cart',
          onAction: () => context.push('/cart'),
        );
      }
    } catch (e) {
      if (mounted) {
        final appErr = mapException(e);
        showError(
          context,
          title: 'Could not add to cart',
          message: appErr.userMessage,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(serviceListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    final serviceCategories = categoriesAsync.maybeWhen(
      data: (cats) => cats.where((c) => !c.isProductCategory).toList(),
      orElse: () => <CategoryModel>[],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const RightTouchTopAppBar(),
      body: RefreshIndicator(
        color: const Color(0xFF059669),
        onRefresh: () async {
          ref.invalidate(serviceListProvider);
          ref.invalidate(categoryListProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Home Services',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  servicesAsync.maybeWhen(
                    data: (list) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6FDF1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${list.length} available',
                        style: const TextStyle(
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category Filter Chips
              if (serviceCategories.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('All Services', null),
                      for (final cat in serviceCategories)
                        _buildCategoryChip(cat.name, cat.name),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Services List
              servicesAsync.when(
                data: (services) {
                  if (services.isEmpty) {
                    return _buildEmptyState();
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 310,
                    ),
                    itemCount: services.length,
                    itemBuilder: (_, i) {
                      final s = services[i];
                      return ApplianceServiceItemCard(
                        service: s,
                        onTap: () => context.push('/service/${s.id}'),
                        onBook: () => _bookService(s),
                      );
                    },
                  );
                },
                loading: () => const CardGridShimmer(count: 6),
                error: (e, _) => _buildEmptyState(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? cat) {
    final isSelected = _selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _selectCategory(cat),
        selectedColor: const Color(0xFF059669),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF475569),
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_repair_service_outlined,
              size: 36,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No services found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try selecting another category or check back later.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _selectCategory(null),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('View All Services'),
          ),
        ],
      ),
    );
  }
}
