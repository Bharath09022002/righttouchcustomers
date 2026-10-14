import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/ui/app_feedback.dart';
import '../../providers/providers.dart';

/// Passwordless customer auth screen matching the exact design:
/// - Brand logo with lightbulb hand click & 'RIGHT TOUCH'
/// - 'Welcome to Right Touch' heading
/// - Segmented Login / Sign up toggle with active underline indicator
/// - Mobile number field with 🇮🇳 +91, dropdown chevron, and green border
/// - 'Your number is safe with us. We'll send a 4-digit OTP.' security badge
/// - Vibrant green swipe to action slider button with dark green circle arrow
/// - 'OR' divider
/// - 'Explore as Guest' button with compass icon
/// - Terms & Privacy Policy agreement footer
class LoginScreen extends ConsumerStatefulWidget {
  final bool initialSignup;
  const LoginScreen({super.key, this.initialSignup = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late bool _isSignup;
  late final TextEditingController _ctrl;
  final FocusNode _focusNode = FocusNode();
  String? _err;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _isSignup = widget.initialSignup;
    _ctrl = TextEditingController(text: ref.read(authProvider).mobile ?? '');
    _focusNode.addListener(() {
      setState(() {});
    });
    if (_isSignup) {
      Future.microtask(
        () => ref.read(authProvider.notifier).setMode(AuthMode.signup),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _setMode(bool signup) {
    HapticFeedback.selectionClick();
    ref
        .read(authProvider.notifier)
        .setMode(signup ? AuthMode.signup : AuthMode.login);
    setState(() {
      _isSignup = signup;
      _err = null;
    });
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
        _setMode(false);
        showError(
          context,
          title: 'Already Registered',
          message:
              'This mobile number is already registered. Please proceed to Login.',
          actionLabel: 'Go to Login',
          onAction: () => _setMode(false),
        );
      } else if (low.contains('signup first') ||
          low.contains('not found') ||
          low.contains('not registered')) {
        _setMode(true);
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
            // Background organic wave graphics
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 18),

                        // 1. BRAND LOGO
                        Center(
                          child: const BrandLogo(width: 170),
                        ),

                        const SizedBox(height: 26),

                        // 2. HEADING & SUBHEADING
                        const Text(
                          'Welcome to Right Touch',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isSignup
                              ? 'Create an account to get started'
                              : 'Sign in to continue to your account',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 3. SEGMENTED TOGGLE (Login | Sign up)
                        Container(
                          height: 52,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildSegmentTab(
                                  label: 'Login',
                                  isSelected: !_isSignup,
                                  onTap: () => _setMode(false),
                                ),
                              ),
                              Expanded(
                                child: _buildSegmentTab(
                                  label: 'Sign up',
                                  isSelected: _isSignup,
                                  onTap: () => _setMode(true),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 26),

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

                        // Input Container with Green Border
                        Container(
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF10B981),
                              width: 1.6,
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
                              // Country Flag
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
                                  focusNode: _focusNode,
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

                        const SizedBox(height: 10),

                        // 5. SECURITY BADGE
                        Row(
                          children: const [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 16,
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Your number is safe with us. We'll send a 4-digit OTP.",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
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

                        const SizedBox(height: 24),

                        // 6. SWIPE TO ACTION BUTTON ("Swipe to Login" / "Swipe to Register")
                        SwipeToActionButton(
                          label: _isSignup ? 'Swipe to Register' : 'Swipe to Login',
                          isLoading: _busy,
                          onSwipe: _send,
                        ),

                        const SizedBox(height: 24),

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
                                  color: Color(0xFF64748B),
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

                        const SizedBox(height: 22),

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
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                      fontSize: 15.5,
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

                        const SizedBox(height: 28),

                        // 9. TERMS & PRIVACY FOOTER
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'By continuing, you agree to our ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: _showTermsDialog,
                                child: const Text(
                                  'Terms',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const Text(
                                '  &  ',
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
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
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
                        ),

                        const SizedBox(height: 20),
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

  /// Segmented Tab Button with white card and green underline accent for active tab
  Widget _buildSegmentTab({
    required String label,
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
                    color: Color(0x0C000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFF00A859),
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            else
              const SizedBox(height: 3),
          ],
        ),
      ),
    );
  }
}

/// Interactive Swipe to Action Slider Button:
/// Drag the thumb from left to right to trigger Login or Register.
class SwipeToActionButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final Future<void> Function() onSwipe;

  const SwipeToActionButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onSwipe,
  });

  @override
  State<SwipeToActionButton> createState() => _SwipeToActionButtonState();
}

class _SwipeToActionButtonState extends State<SwipeToActionButton>
    with SingleTickerProviderStateMixin {
  double _dragProgress = 0.0;
  late final AnimationController _animController;
  Animation<double>? _resetAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(() {
        if (_resetAnim != null) {
          setState(() {
            _dragProgress = _resetAnim!.value;
          });
        }
      });
  }

  @override
  void didUpdateWidget(covariant SwipeToActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If loading completes or resets, return thumb to start
    if (oldWidget.isLoading && !widget.isLoading) {
      _resetSlider();
    }
    // If mode changed (Login <-> Register), reset slider
    if (oldWidget.label != widget.label) {
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
    if (_dragProgress >= 0.72) {
      _handleSwipe();
    } else {
      _resetSlider();
    }
  }

  void _onTapDirect() {
    if (widget.isLoading) return;
    _resetAnim = Tween<double>(begin: _dragProgress, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0.0).then((_) {
      _handleSwipe();
    });
  }

  Future<void> _handleSwipe() async {
    setState(() => _dragProgress = 1.0);
    HapticFeedback.heavyImpact();
    await widget.onSwipe();
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
    const thumbSize = 44.0;
    const padding = 6.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final maxDrag = (totalWidth - thumbSize - (padding * 2)).clamp(1.0, 1000.0);
        final currentOffset = _dragProgress * maxDrag;

        return GestureDetector(
          onHorizontalDragUpdate: (d) => _onDragUpdate(d, maxDrag),
          onHorizontalDragEnd: _onDragEnd,
          onTap: _onTapDirect,
          child: Container(
            height: totalHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF00A859),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3800A859),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Filled darker green track behind thumb as it advances
                Container(
                  width: padding + thumbSize + currentOffset,
                  height: totalHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                // Center animated text label (fades out as thumb passes)
                Positioned.fill(
                  child: Center(
                    child: Opacity(
                      opacity: (1.0 - (_dragProgress * 1.6)).clamp(0.0, 1.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const _ShimmerChevrons(),
                        ],
                      ),
                    ),
                  ),
                ),

                // Draggable circular thumb handle
                Positioned(
                  left: padding + currentOffset,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFF047857),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: widget.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
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
}

/// Shimmering pulsing chevrons indicating the swipe direction
class _ShimmerChevrons extends StatefulWidget {
  const _ShimmerChevrons();

  @override
  State<_ShimmerChevrons> createState() => _ShimmerChevronsState();
}

class _ShimmerChevronsState extends State<_ShimmerChevrons>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_controller),
      child: const Text(
        '❯❯❯',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
