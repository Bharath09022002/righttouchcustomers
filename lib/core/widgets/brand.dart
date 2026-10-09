import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../ui/app_feedback.dart';

/// RightTouch brand logo using official asset logo.png.
class BrandLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final double? iconSize;
  final double? fontSize;
  const BrandLogo({
    super.key,
    this.width,
    this.height,
    this.iconSize,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width ?? (iconSize != null ? iconSize! * 4 : 180.0);
    return Image.asset(
      'assets/images/logo.png',
      width: effectiveWidth,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Color(0xFFFFF7E0),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.wb_sunny_rounded,
            size: 30, color: Color(0xFFF5A623)),
      ),
      const SizedBox(height: 8),
      const Text('RIGHT TOUCH',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
            color: AppColors.primary,
          )),
    ]);
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
