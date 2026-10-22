import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../ui/app_feedback.dart';

/// RightTouch brand logo presented as an elegant curved rectangle emblem with visible logo icon and brand lettering.
class BrandLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final double? iconSize;
  final double? fontSize;
  final bool isCircular;
  final BorderRadius? borderRadius;

  const BrandLogo({
    super.key,
    this.width,
    this.height,
    this.iconSize,
    this.fontSize,
    this.isCircular = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final double targetWidth = width != null ? (width! * 0.84).clamp(120.0, 160.0) : 144.0;
    final double targetHeight = height ?? (targetWidth * 0.76).clamp(96.0, 126.0);
    final double iconH = (iconSize ?? (targetHeight * 0.44)).clamp(38.0, 58.0);
    final double fontS = fontSize ?? (targetWidth * 0.088).clamp(11.0, 14.0);

    return Container(
      width: isCircular ? (height ?? width ?? 142.0) : targetWidth,
      height: isCircular ? (height ?? width ?? 142.0) : targetHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircular ? null : (borderRadius ?? BorderRadius.circular(22)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1816A34A),
            blurRadius: 18,
            spreadRadius: 1,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFDCFCE7),
          width: 2,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo_icon.png',
                height: iconH,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/logo.png',
                  height: iconH,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.lightbulb_rounded,
                    color: const Color(0xFF16A34A),
                    size: iconH,
                  ),
                ),
              ),
              SizedBox(height: targetHeight * 0.035),
              SizedBox(
                width: targetWidth * 0.88,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'RIGHT TOUCH',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: fontS,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: const Color(0xFF16A34A),
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

/// "Or login with" divider + social buttons (Figma auth screens).
/// Social auth is decorative until backend OAuth lands.
class SocialLoginRow extends StatelessWidget {
  final String label;
  const SocialLoginRow({super.key, this.label = 'Or login with'});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        const Expanded(child: Divider(color: AppColors.grey200)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style:
                  const TextStyle(color: AppColors.grey400, fontSize: 12)),
        ),
        const Expanded(child: Divider(color: AppColors.grey200)),
      ]),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _btn(context, 'f', const Color(0xFF1877F2)),
        const SizedBox(width: 16),
        _btn(context, 'G', const Color(0xFFDB4437)),
        const SizedBox(width: 16),
        _btn(context, 'apple', Colors.black),
      ]),
    ]);
  }

  Widget _btn(BuildContext context, String glyph, Color color) {
    return InkWell(
      onTap: () => showSuccess(
        context,
        title: 'Coming Soon',
        message: 'Social login is coming soon. Please use mobile number with OTP.',
      ),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.grey200),
          boxShadow: const [
            BoxShadow(
                color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Center(
          child: glyph == 'apple'
              ? const Icon(Icons.apple, color: Colors.black, size: 26)
              : Text(glyph,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: color)),
        ),
      ),
    );
  }
}

/// Small title header used across auth screens.
class AuthHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const AuthHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(
          subtitle!,
          style: const TextStyle(
            color: AppColors.grey600,
            fontSize: 13,
          ),
        ),
      ],
    ]);
  }
}
