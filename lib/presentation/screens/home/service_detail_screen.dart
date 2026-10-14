import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/service_share_sheet.dart';
import '../../providers/providers.dart';

class ServiceDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ServiceDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollProgress = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // Over the first 140px of scrolling, transition top bar from 0.0 (transparent) to 1.0 (solid white)
    final offset = _scrollController.offset;
    final progress = (offset / 140.0).clamp(0.0, 1.0);
    if (_scrollProgress.value != progress) {
      _scrollProgress.value = progress;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(serviceDetailProvider(widget.id));
    final cartCount = ref.watch(cartProvider).maybeWhen(
          data: (items) => items.fold<int>(0, (sum, it) => sum + it.qty),
          orElse: () => 0,
        );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: d.when(
        data: (s) => Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // 1. SCROLLABLE CONTENT: Extends behind the status bar so words and media scroll smoothly UNDER the top bar
              SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Space for floating top bar so back/share/cart buttons sit above the hero image at rest
                    SizedBox(height: MediaQuery.of(context).padding.top + 56),

                    // Hero Banner Image (Telegram-style media view)
                    if (s.image != null && s.image!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        height: 270,
                        color: const Color(0xFFF8FAFC),
                        child: AppImage(
                          url: s.image,
                          width: double.infinity,
                          height: 270,
                          fit: BoxFit.contain,
                        ),
                      ),

                  // Service Information & Details
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (s.rating > 0) ...[
                              RatingStars(value: s.rating, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${s.rating.toStringAsFixed(1)} (${s.ratingCount})',
                                style: const TextStyle(
                                  color: AppColors.grey600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Text(
                              '${s.durationMin} mins • ${s.categoryName ?? 'Service'}',
                              style: const TextStyle(
                                color: AppColors.grey600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        PriceTag(price: s.price, mrp: s.mrp),
                        if (s.description != null && s.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 18),
                          const Text(
                            'About this service',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.description!,
                            style: const TextStyle(
                              color: AppColors.grey600,
                              height: 1.5,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        if (s.warranty.isNotEmpty && s.warranty != 'Service Warranty') ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primaryBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_user_outlined, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    s.warranty,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. TELEGRAM-STYLE FLOATING TOP BAR: Content and words scroll smoothly underneath
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<double>(
                valueListenable: _scrollProgress,
                builder: (context, progress, _) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: progress),
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFFE2E8F0).withValues(alpha: progress),
                          width: 1,
                        ),
                      ),
                      boxShadow: progress > 0.08
                          ? [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.06 * progress),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 6,
                      bottom: 8,
                      left: 14,
                      right: 14,
                    ),
                    child: Row(
                      children: [
                        // Telegram-Style Circular Back Button
                        _buildCircleButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              context.go('/');
                            }
                          },
                        ),

                        const SizedBox(width: 10),

                        // Title in top bar: Fades in only as user swipes/scrolls past the hero
                        Expanded(
                          child: Opacity(
                            opacity: progress,
                            child: Text(
                              s.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Telegram-Style Circular Share Button
                        _buildCircleButton(
                          icon: Icons.share_outlined,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            showServiceShareSheet(context, s);
                          },
                        ),

                        const SizedBox(width: 8),

                        // Telegram-Style Circular Cart Button with Badge
                        _buildCartButton(cartCount: cartCount),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.grey200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Add to cart',
                    outlined: true,
                    onPressed: () async {
                      try {
                        await ref.read(cartRepoProvider).add(s.id, 'service', 1);
                        ref.invalidate(cartProvider);
                        if (context.mounted) {
                          showSuccess(
                            context,
                            title: 'Added to cart',
                            message: '${s.name} added to cart.',
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
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Book now',
                    onPressed: () => context.push('/book/${s.id}'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      loading: () => const Scaffold(
        body: Center(child: RtLoader()),
      ),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: ErrorView(
            message: '$e',
            onRetry: () => ref.invalidate(serviceDetailProvider(widget.id)),
          ),
        ),
      ),
    );
  }

  /// Telegram-style circular action button
  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 40,
    double iconSize = 20,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, color: const Color(0xFF0F172A), size: iconSize),
          ),
        ),
      ),
    );
  }

  /// Telegram-style circular cart button with count badge
  Widget _buildCartButton({required int cartCount}) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/cart');
        },
        customBorder: const CircleBorder(),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0F172A), size: 20),
              if (cartCount > 0)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Color(0x3316A34A), blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
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

