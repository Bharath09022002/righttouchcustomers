import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/ui.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/guest_login_placeholder.dart';
import '../../widgets/review_bottom_sheet.dart';

class MyRatingsScreen extends ConsumerStatefulWidget {
  const MyRatingsScreen({super.key});

  @override
  ConsumerState<MyRatingsScreen> createState() => _MyRatingsScreenState();
}

class _MyRatingsScreenState extends ConsumerState<MyRatingsScreen> {
  String _filter = 'all'; // 'all', 'service', 'product'

  Future<void> _handleEdit(RatingModel rating) async {
    HapticFeedback.lightImpact();
    final updated = await showReviewBottomSheet(
      context,
      bookingId: rating.bookingId,
      serviceTitle: rating.serviceName ?? rating.productName ?? 'Booking Review',
      technicianName: rating.technicianName,
      bookingType: rating.bookingType,
      initialRating: rating.rates,
      initialComment: rating.comment,
      isEditing: true,
      onSubmit: (rates, comment) async {
        try {
          await ref.read(ratingRepoProvider).updateRating(
            id: rating.id,
            rates: rates,
            comment: comment,
          );
          ref.invalidate(myRatingsProvider);
          return true;
        } catch (e) {
          if (mounted) {
            final appErr = mapException(e);
            showError(context, title: 'Update Failed', message: appErr.userMessage);
          }
          return false;
        }
      },
    );

    if (updated == true) {
      ref.invalidate(myRatingsProvider);
    }
  }

  Future<void> _handleDelete(RatingModel rating) async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Review?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Text(
          'Are you sure you want to delete this rating? The technician and service rating statistics will be automatically updated.',
          style: TextStyle(fontSize: 14, color: AppColors.grey700),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.grey600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(ratingRepoProvider).deleteRating(rating.id);
      ref.invalidate(myRatingsProvider);
      if (mounted) {
        showSuccess(
          context,
          title: 'Review Deleted',
          message: 'Your review has been successfully removed.',
        );
      }
    } catch (e) {
      if (mounted) {
        final appErr = mapException(e);
        showError(context, title: 'Delete Failed', message: appErr.userMessage);
      }
    }
  }

  Color _getContentColor(int rates) {
    if (rates >= 4) return const Color(0xFF16A34A);
    if (rates == 3) return const Color(0xFFD97706);
    if (rates == 2) return const Color(0xFFEA580C);
    return const Color(0xFFDC2626);
  }

  Color _getContentBg(int rates) {
    if (rates >= 4) return const Color(0xFFECFDF5);
    if (rates == 3) return const Color(0xFFFFFBEB);
    if (rates == 2) return const Color(0xFFFFF7ED);
    return const Color(0xFFFEF2F2);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    if (auth.isGuest) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('My Ratings & Reviews', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ),
        body: const GuestLoginPlaceholder(
          icon: Icons.star_rate_rounded,
          title: 'Sign In to View Reviews',
          subtitle: 'Please log in with your account to view, submit, and manage your service and equipment ratings.',
          primaryButtonText: 'Log In / Sign Up',
        ),
      );
    }

    final ratingsAsync = ref.watch(myRatingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Ratings & Reviews',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _buildFilterChip('all', 'All Reviews'),
                const SizedBox(width: 8),
                _buildFilterChip('service', 'Services'),
                const SizedBox(width: 8),
                _buildFilterChip('product', 'Equipment & Products'),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF16A34A),
        onRefresh: () async {
          ref.invalidate(myRatingsProvider);
        },
        child: ratingsAsync.when(
          data: (ratings) {
            final filtered = ratings.where((r) {
              if (_filter == 'all') return true;
              return r.bookingType.toLowerCase() == _filter;
            }).toList();

            if (filtered.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 60),
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 36),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Reviews Found',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You haven’t submitted any ratings in this category yet. Ratings can be added once your service is completed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: const Text('View Completed Bookings', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () => context.push('/bookings'),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (ctx, i) {
                final r = filtered[i];
                final isService = r.bookingType.toLowerCase() == 'service';
                final title = isService
                    ? (r.serviceName ?? 'Service Booking')
                    : (r.productName ?? 'Product Order');

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Service/Product Badge + Booking ID + Options
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: isService ? const Color(0xFFEFF6FF) : const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isService ? 'SERVICE' : 'PRODUCT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: isService ? const Color(0xFF2563EB) : const Color(0xFF7C3AED),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (r.bookingId.isNotEmpty)
                            Text(
                              'Booking #${r.bookingId.length > 8 ? r.bookingId.substring(r.bookingId.length - 8) : r.bookingId}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Title & Technician
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (r.technicianName != null && r.technicianName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Technician: ${r.technicianName}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Star Row & Auto Content Badge
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (sIdx) {
                              return Icon(
                                sIdx < r.rates ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: sIdx < r.rates ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                                size: 20,
                              );
                            }),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getContentBg(r.rates),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _getContentColor(r.rates).withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              r.content.isNotEmpty ? r.content : RatingModel.computeContent(r.rates),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _getContentColor(r.rates),
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (r.createdAt != null)
                            Text(
                              fmtDate(r.createdAt),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Comment Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Text(
                          r.comment.isNotEmpty ? r.comment : 'No detailed feedback provided.',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF334155),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Action Buttons: Edit & Delete
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit Review', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                            onPressed: () => _handleEdit(r),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFFECACA)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded, size: 16),
                            label: const Text('Delete', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                            onPressed: () => _handleDelete(r),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: RtLoader()),
          error: (e, _) => ErrorView(
            message: '$e',
            onRetry: () => ref.invalidate(myRatingsProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final selected = _filter == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filter = key);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
