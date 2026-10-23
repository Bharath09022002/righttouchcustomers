// Right Touch: animated splash screen v2
// The logo is drawn in code (CustomPainter), so every part animates separately
// and stays sharp on all screen sizes. No image assets or extra packages needed.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';

const _green = Color(0xFF12A04B);
const _yellow = Color(0xFFFFE600);
const _ink = Color(0xFF111111);
const _introSec = 3.2;

class SplashScreen extends ConsumerStatefulWidget {
  /// Optional callback for startup initialization work.
  final Future<void> Function()? onInit;

  const SplashScreen({super.key, this.onInit});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _loop;
  Timer? _watchdog;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _intro.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        _loop.repeat();
      }
    });

    _run();

    // Defensive fallback: ensure navigation happens even on network/storage hangs
    _watchdog = Timer(const Duration(seconds: 8), () {
      if (mounted && !_navigated) {
        _navigateAfterInit();
      }
    });
  }

  Future<void> _run() async {
    await Future.wait([
      _intro.forward().orCancel.catchError((_) {}),
      _performInit(),
    ]);

    if (!mounted || _navigated) return;
    _navigateAfterInit();
  }

  Future<void> _performInit() async {
    try {
      if (widget.onInit != null) {
        await widget.onInit!();
      }
      final store = ref.read(tokenStorageProvider);
      await store.loadCache();
    } catch (e) {
      if (kDebugMode) debugPrint('[Splash] init error: $e');
    }
  }

  Future<void> _navigateAfterInit() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    try {
      final store = ref.read(tokenStorageProvider);
      final onboarded = await store.isOnboarded().catchError((_) => true);

      if (!mounted) return;
      if (!onboarded) {
        context.go('/onboarding');
      } else if (store.cachedToken?.isNotEmpty == true) {
        context.go('/');
      } else {
        context.go('/login');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Splash] nav failed: $e');
      if (mounted) context.go('/login');
    }
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  /// Progress (0..1) of a segment that runs from [start] to [start+dur] seconds.
  double _p(double start, double dur, [Curve curve = Curves.linear]) {
    final t = ((_intro.value * _introSec - start) / dur).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations && _intro.value < 1) {
      _intro.value = 1; // honour "reduce motion"
    }
    const word = 'RIGHT TOUCH';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_intro, _loop]),
          builder: (context, _) {
            final done = _intro.isCompleted;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 190,
                  height: 190 * 95 / 100,
                  child: CustomPaint(
                    painter: _LogoPainter(
                      bulbLine: _p(0.0, 0.6, Curves.easeInOut),
                      bulbFill: _p(0.5, 0.45, Curves.easeOutBack),
                      glow: _p(0.7, 0.6),
                      rays: List.generate(
                        8,
                        (i) => _p(0.9 + i * 0.06, 0.3, Curves.easeOut),
                      ),
                      hand: _p(1.25, 0.6, Curves.easeOutBack),
                      tap: _p(1.9, 0.3),
                      ripple: _p(2.0, 0.7, Curves.easeOut),
                      flash: _p(2.0, 0.5),
                      check: _p(2.1, 0.45, Curves.easeInOutCubic),
                      loop: done ? _loop.value : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(word.length, (i) {
                    final t = _p(2.3 + i * 0.06, 0.55, Curves.easeOutBack);
                    return Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, -40 * (1 - t)),
                        child: Transform.scale(
                          scale: 0.6 + 0.4 * t,
                          child: Text(
                            word[i],
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w800,
                              fontSize: 31,
                              letterSpacing: 0.5,
                              color: _green,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 42),
                Opacity(
                  opacity: done ? 1 : 0,
                  child: _LoadingBar(t: (_loop.value * 2) % 1.0),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  final double t;
  const _LoadingBar({required this.t});

  @override
  Widget build(BuildContext context) {
    final x = Curves.easeInOut.transform(t);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 120,
        height: 4,
        color: const Color(0xFFE6F4EC),
        child: Stack(
          children: [
            Positioned(
              left: -48 + 168 * x, // slides from off-left to off-right
              top: 0,
              width: 48,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final double bulbLine, bulbFill, glow, hand, tap, ripple, flash, check;
  final List<double> rays;
  final double? loop; // null during intro, 0..1 repeating afterwards

  _LogoPainter({
    required this.bulbLine,
    required this.bulbFill,
    required this.glow,
    required this.rays,
    required this.hand,
    required this.tap,
    required this.ripple,
    required this.flash,
    required this.check,
    required this.loop,
  });

  static const _c = Offset(51, 40);
  static const _r = 21.5;
  static const _rayAngles = [-90, -120, -60, -150, 180, 150, 0, 25];

  static double _bump(double t) => 1 - (2 * t - 1).abs(); // 0 -> 1 -> 0

  Path _partial(Path p, double t) {
    final out = Path();
    if (t <= 0) return out;
    for (final m in p.computeMetrics()) {
      out.addPath(m.extractPath(0, m.length * t), Offset.zero);
    }
    return out;
  }

  Path get _handPath => Path()
    ..moveTo(45, 44)
    ..quadraticBezierTo(45, 37.5, 49, 37.5)
    ..quadraticBezierTo(53, 37.5, 53, 44)
    ..lineTo(53, 60)
    ..quadraticBezierTo(53, 56, 57, 56)
    ..quadraticBezierTo(61, 56, 61, 60)
    ..quadraticBezierTo(61, 57, 65, 57)
    ..quadraticBezierTo(69, 57, 69, 61)
    ..quadraticBezierTo(69, 59, 72.5, 59)
    ..quadraticBezierTo(76, 59, 76, 63)
    ..lineTo(76, 76)
    ..quadraticBezierTo(76, 86, 66, 90)
    ..lineTo(51, 90)
    ..quadraticBezierTo(44, 88, 40.5, 82)
    ..lineTo(30.5, 70.5)
    ..quadraticBezierTo(28, 66.5, 31.5, 64.5)
    ..quadraticBezierTo(35, 62.5, 38, 65.5)
    ..lineTo(45, 72)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100);

    // 1. Glow behind bulb (burst, then breathe in loop)
    double gScale, gOpacity;
    if (loop != null) {
      final b = _bump(loop!);
      gScale = 1 + 0.15 * b;
      gOpacity = 0.85 - 0.4 * b;
    } else {
      gScale = glow < .6 ? 0.2 + 1.1 * glow / .6 : 1.3 - 0.3 * (glow - .6) / .4;
      gOpacity = glow < .6 ? glow / .6 : 1 - 0.15 * (glow - .6) / .4;
    }
    if (gOpacity > 0) {
      final gr = 40 * gScale;
      canvas.drawCircle(
        _c,
        gr,
        Paint()
          ..shader = ui.Gradient.radial(
            _c,
            gr,
            [
              _yellow.withValues(alpha: .6 * gOpacity),
              _yellow.withValues(alpha: .18 * gOpacity),
              _yellow.withValues(alpha: 0),
            ],
            [0, .5, 1],
          ),
      );
    }

    // 2. Rays shoot out one by one, twinkle in loop
    for (var i = 0; i < 8; i++) {
      final t = rays[i];
      if (t <= 0) continue;
      final a = _rayAngles[i] * math.pi / 180;
      final dir = Offset(math.cos(a), math.sin(a));
      final p1 = _c + dir * 28;
      final p2 = p1 + dir * 8 * t;
      var op = 1.0;
      if (loop != null) op = 1 - 0.65 * _bump((loop! - i * 0.04) % 1.0);
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = _ink.withValues(alpha: op)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    // 3. Bulb fill (pops from centre) + flash on tap
    if (bulbFill > 0) {
      canvas.drawCircle(_c, _r * bulbFill, Paint()..color = _yellow);
      final f = flash < .3 ? flash / .3 : 1 - (flash - .3) / .7;
      if (flash > 0 && flash < 1) {
        canvas.drawCircle(
          _c,
          _r + 2,
          Paint()
            ..color = _yellow.withValues(alpha: .9 * f)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }

    // 4. Bulb outline draws clockwise from the top
    final ring = Path()
      ..addArc(
        Rect.fromCircle(center: _c, radius: _r),
        -math.pi / 2,
        2 * math.pi - 0.0001,
      );
    canvas.drawPath(
      _partial(ring, bulbLine),
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // 5. Ripple from the fingertip
    if (ripple > 0 && ripple < 1) {
      canvas.drawCircle(
        const Offset(49, 38.5),
        3 * (0.3 + 5.7 * ripple),
        Paint()
          ..color = _green.withValues(alpha: 1 - ripple)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // 6. Hand rises up, then taps
    if (hand > 0) {
      final tapB = tap > 0 && tap < 1 ? _bump(tap) : 0.0;
      canvas.save();
      canvas.translate(0, 45 * (1 - hand) + 3 * tapB);
      final s = 1 - 0.04 * tapB;
      canvas.translate(53, 64);
      canvas.scale(s);
      canvas.translate(-53, -64);
      final op = hand.clamp(0.0, 1.0);
      final hp = _handPath;
      canvas.drawPath(hp, Paint()..color = Colors.white.withValues(alpha: op));
      canvas.drawPath(
        Path()
          ..moveTo(71, 64)
          ..lineTo(71, 82)
          ..quadraticBezierTo(70, 86, 64, 88),
        Paint()
          ..color = const Color(0xFFCCCCCC).withValues(alpha: op)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
      final line = Paint()
        ..color = _ink.withValues(alpha: op)
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(hp, line..strokeWidth = 2);
      canvas.drawPath(
        Path()
          ..moveTo(53, 60)
          ..lineTo(53, 66)
          ..moveTo(61, 60)
          ..lineTo(61, 66)
          ..moveTo(69, 61)
          ..lineTo(69, 66),
        line..strokeWidth = 1.4,
      );
      canvas.restore();
    }

    // 7. Checkmark draws itself
    if (check > 0) {
      final ck = Path()
        ..moveTo(54, 41)
        ..lineTo(60.5, 48.5)
        ..lineTo(87, 24);
      canvas.drawPath(
        _partial(ck, check),
        Paint()
          ..color = _green
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
