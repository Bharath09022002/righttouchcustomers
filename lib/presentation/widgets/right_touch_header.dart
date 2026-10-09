import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';

class RightTouchTopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool showSearch;
  final VoidCallback? onSearchTap;

  const RightTouchTopAppBar({
    super.key,
    this.showSearch = true,
    this.onSearchTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final cartCount = ref.watch(cartProvider).maybeWhen(
          data: (items) => items.fold<int>(0, (sum, it) => sum + it.qty),
          orElse: () => 0,
        );

    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        bottom: 8,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          // Logo & Brand Name
          Expanded(
            child: InkWell(
              onTap: () => context.go('/'),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLogoIcon(),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'sans-serif',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          children: [
                            const TextSpan(
                              text: 'RICHT ',
                              style: TextStyle(color: Color(0xFF059669)),
                            ),
                            TextSpan(
                              text: 'TOUCH',
                              style: TextStyle(color: iconColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Notifications Bell
          InkWell(
            onTap: () => context.push('/notifications'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.notifications_outlined,
                color: iconColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Shopping Cart with Green Badge
          InkWell(
            onTap: () => context.push('/cart'),
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 4,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
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
        ],
      ),
    );
  }

  Widget _buildLogoIcon() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: const [
            Icon(Icons.wb_sunny_outlined, size: 20, color: Color(0xFFD97706)),
            Icon(Icons.eco, size: 12, color: Color(0xFF059669)),
          ],
        ),
      ),
    );
  }
}
