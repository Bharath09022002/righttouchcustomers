import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:righttouch/core/theme/app_colors.dart';

/// Branded high-performance Right Touch loader.
/// Features orbiting brand marks and pulse animation with accessibility and reduced-motion support.
class RtLoader extends StatefulWidget {
  final double size;
  final String? label;
  final Color? color;
  final bool delay;

  const RtLoader({
    super.key,
    this.size = 48,
    this.label,
    this.color,
    this.delay = false,
  });

  /// 20px compact variant for buttons (preserves dimensions without layout shifts).
  const RtLoader.button({
    super.key,
    this.size = 20,
    this.label = 'Loading',
    this.color,
    this.delay = false,
  });

  // --- Static Overlay Implementation ---
  static OverlayEntry? _overlayEntry;
  static DateTime? _overlayShownTime;
  static const Duration _minDisplayDuration = Duration(milliseconds: 400);

  /// Shows a full-screen blocking overlay with dimmed barrier and PopScope guard.
  static void showOverlay(BuildContext context, {String? message}) {
    if (_overlayEntry != null) return;

    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) return;

    _overlayShownTime = DateTime.now();
    _overlayEntry = OverlayEntry(
      builder: (ctx) => PopScope(
        canPop: false,
        child: Material(
          color: const Color(0x99000000), // Dimmed barrier
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const RtLoader(size: 48),
                  if (message != null && message.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(_overlayEntry!);
  }

  /// Hides the full-screen overlay, enforcing minimum display duration to prevent visual flashes.
  static Future<void> hideOverlay({bool enforceMinDisplay = true}) async {
    final entry = _overlayEntry;
    if (entry == null) return;

    final shownTime = _overlayShownTime;
    if (enforceMinDisplay && shownTime != null) {
      final elapsed = DateTime.now().difference(shownTime);
      if (elapsed < _minDisplayDuration) {
        await Future.delayed(_minDisplayDuration - elapsed);
      }
    }

    if (_overlayEntry == entry) {
      entry.remove();
      _overlayEntry = null;
      _overlayShownTime = null;
    }
  }

  @override
  State<RtLoader> createState() => _RtLoaderState();
}

class _RtLoaderState extends State<RtLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.delay) {
      _isVisible = false;
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          setState(() => _isVisible = true);
          final disable = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
          if (!disable) _controller.repeat();
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final disable = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
          if (!disable) {
            _controller.repeat();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return SizedBox(width: widget.size, height: widget.size);
    }

    final effectiveColor = widget.color ?? AppColors.primary;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      label: widget.label ?? 'Loading',
      liveRegion: true,
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: disableAnimations
              ? _ReducedMotionMark(
                  size: widget.size,
                  color: effectiveColor,
                )
              : AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _RtLoaderPainter(
                        progress: _controller.value,
                        color: effectiveColor,
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// Fallback visual for reduced motion preferences.
class _ReducedMotionMark extends StatelessWidget {
  final double size;
  final Color color;

  const _ReducedMotionMark({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RtReducedMotionPainter(color: color),
    );
  }
}

class _RtReducedMotionPainter extends CustomPainter {
  final Color color;
  _RtReducedMotionPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final centerRadius = size.width * 0.16;
    final orbitRadius = size.width * 0.36;
    final dotRadius = size.width * 0.08;

    // Center static mark
    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, centerRadius, centerPaint);

    // Three static orbiting dots
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi) / 3;
      final x = center.dx + orbitRadius * math.cos(angle);
      final y = center.dy + orbitRadius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RtReducedMotionPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Custom painter rendering orbiting arcs and pulsing center mark.
class _RtLoaderPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;

  _RtLoaderPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final centerBaseRadius = size.width * 0.14;
    final orbitRadius = size.width * 0.36;
    final dotBaseRadius = size.width * 0.075;

    // Center pulse: scale between 0.85 and 1.15
    final pulseScale = 1.0 + 0.15 * math.sin(progress * 2 * math.pi);
    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, centerBaseRadius * pulseScale, centerPaint);

    // Orbit path ring (faint)
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, size.width * 0.04);
    canvas.drawCircle(center, orbitRadius, ringPaint);

    // 3 Orbiting dots with staggered phase and non-linear ease
    for (int i = 0; i < 3; i++) {
      final phaseOffset = (i * 2 * math.pi) / 3;
      final t = (progress * 2 * math.pi + phaseOffset) % (2 * math.pi);

      // Smooth ease-in-out angular progression
      final easedAngle = t + 0.25 * math.sin(2 * t);
      final x = center.dx + orbitRadius * math.cos(easedAngle);
      final y = center.dy + orbitRadius * math.sin(easedAngle);

      final dotScale = 0.85 + 0.3 * (0.5 + 0.5 * math.sin(easedAngle));
      final opacity = 0.5 + 0.5 * (0.5 + 0.5 * math.cos(easedAngle));

      final dotPaint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), dotBaseRadius * dotScale, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RtLoaderPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Stack overlay for screen or card level loading states.
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingMessage;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AbsorbPointer(
          absorbing: isLoading,
          child: Opacity(opacity: isLoading ? 0.5 : 1.0, child: child),
        ),
        if (isLoading)
          Center(
            child: Card(
              elevation: 8,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const RtLoader(size: 48),
                    if (loadingMessage != null && loadingMessage!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        loadingMessage!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
