import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/products/products_screen.dart';
import '../screens/services/services_screen.dart';
import '../screens/profile/profile_screen.dart';

import '../providers/providers.dart';

/// 4-tab bottom navigation matching RightTouch website and mobile UI
class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _index(BuildContext ctx) {
    final loc = GoRouterState.of(ctx).matchedLocation;
    if (loc.startsWith('/products')) return 1;
    if (loc.startsWith('/services')) return 2;
    if (loc.startsWith('/profile') || loc.startsWith('/account')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = _index(context);
    final cartCount = ref.watch(cartProvider).maybeWhen(
          data: (items) => items.fold<int>(0, (sum, it) => sum + it.qty),
          orElse: () => 0,
        );

    return Scaffold(
      body: child,
      floatingActionButton: (i == 1)
          ? FloatingActionButton(
        onPressed: () => context.push('/cart'),
        backgroundColor: const Color(0xFF059669),
        elevation: 6,
        shape: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 26),
            if (cartCount > 0)
              Positioned(
                right: -6,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF047857),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
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
      ) : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _tab(context, 0, i, Icons.home_outlined, Icons.home, 'Home'),
                _tab(context, 1, i, Icons.shopping_bag_outlined, Icons.shopping_bag, 'Products'),
                _tab(context, 2, i, Icons.build_outlined, Icons.build, 'Services'),
                _tab(context, 3, i, Icons.person_outline, Icons.person, 'Account'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    int idx,
    int cur,
    IconData icon,
    IconData active,
    String label,
  ) {
    final sel = idx == cur;
    return Expanded(
      child: InkWell(
        onTap: () {
          switch (idx) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/products');
              break;
            case 2:
              context.go('/services');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFFE8FAF2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  sel ? active : icon,
                  color: sel ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                  color: sel ? const Color(0xFF059669) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Aliases used by the router for tab roots.
class HomeTabPlaceholder extends StatelessWidget {
  const HomeTabPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const HomeScreen();
}

class ProductsTabPlaceholder extends StatelessWidget {
  const ProductsTabPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const ProductsScreen();
}

class ServicesTabPlaceholder extends StatelessWidget {
  const ServicesTabPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const ServicesScreen();
}

class ProfileTabPlaceholder extends StatelessWidget {
  const ProfileTabPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const ProfileScreen();
}
