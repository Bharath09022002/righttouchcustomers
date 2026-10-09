import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand.dart';
import '../providers/providers.dart';

/// Figma splash: centered brand lockup with a proper loading state
/// (pulsing sun + progress bar + tagline).
/// Navigation is defensive: any storage failure still routes somewhere,
// plus a watchdog timer guarantees we never sit on the logo forever.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _S();
}

class _S extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _go();
    // Watchdog: never strand the user on the logo.
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && !_navigated) {
        _navigated = true;
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _nav(String route) {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go(route);
  }

  Future<void> _go() async {
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted || _navigated) return;
    try {
      final store = ref.read(tokenStorageProvider);
      final onboarded =
          await store.isOnboarded().catchError((_) => true);
      await store.loadCache();
      if (!mounted || _navigated) return;
      if (!onboarded) {
        _nav('/onboarding');
      } else if (store.cachedToken?.isNotEmpty == true) {
        // Logged in; enter home immediately (main.dart bootstraps profile)
        _nav('/');
      } else {
        _nav('/login');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Splash] nav failed: $e');
      _nav('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Image1: pure white, tiny centered lockup — no tagline, no big loader.
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: Tween(begin: 0.96, end: 1.04).animate(
                CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
              ),
              child: const BrandLogo(width: 200),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 90,
              child: LinearProgressIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.primarySoft,
                minHeight: 3,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
