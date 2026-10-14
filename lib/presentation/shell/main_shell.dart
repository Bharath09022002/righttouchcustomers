import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/products/products_screen.dart';
import '../screens/products/product_quotations_screen.dart';
import '../screens/services/services_screen.dart';
import '../screens/booking/bookings_screen.dart';
import '../screens/profile/profile_screen.dart';

/// Floating capsule bottom navigation matching exact design:
/// - Pure white rounded container with soft shadow
/// - Selected tab has filled teal-emerald squircle with white icon + label
/// - Inactive tabs have clean outline icon + label
/// - Includes 5 core tabs: Home, Services, Product, Bookings, Profile
class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _index(BuildContext ctx) {
    final loc = GoRouterState.of(ctx).matchedLocation;
    if (loc.startsWith('/services')) return 1;
    if (loc.startsWith('/product') || loc.startsWith('/quotation')) return 2;
    if (loc.startsWith('/bookings') || loc.startsWith('/book')) return 3;
    if (loc.startsWith('/profile') || loc.startsWith('/account')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = _index(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 20,
                spreadRadius: 1,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _tab(context, 0, i, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _tab(context, 1, i, Icons.build_circle_outlined, Icons.build_circle_rounded, 'Services'),
              _tab(context, 2, i, Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Product'),
              _tab(context, 3, i, Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Bookings'),
              _tab(context, 4, i, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
            ],
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
    IconData activeIcon,
    String label,
  ) {
    final sel = idx == cur;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (sel) return; // Prevent duplicate rapid taps on active tab
          HapticFeedback.selectionClick();
          switch (idx) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/services');
              break;
            case 2:
              context.go('/product');
              break;
            case 3:
              context.go('/bookings');
              break;
            case 4:
              context.go('/profile');
              break;
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: sel ? const Color(0xFF16A34A) : Colors.transparent,
            boxShadow: sel
                ? const [
                    BoxShadow(
                      color: Color(0x3816A34A),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                sel ? activeIcon : icon,
                color: sel ? Colors.white : const Color(0xFF64748B),
                size: 21,
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? Colors.white : const Color(0xFF64748B),
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

// Aliases used by the router for tab roots.
class HomeTabPlaceholder extends StatelessWidget {
  const HomeTabPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const HomeScreen();
}

class ProductTabPlaceholder extends StatelessWidget {
  const ProductTabPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const ProductQuotationsScreen();
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

class BookingsTabPlaceholder extends StatelessWidget {
  const BookingsTabPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const BookingsScreen();
}

class ProfileTabPlaceholder extends StatelessWidget {
  const ProfileTabPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const ProfileScreen();
}
