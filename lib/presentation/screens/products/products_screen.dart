import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/right_touch_header.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const ProductsScreen({super.key, this.initialCategory});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isGridView = true;
  bool _under50kFilter = false;
  String? _selectedBrand;
  String _sortBy = 'featured'; // 'featured', 'price_asc', 'price_desc', 'rating'

  final Map<String, int> _quantities = {};
  final Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _searchQuery = '';
      _searchCtrl.clear();
      _under50kFilter = false;
      _selectedBrand = null;
      _sortBy = 'featured';
    });
    ref.read(productQueryProvider.notifier).state = const ProductQuery();
  }

  void _selectCategory(String? catName) {
    setState(() {
      _selectedCategory = catName;
    });
    ref.read(productQueryProvider.notifier).state =
        ProductQuery(_searchQuery, _selectedCategory);
  }

  void _toggleFavorite(String productId) {
    setState(() {
      if (_favorites.contains(productId)) {
        _favorites.remove(productId);
      } else {
        _favorites.add(productId);
      }
    });
  }

  void _changeQuantity(String productId, int delta) {
    setState(() {
      final current = _quantities[productId] ?? 1;
      final next = (current + delta).clamp(1, 99);
      _quantities[productId] = next;
    });
  }

  void _handleProductAction(ProductModel p) async {
    final qty = _quantities[p.id] ?? 1;
    if (p.quoteRequired) {
      _showQuoteRequestModal(p);
    } else {
      try {
        await ref.read(cartRepoProvider).add(p.id, 'product', qty);
        ref.invalidate(cartProvider);
        if (mounted) {
          showSuccess(
            context,
            title: 'Added to cart',
            message: '$qty x ${p.name} added to cart.',
            actionLabel: 'View Cart',
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
  }

  void _showSortModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sort Products By',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),
                _sortTile('featured', 'Featured & Recommended', ctx),
                _sortTile('price_asc', 'Price: Low to High', ctx),
                _sortTile('price_desc', 'Price: High to Low', ctx),
                _sortTile('rating', 'Customer Rating', ctx),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sortTile(String id, String label, BuildContext ctx) {
    final isSelected = _sortBy == id;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF1E293B),
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)) : null,
      onTap: () {
        setState(() => _sortBy = id);
        Navigator.pop(ctx);
      },
    );
  }

  void _showFilterModal(List<CategoryModel> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Products',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Select Category',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All Categories'),
                      selected: _selectedCategory == null,
                      onSelected: (_) {
                        _selectCategory(null);
                        Navigator.pop(ctx);
                      },
                      selectedColor: const Color(0xFFE6FDF1),
                      checkmarkColor: const Color(0xFF16A34A),
                    ),
                    for (final cat in categories)
                      FilterChip(
                        label: Text(cat.name),
                        selected: _selectedCategory == cat.name || _selectedCategory == cat.id,
                        onSelected: (_) {
                          _selectCategory(cat.name);
                          Navigator.pop(ctx);
                        },
                        selectedColor: const Color(0xFFE6FDF1),
                        checkmarkColor: const Color(0xFF16A34A),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _resetFilters();
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Reset All Filters', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQuoteRequestModal(ProductModel p) {
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
              Text(
                'Request Quotation: ${p.name}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Our technical engineer will prepare a customized proposal with installation and subsidy details.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add requirements (e.g. 5kW rooftop, 3-phase connection...)',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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
                        note.isNotEmpty ? note : 'Quote request for ${p.name}',
                      );
                      ref.invalidate(quoteRequestListProvider);
                      if (!mounted) return;
                      showSuccess(
                        context,
                        title: 'Quote Requested',
                        message: 'Quotation request submitted! Our engineer will prepare a proposal.',
                        actionLabel: 'View Quotations',
                        onAction: () => context.push('/quotations'),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      final appErr = mapException(e);
                      showError(
                        context,
                        title: 'Quote Request Failed',
                        message: appErr.userMessage,
                      );
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
    final productsAsync = ref.watch(productListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final productCategories = categoriesAsync.maybeWhen(
      data: (cats) => cats.where((c) => c.isProductCategory).toList(),
      orElse: () => <CategoryModel>[],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const RightTouchTopAppBar(title: 'Products'),
      body: RefreshIndicator(
        color: const Color(0xFF16A34A),
        onRefresh: () async {
          ref.invalidate(productListProvider);
          ref.invalidate(categoryListProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. SEARCH BAR WITH SCANNER ICON
              _buildSearchBar(isDark),

              const SizedBox(height: 14),

              // 2. HERO CAROUSEL BANNER: "Solar Products for a Better Tomorrow"
              _buildHeroBanner(context),

              const SizedBox(height: 14),

              // Stage 7: Custom Quotes & Orders Quick Access Banner
              InkWell(
                onTap: () => context.push('/quotations'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B).withAlpha(120) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF15803D) : const Color(0xFFBBF7D0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.request_quote_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Custom Quotes & Equipment Orders',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Request quotes for industrial/solar equipment or track active orders',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF16A34A)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 3. CATEGORY ICON SELECTOR (All Products, Solar, Surveillance, Appliances, etc.)
              _buildCategoryIconSelector(isDark, productCategories),

              const SizedBox(height: 22),

              // 4. "PRODUCTS" HEADER & VIEW ALL
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Products',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _resetFilters,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'View All',
                          style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_forward_rounded, color: Color(0xFF16A34A), size: 14),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 5. FILTER CHIPS & VIEW SWITCHER ROW
              _buildFilterChipsRow(isDark, productCategories),

              const SizedBox(height: 16),

              // 6. FEATURED CATEGORY BANNERS (Solar Panels & CCTV Cameras)
              _buildCategoryBanners(context),

              const SizedBox(height: 18),

              // 7. PRODUCT CATALOG GRID / LIST
              productsAsync.when(
                data: (rawProducts) {
                  final filtered = _filterAndSortProducts(rawProducts);
                  if (filtered.isEmpty) {
                    return _buildEmptyState(isDark);
                  }

                  if (_isGridView) {
                    final textScaler = MediaQuery.of(context).textScaler;
                    final cardExtent = textScaler.scale(385.0);

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                        mainAxisExtent: cardExtent,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final p = filtered[i];
                        return _buildProductGridCard(p, i, isDark);
                      },
                    );
                  } else {
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final p = filtered[i];
                        return _buildProductListCard(p, i, isDark);
                      },
                    );
                  }
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: RtLoader(),
                  ),
                ),
                error: (error, stack) => _buildEmptyState(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. SEARCH BAR
  // ---------------------------------------------------------------------------
  Widget _buildSearchBar(bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) {
                setState(() => _searchQuery = val);
                ref.read(productQueryProvider.notifier).state =
                    ProductQuery(_searchQuery, _selectedCategory);
              },
              decoration: InputDecoration(
                hintText: 'Search products, brands, models...',
                hintStyle: TextStyle(
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _searchQuery = '');
                ref.read(productQueryProvider.notifier).state =
                    ProductQuery('', _selectedCategory);
              },
              child: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
            )
          else
            const Icon(Icons.crop_free, color: Color(0xFF64748B), size: 20),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. HERO CAROUSEL BANNER
  // ---------------------------------------------------------------------------
  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF062024), Color(0xFF093630)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Background house with solar panels image on right
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 170,
              child: Opacity(
                opacity: 0.65,
                child: const AppImage(
                  url: 'assets/images/solar_banner.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Gradient overlay for smooth transition to dark left side
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF062024),
                      Color(0xEB062024),
                      Color(0x66062024),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.45, 0.75, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            // Content Column
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kicker
                  const Text(
                    'CLEAN ENERGY. SMART LIVING.',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Headline
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        height: 1.18,
                      ),
                      children: [
                        TextSpan(
                          text: 'Solar Products\nfor a ',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: 'Better Tomorrow',
                          style: TextStyle(color: Color(0xFF22C55E)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle
                  const Text(
                    'High efficiency • Long lasting\nTrusted by 50K+ homes',
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 10.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Button & Overlaid Pills
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Shop Solar Products Button
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: InkWell(
                          onTap: () => _selectCategory('Solar Products'),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Shop Solar Products',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F172A), size: 12),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 3 Mini badges: Save Energy, Reduce Bills, Go Green
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _heroBadgePill(Icons.eco_rounded, 'Save Energy'),
                            const SizedBox(width: 4),
                            _heroBadgePill(Icons.currency_rupee_rounded, 'Reduce Bills'),
                            const SizedBox(width: 4),
                            _heroBadgePill(Icons.energy_savings_leaf_outlined, 'Go Green'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Dots Indicator
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroBadgePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF16A34A)),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. CATEGORY ICON SELECTOR (All Products, Solar, Surveillance, Appliances, etc.)
  // ---------------------------------------------------------------------------
  Widget _buildCategoryIconSelector(bool isDark, List<CategoryModel> categories) {
    final items = [
      _CategoryIconItem('All Products', Icons.grid_view_rounded, null, isAll: true),
      _CategoryIconItem('Solar Products', Icons.wb_sunny_rounded, 'solar', iconColor: const Color(0xFFF59E0B)),
      _CategoryIconItem('Surveillance', Icons.videocam_rounded, 'surveil', iconColor: const Color(0xFF3B82F6)),
      _CategoryIconItem('Appliances', Icons.local_laundry_service_outlined, 'appliance', iconColor: const Color(0xFF64748B)),
      _CategoryIconItem('AC & Cooling', Icons.ac_unit_rounded, 'air', iconColor: const Color(0xFF06B6D4)),
      _CategoryIconItem('Electrical', Icons.bolt_rounded, 'electr', iconColor: const Color(0xFF22C55E)),
      _CategoryIconItem('More', Icons.apps_rounded, 'more', iconColor: const Color(0xFF8B5CF6)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _buildCategoryCard(item, isDark, categories),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    _CategoryIconItem item,
    bool isDark,
    List<CategoryModel> categories,
  ) {
    final isSelected = item.isAll
        ? _selectedCategory == null
        : (_selectedCategory != null &&
            _selectedCategory!.toLowerCase().contains(item.matchKeyword ?? item.label.toLowerCase()));

    return InkWell(
      onTap: () {
        if (item.isAll) {
          _selectCategory(null);
        } else if (item.matchKeyword == 'more') {
          _showFilterModal(categories);
        } else {
          final matched = categories.firstWhere(
            (c) => c.name.toLowerCase().contains(item.matchKeyword!),
            orElse: () => CategoryModel(id: '', name: item.label),
          );
          _selectCategory(matched.name);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 72,
        height: 72,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE8FAF2)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF16A34A)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 24,
              color: isSelected ? const Color(0xFF16A34A) : (item.iconColor ?? const Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF16A34A)
                    : (isDark ? Colors.white : const Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. FILTER CHIPS & VIEW SWITCHER ROW
  // ---------------------------------------------------------------------------
  Widget _buildFilterChipsRow(bool isDark, List<CategoryModel> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // Filter button
          _filterPill(
            icon: Icons.filter_alt_outlined,
            label: 'Filter',
            isSelected: _selectedCategory != null,
            isDark: isDark,
            onTap: () => _showFilterModal(categories),
          ),
          const SizedBox(width: 8),

          // Sort button
          _filterPill(
            icon: Icons.swap_vert_rounded,
            label: _sortBy == 'featured' ? 'Sort' : 'Sorted',
            isSelected: _sortBy != 'featured',
            isDark: isDark,
            onTap: _showSortModal,
          ),
          const SizedBox(width: 8),

          // Under ₹50,000 quick toggle
          _filterPill(
            icon: Icons.currency_rupee_rounded,
            label: 'Under ₹50,000',
            isSelected: _under50kFilter,
            isDark: isDark,
            onTap: () {
              setState(() => _under50kFilter = !_under50kFilter);
            },
          ),
          const SizedBox(width: 8),

          // Brand dropdown
          _filterPill(
            icon: null,
            label: _selectedBrand ?? 'Brand',
            hasDropdown: true,
            isSelected: _selectedBrand != null,
            isDark: isDark,
            onTap: () {
              setState(() {
                _selectedBrand = _selectedBrand == null ? 'RightTouch' : null;
              });
            },
          ),
          const SizedBox(width: 14),

          // View mode switch: Grid vs List
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => setState(() => _isGridView = true),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: _isGridView ? const Color(0xFF16A34A) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.grid_view_rounded,
                      size: 16,
                      color: _isGridView ? Colors.white : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                InkWell(
                  onTap: () => setState(() => _isGridView = false),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: !_isGridView ? const Color(0xFF16A34A) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.view_list_rounded,
                      size: 16,
                      color: !_isGridView ? Colors.white : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterPill({
    IconData? icon,
    required String label,
    bool hasDropdown = false,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE8FAF2)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF16A34A)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF64748B)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF16A34A)
                    : (isDark ? Colors.white : const Color(0xFF1E293B)),
              ),
            ),
            if (hasDropdown) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 15,
                color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF64748B),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. FEATURED CATEGORY BANNERS (Solar Panels & CCTV Cameras)
  // ---------------------------------------------------------------------------
  Widget _buildCategoryBanners(BuildContext context) {
    return Row(
      children: [
        // Banner 1: Solar Panels
        Expanded(
          child: _categoryBannerCard(
            title: 'Solar Panels',
            subtitle: 'High efficiency panels\nfor residential & commercial',
            imagePath: 'assets/images/solar_panels_banner.jpg',
            gradientColors: const [Color(0xFF063A37), Color(0xFF0C5A52)],
            onTap: () => _selectCategory('Solar Products'),
          ),
        ),
        const SizedBox(width: 10),

        // Banner 2: CCTV Cameras
        Expanded(
          child: _categoryBannerCard(
            title: 'CCTV Cameras',
            subtitle: 'Smart surveillance\nfor safer living',
            imagePath: 'assets/images/cctv_banner.jpg',
            gradientColors: const [Color(0xFF0E253F), Color(0xFF183B5E)],
            onTap: () => _selectCategory('Surveillance'),
          ),
        ),
      ],
    );
  }

  Widget _categoryBannerCard({
    required String title,
    required String subtitle,
    required String imagePath,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 114,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Image on right half
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 75,
                child: Opacity(
                  opacity: 0.85,
                  child: AppImage(
                    url: imagePath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Gradient fade
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gradientColors.first,
                        gradientColors.first.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              // Text Content & Action Button
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Expanded(
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 8.5,
                                height: 1.15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: gradientColors.first,
                        size: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. PRODUCT GRID CARD
  // ---------------------------------------------------------------------------
  Widget _buildProductGridCard(ProductModel p, int index, bool isDark) {
    final qty = _quantities[p.id] ?? 1;
    final isFav = _favorites.contains(p.id);

    // Dynamic badge based on index or product properties
    final badgeInfo = _getBadgeInfo(index);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Container + Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.all(4),
                  child: AppImage(
                    url: p.image,
                    fit: BoxFit.contain,
                    errorWidget: _fallbackProductImage(p),
                  ),
                ),
              ),

              // Ribbon Badge top-left
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: badgeInfo.colors),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeInfo.icon, size: 10, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(
                        badgeInfo.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Favorite Heart Button top-right
              Positioned(
                right: 8,
                top: 8,
                child: InkWell(
                  onTap: () => _toggleFavorite(p.id),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        )
                      ],
                    ),
                    child: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 15,
                      color: isFav ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),

              // Category tag pill bottom-left of image
              Positioned(
                left: 8,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.categoryName ?? 'RightTouch',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Details & Specifications
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Title
                      Text(
                        p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Rating Row
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 2),
                          Text(
                            p.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            ' (${p.ratingCount})',
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Price Row
                      _buildPriceRow(p),

                      const SizedBox(height: 6),

                      // 3 Bullet Feature Specs with Icons
                      _buildSpecsList(p, isDark),
                    ],
                  ),

                  // Bottom Action Row: [ - 1 + ] & [ Add to Cart ]
                  Row(
                    children: [
                      // Quantity Stepper
                      Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => _changeQuantity(p.id, -1),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 2),
                                child: Icon(Icons.remove, size: 12, color: Color(0xFF64748B)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '$qty',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _changeQuantity(p.id, 1),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 2),
                                child: Icon(Icons.add, size: 12, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Add to Cart Button
                      Expanded(
                        child: SizedBox(
                          height: 30,
                          child: ElevatedButton(
                            onPressed: () => _handleProductAction(p),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.shopping_cart_outlined, size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      p.quoteRequired ? 'Quote' : 'Add to Cart',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7B. PRODUCT LIST CARD (FOR LIST VIEW MODE)
  // ---------------------------------------------------------------------------
  Widget _buildProductListCard(ProductModel p, int index, bool isDark) {
    final qty = _quantities[p.id] ?? 1;
    final isFav = _favorites.contains(p.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 100,
              height: 100,
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              padding: const EdgeInsets.all(4),
              child: AppImage(
                url: p.image,
                fit: BoxFit.contain,
                errorWidget: _fallbackProductImage(p),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Right: Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.categoryName ?? 'RightTouch',
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _toggleFavorite(p.id),
                      child: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 18,
                        color: isFav ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                _buildPriceRow(p),
                const SizedBox(height: 8),

                // Stepper + Add to Cart
                Row(
                  children: [
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _changeQuantity(p.id, -1),
                            child: const Icon(Icons.remove, size: 14, color: Color(0xFF64748B)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '$qty',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _changeQuantity(p.id, 1),
                            child: const Icon(Icons.add, size: 14, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () => _handleProductAction(p),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            p.quoteRequired ? 'Request Quote' : 'Add to Cart',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                          ),
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
    );
  }

  // ---------------------------------------------------------------------------
  // SPECS BULLETS & HELPERS
  // ---------------------------------------------------------------------------
  Widget _buildPriceRow(ProductModel p) {
    if (p.price == null) {
      return const Text(
        'Price on Request',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
        ),
      );
    }

    final price = p.price!.toInt();
    final mrp = p.mrp != null && p.mrp! > p.price! ? p.mrp!.toInt() : (price * 1.2).toInt();
    final discountPercent = (((mrp - price) / mrp) * 100).round();

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '₹${_formatPrice(price)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '₹${_formatPrice(mrp)}',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
              decoration: TextDecoration.lineThrough,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (discountPercent > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$discountPercent% OFF',
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF16A34A),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecsList(ProductModel p, bool isDark) {
    final specs = _resolveProductSpecs(p);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in specs)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Icon(s.icon, size: 10, color: s.iconColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<_SpecItem> _resolveProductSpecs(ProductModel p) {
    final lower = (p.name + (p.categoryName ?? '')).toLowerCase();
    if (lower.contains('solar') || lower.contains('perc')) {
      return const [
        _SpecItem(Icons.bolt_rounded, '550W Output', Color(0xFF22C55E)),
        _SpecItem(Icons.verified_rounded, '25 Years Warranty', Color(0xFF16A34A)),
        _SpecItem(Icons.eco_rounded, 'High Efficiency', Color(0xFF22C55E)),
      ];
    } else if (lower.contains('inverter') || lower.contains('mppt')) {
      return const [
        _SpecItem(Icons.bolt_rounded, '5kVA Hybrid', Color(0xFF22C55E)),
        _SpecItem(Icons.settings_suggest_rounded, 'MPPT Technology', Color(0xFF16A34A)),
        _SpecItem(Icons.verified_rounded, '5 Years Warranty', Color(0xFF16A34A)),
      ];
    } else if (lower.contains('camera') || lower.contains('cctv') || lower.contains('surveil')) {
      return const [
        _SpecItem(Icons.videocam_rounded, '4K Ultra HD', Color(0xFF3B82F6)),
        _SpecItem(Icons.nightlight_round, 'Night Vision', Color(0xFF6366F1)),
        _SpecItem(Icons.cloud_outlined, 'Weather Resistant', Color(0xFF0EA5E9)),
      ];
    } else if (lower.contains('ac') || lower.contains('air') || lower.contains('cool')) {
      return const [
        _SpecItem(Icons.star_rounded, '5 Star Rating', Color(0xFFFBBF24)),
        _SpecItem(Icons.energy_savings_leaf_outlined, 'Inverter Tech', Color(0xFF22C55E)),
        _SpecItem(Icons.build_rounded, 'Free Installation', Color(0xFF16A34A)),
      ];
    } else {
      return [
        const _SpecItem(Icons.verified_rounded, 'Genuine RightTouch', Color(0xFF16A34A)),
        _SpecItem(Icons.security_rounded, p.warranty, const Color(0xFF22C55E)),
        const _SpecItem(Icons.local_shipping_outlined, 'Quick Dispatch', Color(0xFF64748B)),
      ];
    }
  }

  Widget _fallbackProductImage(ProductModel p) {
    final lower = (p.name + (p.categoryName ?? '')).toLowerCase();
    String assetPath = 'assets/images/solar_panels_banner.jpg';
    if (lower.contains('inverter')) {
      assetPath = 'assets/images/solar_inverter.jpg';
    } else if (lower.contains('camera') || lower.contains('cctv') || lower.contains('surveil')) {
      assetPath = 'assets/images/cctv_banner.jpg';
    } else if (lower.contains('ac') || lower.contains('air') || lower.contains('appliance')) {
      assetPath = 'assets/images/ac_banner.jpg';
    }

    return AppImage(
      url: assetPath,
      fit: BoxFit.cover,
      errorWidget: const Center(
        child: Icon(Icons.inventory_2_outlined, color: Color(0xFF16A34A), size: 30),
      ),
    );
  }

  _BadgeInfo _getBadgeInfo(int index) {
    switch (index % 4) {
      case 0:
        return const _BadgeInfo(
          'Best Seller',
          Icons.star_rounded,
          [Color(0xFFF59E0B), Color(0xFFD97706)],
        );
      case 1:
        return const _BadgeInfo(
          'Popular',
          Icons.local_fire_department_rounded,
          [Color(0xFFEF4444), Color(0xFFDC2626)],
        );
      case 2:
        return const _BadgeInfo(
          'New Launch',
          Icons.new_releases_rounded,
          [Color(0xFF3B82F6), Color(0xFF2563EB)],
        );
      default:
        return const _BadgeInfo(
          'Premium',
          Icons.workspace_premium_rounded,
          [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        );
    }
  }

  String _formatPrice(int amount) {
    final str = amount.toString();
    if (str.length <= 3) return str;
    String result = str.substring(str.length - 3);
    int remaining = str.length - 3;
    while (remaining > 0) {
      final chunk = remaining >= 2 ? 2 : remaining;
      result = '${str.substring(remaining - chunk, remaining)},$result';
      remaining -= chunk;
    }
    return result;
  }

  List<ProductModel> _filterAndSortProducts(List<ProductModel> raw) {
    List<ProductModel> list = raw;

    // Filter by category
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      list = list.where((p) {
        final cat = p.categoryName ?? '';
        return cat.toLowerCase().contains(_selectedCategory!.toLowerCase());
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }

    // Filter under 50k
    if (_under50kFilter) {
      list = list.where((p) => (p.price ?? 0) <= 50000).toList();
    }

    // Filter by brand
    if (_selectedBrand != null) {
      list = list.where((p) => (p.brand ?? 'RightTouch') == _selectedBrand).toList();
    }

    // Sorting
    final sorted = List<ProductModel>.from(list);
    switch (_sortBy) {
      case 'price_asc':
        sorted.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
        break;
      case 'price_desc':
        sorted.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
      case 'rating':
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        break;
    }

    return sorted;
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE CARD
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 20),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We couldn\'t find any products matching your search or filters.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _resetFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.refresh, size: 16),
                SizedBox(width: 6),
                Text('Reset Filters', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DATA CLASSES
// ---------------------------------------------------------------------------
class _CategoryIconItem {
  final String label;
  final IconData icon;
  final String? matchKeyword;
  final Color? iconColor;
  final bool isAll;

  const _CategoryIconItem(
    this.label,
    this.icon,
    this.matchKeyword, {
    this.iconColor,
    this.isAll = false,
  });
}

class _BadgeInfo {
  final String label;
  final IconData icon;
  final List<Color> colors;

  const _BadgeInfo(this.label, this.icon, this.colors);
}

class _SpecItem {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _SpecItem(this.icon, this.label, this.iconColor);
}
