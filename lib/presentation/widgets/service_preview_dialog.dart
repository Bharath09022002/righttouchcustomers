import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_image.dart';
import '../../core/ui/app_feedback.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';
import 'service_share_sheet.dart';

/// Shows an interactive pop-up preview for a service when "Book Service" is tapped.
/// Displays a blurred backdrop, media preview card, highlighted price & minutes duration,
/// and quick action items including "Add to Cart".
Future<void> showServicePreview({
  required BuildContext context,
  required WidgetRef ref,
  required ServiceModel service,
}) async {
  HapticFeedback.mediumImpact();

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: const Color(0xB8000000), // ~72% black overlay
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return ServicePreviewDialog(
        service: service,
        parentRef: ref,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedValue = Curves.easeOutBack.transform(animation.value) - 1.0;
      return Transform.scale(
        scale: 1.0 + (curvedValue * 0.1),
        child: Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: child,
        ),
      );
    },
  );
}

class ServicePreviewDialog extends ConsumerStatefulWidget {
  final ServiceModel service;
  final WidgetRef parentRef;

  const ServicePreviewDialog({
    super.key,
    required this.service,
    required this.parentRef,
  });

  @override
  ConsumerState<ServicePreviewDialog> createState() =>
      _ServicePreviewDialogState();
}

class _ServicePreviewDialogState
    extends ConsumerState<ServicePreviewDialog> {
  int _quantity = 1;
  bool _isAdding = false;
  bool _isAdded = false;

  void _increment() {
    if (_quantity < 10) {
      HapticFeedback.selectionClick();
      setState(() => _quantity++);
    }
  }

  void _decrement() {
    if (_quantity > 1) {
      HapticFeedback.selectionClick();
      setState(() => _quantity--);
    }
  }

  Future<void> _handleAddToCart() async {
    if (_isAdding) return;

    if (_isAdded) {
      // Already added: direct to Cart
      Navigator.of(context).pop();
      context.push('/cart');
      return;
    }

    final auth = widget.parentRef.read(authProvider);
    if (auth.isGuest || !auth.loggedIn) {
      showError(
        context,
        title: 'Notice',
        message: 'Please sign in to complete this action.',
      );
      return;
    }

    setState(() => _isAdding = true);
    HapticFeedback.mediumImpact();

    try {
      await widget.parentRef.read(cartRepoProvider).add(
            widget.service.id,
            'service',
            _quantity,
            name: widget.service.name,
            price: widget.service.price,
            image: widget.service.image,
          );
      widget.parentRef.invalidate(cartProvider);

      if (mounted) {
        setState(() {
          _isAdding = false;
          _isAdded = true;
        });
        HapticFeedback.lightImpact();

        // Show brief in-app toast feedback
        showSuccess(
          context,
          title: 'Added to Cart',
          message:
              '${widget.service.name} (${_quantity > 1 ? "$_quantity items" : "1 item"}) added.',
          actionLabel: 'View Cart',
          onAction: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            context.push('/cart');
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAdding = false);
        final appErr = mapException(e);
        showError(
          context,
          title: 'Notice',
          message: appErr.userMessage,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final media = MediaQuery.of(context);
    final maxDialogWidth = (media.size.width - 40).clamp(280.0, 380.0);

    // Duration display
    final durationText = s.durationText?.trim().isNotEmpty == true
        ? s.durationText!
        : '${s.durationMin} mins';

    // Pricing calculation
    final unitPrice = s.price?.toInt();
    final totalPrice = unitPrice != null ? unitPrice * _quantity : null;
    final unitMrp = s.mrp?.toInt();

    return Material(
      type: MaterialType.transparency,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxDialogWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. TOP PREVIEW CARD
                  _buildMediaPreviewCard(s),

                  const SizedBox(height: 12),

                  // 2. BOTTOM FLOATING ACTION MENU
                  _buildActionMenu(
                    s: s,
                    unitPrice: unitPrice,
                    totalPrice: totalPrice,
                    unitMrp: unitMrp,
                    durationText: durationText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Top preview card
  Widget _buildMediaPreviewCard(ServiceModel s) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E232B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0x1FFFFFFF),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
            child: Row(
              children: [
                // Circular Brand Avatar with emerald ring
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF10B981), width: 1.8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.home_repair_service_rounded,
                      size: 20,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Author / Category info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              s.categoryName?.isNotEmpty == true
                                  ? s.categoryName!
                                  : 'Right Touch Services',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: Color(0xFF3897F0), // Verified blue
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 11,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            s.warranty,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Close button
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0x14FFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Service Media Container with Badges
          Stack(
            children: [
              Container(
                height: 210,
                width: double.infinity,
                color: const Color(0xFF0F172A),
                child: AppImage(
                  url: s.image,
                  fit: BoxFit.contain,
                  errorWidget: _fallbackMedia(),
                ),
              ),

              // Gradient vignette on bottom for contrast
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 60,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0xF21E232B),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Rating pill badge (top-left)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xA6000000),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 3),
                      Text(
                        s.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        ' (${s.ratingCount})',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Verified Pro indicator (bottom-right)
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x99000000),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 13, color: Color(0xFFFBBF24)),
                      SizedBox(width: 3),
                      Text(
                        'Verified Pro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Service Title & Description snippet
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                if (s.description != null && s.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    s.description!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom action menu
  Widget _buildActionMenu({
    required ServiceModel s,
    required int? unitPrice,
    required int? totalPrice,
    required int? unitMrp,
    required String durationText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF222730),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0x1FFFFFFF),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------------------------------------------------------
          // PRICE & MINS HIGHLIGHT ROW
          // ---------------------------------------------------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF1B2027),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Price section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          unitPrice != null ? '₹$unitPrice' : 'Get a Quote',
                          style: const TextStyle(
                            color: Color(0xFF22C55E), // Vivid neon emerald
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (unitMrp != null && unitPrice != null && unitMrp > unitPrice) ...[
                          const SizedBox(width: 8),
                          Text(
                            '₹$unitMrp',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Standard Service Fee',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // Minutes pill (Mins highlighted with clock icon)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF334155), width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: Color(0xFF38BDF8), // Sky blue icon
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              durationText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFF1F5F9),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0x14FFFFFF), height: 1, thickness: 1),

          // ---------------------------------------------------------
          // ADD TO CART SECTION (Quantity + Primary Action Button)
          // ---------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                // Quantity Counter (Minus / Plus)
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141920),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x1AFFFFFF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _quantity > 1 ? _decrement : null,
                        icon: const Icon(Icons.remove, size: 16),
                        color: Colors.white70,
                        disabledColor: Colors.white24,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 44),
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        onPressed: _quantity < 10 ? _increment : null,
                        icon: const Icon(Icons.add, size: 16),
                        color: Colors.white70,
                        disabledColor: Colors.white24,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 44),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Main "Add to Cart" Button
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _handleAddToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAdded
                            ? const Color(0xFF0F766E)
                            : const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isAdding
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isAdded
                                      ? Icons.check_circle_rounded
                                      : Icons.shopping_bag_outlined,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _isAdded
                                        ? 'Added! View Cart'
                                        : (totalPrice != null
                                            ? 'Add to Cart • ₹$totalPrice'
                                            : 'Add to Cart'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // ---------------------------------------------------------
          // ACTION TILES
          // ---------------------------------------------------------
          _buildActionItem(
            icon: Icons.open_in_new_rounded,
            title: 'View Details',
            subtitle: 'Specifications, FAQs & warranty',
            onTap: () {
              Navigator.of(context).pop();
              context.push('/service/${s.id}');
            },
          ),
          _buildActionItem(
            icon: Icons.near_me_outlined,
            title: 'Share Service',
            onTap: () {
              Navigator.of(context).pop();
              showServiceShareSheet(context, s);
            },
          ),
          _buildActionItem(
            icon: Icons.close_rounded,
            title: 'Dismiss',
            isDestructive: true,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Action row
  Widget _buildActionItem({
    required IconData icon,
    required String title,
    String? subtitle,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    final textColor = isDestructive ? const Color(0xFFEF4444) : Colors.white;
    final iconColor = isDestructive ? const Color(0xFFEF4444) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isDestructive)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Colors.white24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackMedia() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: const Icon(
          Icons.build_circle_outlined,
          size: 40,
          color: Color(0xFF10B981),
        ),
      ),
    );
  }
}
