import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../widgets/skeleton.dart';

/// Centralized, high-performance image component with:
/// 1. Automatic Retina-sharp downsampling via memCacheWidth / memCacheHeight
/// 2. Uniform AspectRatio and BoxFit.cover framing across all screens
/// 3. Brand-consistent Shimmer skeleton placeholder
/// 4. Unified handling for both remote URLs and local assets/images
class AppImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final double? aspectRatio;
  final BoxFit fit;
  final BorderRadius? radius;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppImage({
    super.key,
    this.url,
    this.width,
    this.height,
    this.aspectRatio,
    this.fit = BoxFit.cover,
    this.radius,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholder,
    this.errorWidget,
  });

  /// 1:1 Square avatar/product variant
  const AppImage.square({
    super.key,
    required this.url,
    double size = 48,
    this.radius,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  })  : width = size,
        height = size,
        aspectRatio = 1.0,
        memCacheWidth = null,
        memCacheHeight = null;

  /// 16:9 Banner variant
  const AppImage.banner({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  })  : aspectRatio = 16 / 9,
        memCacheWidth = null,
        memCacheHeight = null;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;

    // High-fidelity display resolution:
    // Guarantees razor-sharp rendering on high-DPI screens without pixelation or clumsy artifacts.
    final targetCacheWidth = memCacheWidth ??
        (width != null && !width!.isInfinite
            ? (width! * dpr * 2.0).clamp(720, 2048).round()
            : 1080);
    final targetCacheHeight = memCacheHeight;

    final defaultPlaceholder = placeholder ??
        Skeleton(
          width: width,
          height: height,
          borderRadius: radius != null ? radius!.topLeft.x : 12,
        );

    final defaultError = errorWidget ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: radius,
          ),
          child: const Center(
            child: Icon(
              Icons.broken_image_rounded,
              color: AppColors.grey400,
              size: 24,
            ),
          ),
        );

    Widget imageWidget;

    if (url == null || url!.trim().isEmpty) {
      imageWidget = defaultError;
    } else if (url!.startsWith('assets/')) {
      // Local bundled asset with crisp high-definition filtering
      imageWidget = Image.asset(
        url!,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: targetCacheWidth,
        cacheHeight: targetCacheHeight,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => defaultError,
      );
    } else {
      // Remote cached network image with high-fidelity caching and shimmer placeholder
      imageWidget = CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: targetCacheWidth,
        memCacheHeight: targetCacheHeight,
        filterQuality: FilterQuality.high,
        placeholder: (_, __) => defaultPlaceholder,
        errorWidget: (_, __, ___) => defaultError,
      );
    }

    if (aspectRatio != null) {
      imageWidget = AspectRatio(
        aspectRatio: aspectRatio!,
        child: imageWidget,
      );
    }

    if (radius != null) {
      imageWidget = ClipRRect(
        borderRadius: radius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
