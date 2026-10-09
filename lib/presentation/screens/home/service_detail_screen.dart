import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/providers.dart';

class ServiceDetailScreen extends ConsumerWidget {
  final String id;
  const ServiceDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(serviceDetailProvider(id));

    return d.when(
      data: (s) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            s.name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/');
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                Clipboard.setData(ClipboardData(
                  text: '${s.name} - Book at https://www.righttouchservice.com/',
                ));
                showSuccess(
                  context,
                  title: 'Link Copied',
                  message: 'Service link copied to clipboard!',
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (s.image != null && s.image!.isNotEmpty)
                  AppImage(
                    url: s.image,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (s.rating > 0) ...[
                            RatingStars(value: s.rating, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${s.rating.toStringAsFixed(1)} (${s.ratingCount})',
                              style: const TextStyle(
                                color: AppColors.grey600,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Text(
                            '${s.durationMin} mins • ${s.categoryName ?? 'Service'}',
                            style: const TextStyle(
                              color: AppColors.grey600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      PriceTag(price: s.price, mrp: s.mrp),
                      if (s.description != null && s.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'About this service',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.description!,
                          style: const TextStyle(
                            color: AppColors.grey600,
                            height: 1.5,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (s.warranty.isNotEmpty && s.warranty != 'Service Warranty') ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user_outlined, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  s.warranty,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.grey200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Add to cart',
                    outlined: true,
                    onPressed: () async {
                      try {
                        await ref.read(cartRepoProvider).add(s.id, 'service', 1);
                        ref.invalidate(cartProvider);
                        if (context.mounted) {
                          showSuccess(
                            context,
                            title: 'Added to cart',
                            message: '${s.name} added to cart.',
                            actionLabel: 'View cart',
                            onAction: () => context.push('/cart'),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          final appErr = mapException(e);
                          showError(
                            context,
                            title: 'Could not add to cart',
                            message: appErr.userMessage,
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Book now',
                    onPressed: () => context.push('/book/${s.id}'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: '$e',
          onRetry: () => ref.invalidate(serviceDetailProvider(id)),
        ),
      ),
    );
  }
}
