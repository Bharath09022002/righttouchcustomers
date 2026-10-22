import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/ui/app_feedback.dart';
import '../../providers/providers.dart';

/// Passwordless customer auth screen matching the exact reference design:
/// - Brand logo with lightbulb hand click & 'RIGHT TOUCH'
/// - 'Welcome to Right Touch' heading
/// - Segmented Login / Sign up toggle with active underline indicator
/// - Fully swipeable PageView between Login and Sign up / Register
/// - Mobile number field with 🇮🇳 +91, dropdown chevron, and green border
/// - 'Your number is safe with us. We'll send a 4-digit OTP.' security badge
/// - Vibrant green 'Continue with OTP' button with dark circle forward arrow
/// - 'OR' divider
/// - 'Explore as Guest' button with compass icon
/// - Terms & Privacy Policy agreement footer with green links
class LoginScreen extends ConsumerStatefulWidget {
  final bool initialSignup;
  const LoginScreen({super.key, this.initialSignup = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late int _currentPage;
  late final PageController _pageController;
  late final TextEditingController _ctrl;
  final FocusNode _focusNode = FocusNode();
  String? _err;
  bool _busy = false;

  bool get _isSignup => _currentPage == 1;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialSignup ? 1 : 0;
    _pageController = PageController(initialPage: _currentPage);
    _ctrl = TextEditingController(text: ref.read(authProvider).mobile ?? '');
    _focusNode.addListener(() {
      setState(() {});
    });
    if (widget.initialSignup) {
      Future.microtask(
        () => ref.read(authProvider.notifier).setMode(AuthMode.signup),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _ctrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentPage == index) return;
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentPage = index;
      _err = null;
    });
    ref
        .read(authProvider.notifier)
        .setMode(_isSignup ? AuthMode.signup : AuthMode.login);
  }

  Future<void> _send() async {
    HapticFeedback.lightImpact();
    final m = normalizeIndianMobile(_ctrl.text);
    if (!isValidIndianMobile(m)) {
      setState(() => _err = 'Enter a valid 10-digit mobile number');
      return;
    }

    setState(() {
      _err = null;
      _busy = true;
    });

    final e = await ref.read(authProvider.notifier).requestOtp(
          m,
          mode: _isSignup ? AuthMode.signup : AuthMode.login,
        );
    if (!mounted) return;
    setState(() => _busy = false);

    if (e != null) {
      final low = e.toLowerCase();
      if (low.contains('already registered') || low.contains('already exist')) {
        _onTabSelected(0);
        showError(
          context,
          title: 'Already Registered',
          message:
              'This mobile number is already registered. Please proceed to Login.',
          actionLabel: 'Go to Login',
          onAction: () => _onTabSelected(0),
        );
      } else if (low.contains('signup first') ||
          low.contains('not found') ||
          low.contains('not registered')) {
        _onTabSelected(1);
        showError(
          context,
          title: 'New Account',
          message:
              'Number is not registered yet. Switched to Sign up — continue to create your account.',
        );
      } else {
        final appErr = mapException(e);
        showError(
          context,
          title: 'Failed to Send OTP',
          message: appErr.userMessage,
        );
      }
    } else {
      context.push('/otp');
      showSuccess(
        context,
        title: 'OTP Sent',
        message: _isSignup
            ? 'Account OTP sent to +91 $m (valid 5 min)'
            : 'Login OTP sent to +91 $m (valid 5 min)',
      );
    }
  }

  void _exploreAsGuest() {
    HapticFeedback.lightImpact();
    ref.read(authProvider.notifier).continueAsGuest();
    context.go('/');
    showSuccess(
      context,
      title: 'Welcome to Right Touch',
      message: 'Browsing as Guest. You can log in anytime from Profile.',
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terms & Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'By using Right Touch services, you agree to comply with our service standards, respectful communication with technicians, and platform booking guidelines.\n\nYour personal data and phone numbers are encrypted, confidential, and used strictly for dispatching verified technicians and order status updates.',
            style: TextStyle(fontSize: 13, height: 1.45),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Background organic wave graphics matching reference
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _LoginBackgroundWavePainter(),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 14),

                        const SizedBox(height: 10),

                        // 1. BRAND LOGO (Standalone emblem directly on background)
                        Center(
                          child: Image.asset(
                            'assets/images/logo_icon.png',
                            height: 108,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const BrandLogo(width: 150),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // 2. BRAND NAME: RIGHT TOUCH
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'RIGHT ',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'TOUCH',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: Color(0xFF00A859),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _isSignup
                                ? 'Create an account to get started'
                                : 'Sign in to continue to your account',
                            key: ValueKey<bool>(_isSignup),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // 3. SEGMENTED TOGGLE (Login | Sign up) - Swipeable toggle
                        Builder(
                          builder: (context) {
                            double dragDistance = 0;
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragStart: (_) => dragDistance = 0,
                              onHorizontalDragUpdate: (details) =>
                                  dragDistance += details.primaryDelta ?? 0,
                              onHorizontalDragEnd: (details) {
                                final velocity = details.primaryVelocity ?? 0;
                                if (velocity < -80 || dragDistance < -30) {
                                  _onTabSelected(1);
                                } else if (velocity > 80 || dragDistance > 30) {
                                  _onTabSelected(0);
                                }
                              },
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9).withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.6)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildSegmentTab(
                                        label: 'Login',
                                        icon: Icons.person_rounded,
                                        isSelected: !_isSignup,
                                        onTap: () => _onTabSelected(0),
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildSegmentTab(
                                        label: 'Sign up',
                                        icon: Icons.person_add_alt_1_rounded,
                                        isSelected: _isSignup,
                                        onTap: () => _onTabSelected(1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // 4. SWIPEABLE LOGIN / REGISTER FORM CARD
                        SizedBox(
                          height: 380,
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: _onPageChanged,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildFormCard(isSignup: false),
                              _buildFormCard(isSignup: true),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 5. TERMS & PRIVACY FOOTER (Fixed)
                        _buildFooter(),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Inner swipeable card content for either Login (index 0) or Sign up (index 1)
  Widget _buildFormCard({required bool isSignup}) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

              // 4. MOBILE NUMBER INPUT
              const Text(
                'Mobile number',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),

              // Input Container with Green Accent Outline
              Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF10B981),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Flag icon
                    const Text(
                      '🇮🇳',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '+91',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Color(0xFF0F172A),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 1.2,
                      height: 24,
                      color: const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        focusNode: isSignup ? null : _focusNode,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        onChanged: (_) {
                          if (_err != null) {
                            setState(() => _err = null);
                          } else {
                            setState(() {});
                          }
                        },
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter 10-digit number',
                          hintStyle: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_err != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFF87171), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Color(0xFFDC2626), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _err!,
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // 6. PRIMARY 'CONTINUE WITH OTP' ACTION BUTTON (Matching screenshot)
              _ContinueWithOtpButton(
                isLoading: _busy,
                onPressed: _send,
              ),

              const SizedBox(height: 22),

              // 7. OR DIVIDER
              Row(
                children: const [
                  Expanded(
                    child: Divider(
                      color: Color(0xFFE2E8F0),
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Color(0xFFE2E8F0),
                      thickness: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 8. EXPLORE AS GUEST BUTTON
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: _exploreAsGuest,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 1.4,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.explore_outlined,
                              size: 22,
                              color: Color(0xFF0F172A),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Explore as Guest',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
    );
  }

  /// Terms & Privacy policy footer
  Widget _buildFooter() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'By continuing, you agree to our',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GestureDetector(
                onTap: _showTermsDialog,
                child: const Text(
                  'Terms',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF00A859),
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF00A859),
                  ),
                ),
              ),
              const Text(
                ' & ',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: _showTermsDialog,
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF00A859),
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF00A859),
                  ),
                ),
              ),
              const Text(
                '.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Segmented Tab Button with white card, icon, and emerald green text
  Widget _buildSegmentTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFF00A859) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF00A859)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Primary button exactly matching the user's design:
/// - Vibrant green background
/// - Dark green circular button on the left with forward arrow icon
/// - Bold 'Continue with OTP' text
/// - Supports both direct tap and interactive swipe-to-continue
class _ContinueWithOtpButton extends StatefulWidget {
  final bool isLoading;
  final Future<void> Function() onPressed;

  const _ContinueWithOtpButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_ContinueWithOtpButton> createState() => _ContinueWithOtpButtonState();
}

class _ContinueWithOtpButtonState extends State<_ContinueWithOtpButton>
    with SingleTickerProviderStateMixin {
  double _dragProgress = 0.0;
  late final AnimationController _animController;
  Animation<double>? _resetAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(() {
        if (_resetAnim != null) {
          setState(() {
            _dragProgress = _resetAnim!.value;
          });
        }
      });
  }

  @override
  void didUpdateWidget(covariant _ContinueWithOtpButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading) {
      _resetSlider();
    }
  }

  void _resetSlider() {
    if (!mounted) return;
    _resetAnim = Tween<double>(begin: _dragProgress, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward(from: 0.0);
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (widget.isLoading) return;
    setState(() {
      _dragProgress =
          (_dragProgress + (details.primaryDelta ?? 0) / maxDrag).clamp(0.0, 1.0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (widget.isLoading) return;
    if (_dragProgress >= 0.65) {
      _handleAction();
    } else {
      _resetSlider();
    }
  }

  void _handleTap() {
    if (widget.isLoading) return;
    _handleAction();
  }

  Future<void> _handleAction() async {
    HapticFeedback.mediumImpact();
    await widget.onPressed();
    if (mounted && !widget.isLoading) {
      _resetSlider();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const totalHeight = 56.0;
    const circleSize = 42.0;
    const padding = 7.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final maxDragDistance = totalWidth - circleSize - (padding * 2);
        final currentLeft = padding + (_dragProgress * maxDragDistance);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: totalHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF00A859), // Right Touch Brand Green
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3300A859),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center Text Label
                  Center(
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Continue with OTP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                  ),

                  // Left Dark Circle with Forward Arrow (Can be dragged or tapped)
                  if (!widget.isLoading)
                    Positioned(
                      left: currentLeft,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) =>
                            _onDragUpdate(details, maxDragDistance),
                        onHorizontalDragEnd: _onDragEnd,
                        child: Container(
                          width: circleSize,
                          height: circleSize,
                          decoration: const BoxDecoration(
                            color: Color(0xFF006C38), // Darker Forest Green Circle
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x2A000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                              color: Colors.white,
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
      },
    );
  }
}

/// Custom painter for the organic soft mint waves at top and bottom of auth screen
class _LoginBackgroundWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top-left subtle mint aura
    final topAura = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.8, -0.9),
        radius: 1.1,
        colors: [
          const Color(0xFFDCFCE7).withValues(alpha: 0.7),
          const Color(0x00DCFCE7),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.45));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.45), topAura);

    // Top-right subtle mint aura
    final topAuraRight = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.9, -0.8),
        radius: 0.9,
        colors: [
          const Color(0xFFE8FAF2).withValues(alpha: 0.5),
          const Color(0x00E8FAF2),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.4));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.4), topAuraRight);

    // Bottom organic wave 1
    final wave1 = Paint()
      ..color = const Color(0xFFE8FAF2).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    final path1 = Path();
    path1.moveTo(0, size.height * 0.93);
    path1.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.89,
      size.width * 0.6,
      size.height * 0.94,
    );
    path1.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.98,
      size.width,
      size.height * 0.93,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, wave1);

    // Bottom organic wave 2
    final wave2 = Paint()
      ..color = const Color(0xFFD1FAE5).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    final path2 = Path();
    path2.moveTo(0, size.height * 0.96);
    path2.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.93,
      size.width * 0.7,
      size.height * 0.97,
    );
    path2.quadraticBezierTo(
      size.width * 0.88,
      size.height * 0.99,
      size.width,
      size.height * 0.95,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, wave2);

    // Decorative Green Leaves matching reference design (bottom waves only)
    _drawLeaf(canvas, Offset(size.width * 0.10, size.height * 0.88), 30, 0.4);
    _drawLeaf(canvas, Offset(size.width * 0.90, size.height * 0.90), 28, -0.4);
  }

  void _drawLeaf(Canvas canvas, Offset center, double size, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final leafPaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final leafPath = Path();
    leafPath.moveTo(0, -size / 2);
    leafPath.cubicTo(size * 0.45, -size * 0.35, size * 0.5, size * 0.3, 0, size / 2);
    leafPath.cubicTo(-size * 0.5, size * 0.3, -size * 0.45, -size * 0.35, 0, -size / 2);
    leafPath.close();

    canvas.drawPath(leafPath, leafPaint);

    final veinPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawLine(Offset(0, -size * 0.4), Offset(0, size * 0.4), veinPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
