import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../providers/providers.dart';

/// Telegram-inspired top app bar with:
/// - Perfectly centered Right Touch logo housed in an elongated stadium pill capsule
/// - Circular action button on the left (Back if route can pop, or quick Menu / custom action)
/// - Telegram-style circular buttons on the right (Notifications & Shopping Cart with badges)
class RightTouchTopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool? isHome;
  final String? title;
  final bool showSearch;
  final VoidCallback? onSearchTap;
  final Widget? leading;
  final VoidCallback? onLeadingTap;
  final IconData? leadingIcon;
  final bool showLeading;
  final PreferredSizeWidget? bottom;
  final List<Widget>? extraActions;

  const RightTouchTopAppBar({
    super.key,
    this.isHome,
    this.title,
    this.showSearch = true,
    this.onSearchTap,
    this.leading,
    this.onLeadingTap,
    this.leadingIcon,
    this.showLeading = true,
    this.bottom,
    this.extraActions,
  });

  @override
  Size get preferredSize => Size.fromHeight(60.0 + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? location;
    try {
      location = GoRouterState.of(context).matchedLocation;
    } catch (_) {
      location = null;
    }
    final effectiveIsHome = isHome ?? (location == '/');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final actionButtonBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final actionButtonBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final cartCount = ref.watch(cartProvider).maybeWhen(
          data: (items) => items.fold<int>(0, (sum, it) => sum + it.qty),
          orElse: () => 0,
        );
    final unreadCount = ref.watch(unreadNotificationCountProvider).maybeWhen(
          data: (count) => count,
          orElse: () => 0,
        );

    bool canPop = false;
    try {
      canPop = context.canPop();
    } catch (_) {
      canPop = Navigator.of(context).canPop();
    }

    // Determine displayed brand/page name:
    // On home: 'Right Touch'
    // On other pages: the page name (title)
    final String displayName;
    if (effectiveIsHome) {
      displayName = 'Right Touch';
    } else if (title != null && title!.trim().isNotEmpty) {
      displayName = title!.trim();
    } else {
      displayName = 'Right Touch';
    }

    final topPadding = MediaQuery.of(context).padding.top;

    final overlayStyle = isDark
        ? const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: Color(0xFF0F172A),
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Container(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
      padding: EdgeInsets.only(
        top: topPadding + 6,
        bottom: bottom != null ? 0 : 6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button if canPop or leading specified
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 8),
                  ] else if (canPop) ...[
                    _buildCircleButton(
                      icon: Icons.arrow_back_rounded,
                      iconColor: iconColor,
                      buttonBg: actionButtonBg,
                      buttonBorder: actionButtonBorder,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (onLeadingTap != null) {
                          onLeadingTap!();
                        } else {
                          try {
                            if (context.canPop()) {
                              context.pop();
                              return;
                            }
                          } catch (_) {}
                          Navigator.of(context).maybePop();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                  ],

                  // LEFT: Brand capsule with logo icon and page name in green
                  Flexible(
                    child: _buildBrandCapsule(
                      context,
                      isDark: isDark,
                      displayName: displayName,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // RIGHT: Search & Cart buttons
                  _buildRightButtons(
                    context,
                    iconColor: iconColor,
                    buttonBg: actionButtonBg,
                    buttonBorder: actionButtonBorder,
                    cartCount: cartCount,
                    unreadCount: unreadCount,
                  ),
                ],
              ),
            ),
          ),
          if (bottom != null) ...[
            const SizedBox(height: 2),
            bottom!,
          ],
        ],
      ),
    ),
  );
}

  /// Stadium pill capsule on the left containing the logo icon and name in brand green
  Widget _buildBrandCapsule(
    BuildContext context, {
    required bool isDark,
    required String displayName,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.go('/');
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo_icon.png',
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.lightbulb_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Right action buttons helper
  Widget _buildRightButtons(
    BuildContext context, {
    required Color iconColor,
    required Color buttonBg,
    required Color buttonBorder,
    required int cartCount,
    required int unreadCount,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (extraActions != null) ...[
          ...extraActions!,
          const SizedBox(width: 8),
        ],
        if (showSearch) ...[
          _buildCircleButton(
            icon: Icons.search_rounded,
            iconColor: iconColor,
            buttonBg: buttonBg,
            buttonBorder: buttonBorder,
            onTap: () {
              HapticFeedback.lightImpact();
              if (onSearchTap != null) {
                onSearchTap!();
              } else {
                context.push('/search');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        _buildCartCircleButton(
          iconColor: iconColor,
          buttonBg: buttonBg,
          buttonBorder: buttonBorder,
          cartCount: cartCount,
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/cart');
          },
        ),
      ],
    );
  }

  /// Telegram-style circular icon button
  Widget _buildCircleButton({
    required IconData icon,
    required Color iconColor,
    required Color buttonBg,
    required Color buttonBorder,
    required VoidCallback onTap,
    bool hasBadge = false,
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
            color: buttonBg,
            shape: BoxShape.circle,
            border: Border.all(color: buttonBorder, width: 1.1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: iconColor, size: iconSize),
              if (hasBadge)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Telegram-style circular cart button with count badge
  Widget _buildCartCircleButton({
    required Color iconColor,
    required Color buttonBg,
    required Color buttonBorder,
    required int cartCount,
    required VoidCallback onTap,
    double size = 40,
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
            color: buttonBg,
            shape: BoxShape.circle,
            border: Border.all(color: buttonBorder, width: 1.1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                color: iconColor,
                size: 20,
              ),
              if (cartCount > 0)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3316A34A),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
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

