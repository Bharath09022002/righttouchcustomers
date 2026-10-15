import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../widgets/right_touch_header.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/models/models.dart';
import '../../../widgets/skeleton.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final productsAsync = ref.watch(productListProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const RightTouchTopAppBar(isHome: true),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(categoryListProvider);
          ref.invalidate(serviceListProvider);
          ref.invalidate(productListProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // 1. DELIVER TO ADDRESS ROW
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: () => context.push('/addresses'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF16A34A),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Deliver to',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                selectedAddress?.line.isNotEmpty == true
                                    ? selectedAddress!.line
                                    : 'Select delivery address',
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. HERO DEMAND BANNER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildHeroCard(context),
              ),

              const SizedBox(height: 24),

              // 4. "OUR HOME SERVICES" SECTION HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'sans-serif',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                          children: [
                            TextSpan(
                              text: 'Our ',
                              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                            const TextSpan(
                              text: 'Home Services',
                              style: TextStyle(color: Color(0xFF16A34A)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => context.go('/services'),
                      child: Row(
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
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF16A34A),
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 5. 4x2 HOME SERVICES GRID
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildServicesGrid(context, categoriesAsync, isDark),
              ),

              const SizedBox(height: 22),

              // 5b. FEATURED PRODUCTS (HORIZONTAL LIST, MAX 6-8)
              _buildHomeProductsSection(context, productsAsync, isDark),

              const SizedBox(height: 20),

              // 6. PROMOTIONAL BANNER: FLAT 20% OFF ON AC SERVICE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildPromoBanner(context),
              ),

              const SizedBox(height: 24),

              // 7. WHY CHOOSE RICHT TOUCH?
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                        children: [
                          TextSpan(
                            text: 'Why Choose ',
                            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                          const TextSpan(
                            text: 'RightTouch?',
                            style: TextStyle(color: Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildWhyChooseUsRow(isDark),
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
  // HERO BANNER CARD
  // ---------------------------------------------------------------------------
  Widget _buildHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF061A1D), Color(0xFF0A2B27)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pill: Trusted by 50K+ customers
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.star, color: Color(0xFFFBBF24), size: 13),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Trusted by 50K+ customers',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Headline + Subtitle
                // Top Section: Headline + Subtitle on left, Technician on right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: 'sans-serif',
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Home ',
                                  style: TextStyle(color: Colors.white),
                                ),
                                TextSpan(
                                  text: 'Repair ',
                                  style: TextStyle(color: Color(0xFF22C55E)),
                                ),
                                TextSpan(
                                  text: '&\n',
                                  style: TextStyle(color: Colors.white),
                                ),
                                TextSpan(
                                  text: 'Services ',
                                  style: TextStyle(color: Color(0xFF22C55E)),
                                ),
                                TextSpan(
                                  text: 'On\nDemand',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Expert technicians for AC, appliances, plumbing & more. Book in minutes — get peace of mind.',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Technician Illustration (lightly bigger)
                    Expanded(
                      flex: 4,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: const AppImage(
                          url: 'assets/images/technician_hero.jpg',
                          height: 170,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // CTAs: Book Now -> and Explore Services side by side on the left (No overflow)
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    InkWell(
                      onTap: () => context.go('/services'),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Book Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => context.go('/services'),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: const Text(
                          'Explore Services',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Stats Footer Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _heroStatItem(
                          icon: Icons.groups_outlined,
                          value: '50K+',
                          label: 'Happy Customers',
                        ),
                      ),
                      Container(width: 1, height: 26, color: Colors.white.withValues(alpha: 0.1)),
                      Expanded(
                        child: _heroStatItem(
                          icon: Icons.star_rate_rounded,
                          value: '4.9★',
                          label: 'Avg. Rating',
                        ),
                      ),
                      Container(width: 1, height: 26, color: Colors.white.withValues(alpha: 0.1)),
                      Expanded(
                        child: _heroStatItem(
                          icon: Icons.bolt_rounded,
                          value: '2hr',
                          label: 'Response Time',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF16A34A),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4x2 SERVICES GRID
  // ---------------------------------------------------------------------------
  Widget _buildServicesGrid(
    BuildContext context,
    AsyncValue<List<CategoryModel>> categoriesAsync,
    bool isDark,
  ) {
    final services = [
      _HomeServiceItem(
        title: 'AC Service\n& Repair',
        icon: Icons.ac_unit_rounded,
        categoryIdMatch: 'air',
      ),
      _HomeServiceItem(
        title: 'Appliance\nRepair',
        icon: Icons.local_laundry_service_outlined,
        categoryIdMatch: 'appliance',
      ),
      _HomeServiceItem(
        title: 'Plumbing\nServices',
        icon: Icons.water_drop_outlined,
        categoryIdMatch: 'plumb',
      ),
      _HomeServiceItem(
        title: 'Electrical\nServices',
        icon: Icons.bolt_outlined,
        categoryIdMatch: 'electr',
      ),
      _HomeServiceItem(
        title: 'Solar\nServices',
        icon: Icons.solar_power_outlined,
        categoryIdMatch: 'solar',
      ),
      _HomeServiceItem(
        title: 'Security &\nSurveillance',
        icon: Icons.shield_outlined,
        categoryIdMatch: 'surveil',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final item = services[index];
        return InkWell(
          onTap: () {
            final cats = categoriesAsync.valueOrNull ?? [];
            final matched = cats.firstWhere(
              (c) => c.name.toLowerCase().contains(item.categoryIdMatch),
              orElse: () => CategoryModel(id: '', name: item.title.replaceAll('\n', ' ')),
            );
            if (matched.id.isNotEmpty) {
              context.go('/services?category=${Uri.encodeComponent(matched.name)}');
            } else {
              context.go('/services');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                )
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  color: const Color(0xFF16A34A),
                  size: 24,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // PROMO BANNER: FLAT 20% OFF ON AC SERVICE
  // ---------------------------------------------------------------------------
  Widget _buildPromoBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE2F9EE), Color(0xFFD1FAE5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA7F3D0).withValues(alpha: 0.6)),
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: 'sans-serif',
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                          children: [
                            TextSpan(
                              text: 'Flat ',
                              style: TextStyle(fontSize: 19, color: Color(0xFF0F172A)),
                            ),
                            TextSpan(
                              text: '20% OFF\n',
                              style: TextStyle(fontSize: 20, color: Color(0xFF16A34A)),
                            ),
                            TextSpan(
                              text: 'On AC Service',
                              style: TextStyle(fontSize: 16, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Stay cool this season',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => context.go('/services'),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Book Now',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: const AppImage(
                    url: 'assets/images/ac_banner.jpg',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WHY CHOOSE RICHT TOUCH? ROW
  // ---------------------------------------------------------------------------
  Widget _buildWhyChooseUsRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _trustChip(
            icon: Icons.verified_rounded,
            title: 'Verified\nTechnicians',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _trustChip(
            icon: Icons.verified_user_rounded,
            title: 'Quality\nService',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _trustChip(
            icon: Icons.currency_rupee_rounded,
            title: 'Transparent\nPricing',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _trustChip({
    required IconData icon,
    required String title,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF16A34A), size: 14),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FEATURED PRODUCTS SECTION (MAX 6-8, HORIZONTAL LIST)
  // ---------------------------------------------------------------------------
  Widget _buildHomeProductsSection(
    BuildContext context,
    AsyncValue<List<ProductModel>> productsAsync,
    bool isDark,
  ) {
    return productsAsync.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Skeleton(width: 140, height: 22, borderRadius: 6),
                Skeleton(width: 60, height: 18, borderRadius: 6),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 224,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const Skeleton(
                width: 156,
                height: 224,
                borderRadius: 16,
              ),
            ),
          ),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        final displayProducts = products.take(8).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                        children: [
                          TextSpan(
                            text: 'Featured ',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const TextSpan(
                            text: 'Products',
                            style: TextStyle(color: Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => context.go('/products'),
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
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF16A34A),
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 236,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: displayProducts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final p = displayProducts[index];
                  return _buildHomeProductCard(context, p, isDark);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHomeProductCard(BuildContext context, ProductModel p, bool isDark) {
    final hasPrice = p.price != null && p.price! > 0 && !p.quoteRequired;

    return Semantics(
      button: true,
      label: 'Product: ${p.name}',
      child: InkWell(
        onTap: () => context.push('/product/${p.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 156,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image with rounded top
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Container(
                  height: 105,
                  width: double.infinity,
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  child: AppImage(
                    url: p.image,
                    height: 105,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: Center(
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),

              // Info Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.brand != null && p.brand!.isNotEmpty)
                            Text(
                              p.brand!.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            p.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      // Price or Request Quote Badge
                      if (!hasPrice)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: const Text(
                            'Request quote',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        )
                      else
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹${p.price!.toInt()}',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              if (p.mrp != null && p.mrp! > p.price!) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '₹${p.mrp!.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    decoration: TextDecoration.lineThrough,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeServiceItem {
  final String title;
  final IconData icon;
  final String categoryIdMatch;

  const _HomeServiceItem({
    required this.title,
    required this.icon,
    required this.categoryIdMatch,
  });
}
