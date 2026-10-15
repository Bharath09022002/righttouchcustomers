import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ui.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/cards.dart';
import '../../widgets/right_touch_header.dart';
import '../../widgets/service_preview_dialog.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const ServicesScreen({super.key, this.initialCategory});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  CategoryModel? _selectedCategory;
  bool _initializedCategory = false;
  bool _showAll = false;
  final String _searchQuery = '';

  void _selectCategory(CategoryModel? cat) {
    setState(() {
      _selectedCategory = cat;
      _showAll = false; // Reset to 10 on filter change
    });
    ref.read(serviceQueryProvider.notifier).state =
        ServiceQuery(_searchQuery, cat?.id);
  }

  void _bookService(ServiceModel s) {
    showServicePreview(
      context: context,
      ref: ref,
      service: s,
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(serviceListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    final serviceCategories = categoriesAsync.maybeWhen(
      data: (cats) => cats.where((c) => !c.isProductCategory).toList(),
      orElse: () => <CategoryModel>[],
    );

    // Initial category sync if passed via URL/Router
    if (!_initializedCategory && widget.initialCategory != null && serviceCategories.isNotEmpty) {
      final match = serviceCategories.firstWhere(
        (c) => c.name.toLowerCase() == widget.initialCategory!.toLowerCase() || c.id == widget.initialCategory,
        orElse: () => serviceCategories.first,
      );
      _selectedCategory = match;
      _initializedCategory = true;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const RightTouchTopAppBar(title: 'Services'),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(serviceListProvider);
          ref.invalidate(categoryListProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title: "All Services"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Services',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  servicesAsync.maybeWhen(
                    data: (list) {
                      final filteredCount = _filterServices(list).length;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryBorder),
                        ),
                        child: Text(
                          '$filteredCount available',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
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
                        _buildCategoryChip(cat.name, cat),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Services List
              servicesAsync.when(
                data: (allServices) {
                  final filtered = _filterServices(allServices);

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Show initial 10 services or all if expanded
                  final displayList = (_showAll || filtered.length <= 10)
                      ? filtered
                      : filtered.take(10).toList();

                  return Column(
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 310,
                        ),
                        itemCount: displayList.length,
                        itemBuilder: (_, i) {
                          final s = displayList[i];
                          return ApplianceServiceItemCard(
                            service: s,
                            showTopBadge: false, // Took out top service badge on services page
                            onTap: () => context.push('/service/${s.id}'),
                            onBook: () => _bookService(s),
                          );
                        },
                      ),

                      // Read More button for services exceeding 10
                      if (!_showAll && filtered.length > 10) ...[
                        const SizedBox(height: 18),
                        Center(
                          child: InkWell(
                            onTap: () => setState(() => _showAll = true),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primary, width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Read More (${filtered.length - 10} more)',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
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

  List<ServiceModel> _filterServices(List<ServiceModel> list) {
    if (_selectedCategory == null) return list;

    final targetId = _selectedCategory!.id;
    final targetName = _selectedCategory!.name.toLowerCase().trim();

    return list.where((s) {
      // 1. Category ID match
      if (s.categoryId == targetId) return true;

      // 2. Category Name match
      if (s.categoryName?.toLowerCase().trim() == targetName) return true;

      // 3. Service Name or Description contains Category name
      final sName = s.name.toLowerCase();
      final sDesc = (s.description ?? '').toLowerCase();
      if (sName.contains(targetName) || sDesc.contains(targetName)) return true;

      // 4. Significant keyword matching
      final parts = targetName.split(' ');
      for (final p in parts) {
        if (p.length >= 3 && (sName.contains(p) || sDesc.contains(p))) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  Widget _buildCategoryChip(String label, CategoryModel? cat) {
    final isSelected = _selectedCategory?.id == cat?.id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _selectCategory(cat),
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          width: isSelected ? 1.5 : 1.0,
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
              backgroundColor: AppColors.primary,
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
