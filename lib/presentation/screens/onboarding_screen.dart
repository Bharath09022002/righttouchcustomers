import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/providers.dart';

/// Figma walkthrough: full-bleed photo, bottom white card with
/// "Let's Get Started", Skip + green Next actions.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _S();
}

class _S extends ConsumerState<OnboardingScreen> {
  final _pages = const [
    (
      img:
          'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=800&q=70',
      icon: Icons.content_cut,
      text:
          'Book trusted barbers & grooming experts at your doorstep, anytime you need them.',
    ),
    (
      img:
          'https://images.unsplash.com/photo-1626806787461-102c1bfaaea1?auto=format&fit=crop&w=800&q=70',
      icon: Icons.local_laundry_service_outlined,
      text:
          'Appliance repair & home cleaning with upfront pricing and verified professionals.',
    ),
    (
      img:
          'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?auto=format&fit=crop&w=800&q=70',
      icon: Icons.plumbing_outlined,
      text:
          'Plumbing, electrical & more — background-verified pros with service warranty.',
    ),
  ];

  final _ctrl = PageController();

  Future<void> _finish() async {
    await ref.read(tokenStorageProvider).setOnboarded();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView.builder(
        controller: _ctrl,
        itemCount: _pages.length,
        itemBuilder: (_, i) {
          final p = _pages[i];
          final last = i == _pages.length - 1;
          return Stack(children: [
            Positioned.fill(
              child: AppImage(
                url: p.img,
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x55000000)],
                    stops: [0.5, 1.0],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      for (int d = 0; d < _pages.length; d++)
                        Expanded(
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: d == i
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(0),
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(p.icon,
                              color: AppColors.primary, size: 26),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text("Let's Get Started",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w900)),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Text(p.text,
                          style: const TextStyle(
                              color: AppColors.grey600,
                              fontSize: 13,
                              height: 1.5)),
                      const SizedBox(height: 18),
                      Row(children: [
                        TextButton(
                          onPressed: _finish,
                          child: const Text('Skip',
                              style: TextStyle(
                                  color: AppColors.grey400,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 130,
                          child: AppButton(
                            label: last ? "Let's Go" : 'Next →',
                            onPressed: () {
                              if (last) {
                                _finish();
                              } else {
                                _ctrl.nextPage(
                                  duration:
                                      const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              }
                            },
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
