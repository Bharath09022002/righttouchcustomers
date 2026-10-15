import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/providers.dart';

class ServiceDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ServiceDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollProgress = ValueNotifier<double>(0.0);
  final Set<int> _expandedFaqIndices = {};
  bool _showAllFaqs = false;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final progress = (offset / 80.0).clamp(0.0, 1.0);
    if (_scrollProgress.value != progress) {
      _scrollProgress.value = progress;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(serviceDetailProvider(widget.id));
    final cartItems = ref.watch(cartProvider).valueOrNull ?? [];
    final inCart = cartItems.any((it) => it.itemId == widget.id || it.id == widget.id);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: d.when(
        data: (s) {
          final included = s.whatIncluded;
          final notIncluded = s.whatNotIncluded;
          final notes = s.serviceHighlights;

          final faqs = s.frequentlyAskedQuestions.map((q) {
            final parts = q.split('?');
            if (parts.length > 1) {
              return {
                'question': '${parts[0].trim()}?',
                'answer': parts.sublist(1).join('?').trim(),
              };
            }
            return {
              'question': q,
              'answer': 'Please contact customer support for specific details regarding this query.',
            };
          }).toList();

          final displayedFaqs = _showAllFaqs ? faqs : faqs.take(4).toList();

          return Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                // 1. Scrollable Content (Words and media scroll underneath the Telegram-style floating top bar)
                SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + 64,
                    16,
                    48,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Inverter Product Image Card
                      Container(
                        width: double.infinity,
                        height: 270,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AppImage(
                          url: s.image,
                          width: double.infinity,
                          height: 270,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Rating & Price + Duration Row (Matching Image 1)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Rating
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFF9800),
                                size: 24,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${s.rating.toStringAsFixed(1)} ',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '(${s.ratingCount} reviews)',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Right: Price and Duration
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (s.price != null && s.price! > 0)
                                  Text(
                                    '₹${s.price!.toInt()}',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                    ),
                                  )
                                else
                                  const Text(
                                    'Price on request',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                if (s.durationMin > 0)
                                  Text(
                                    '${s.durationMin} mins',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF64748B),
                                      height: 1.35,
                                    ),
                                  )
                                else if (s.durationText != null && s.durationText!.trim().isNotEmpty)
                                  Text(
                                    s.durationText!,
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF64748B),
                                      height: 1.35,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Section 1: Service Included (only when non-empty)
                      if (included.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        const Text(
                          'Service Included',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Column(
                          children: included.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: Color(0xFF00A859),
                                    size: 21,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        color: Color(0xFF475569),
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // Section 2: Service does not include (only when non-empty)
                      if (notIncluded.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        const Text(
                          'Service does not include',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Column(
                          children: notIncluded.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.remove_circle_outline_rounded,
                                    color: Color(0xFFE53935),
                                    size: 21,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        color: Color(0xFF475569),
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // Section 3: Please note (only when non-empty)
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        const Text(
                          'Please note',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Column(
                          children: notes.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: Color(0xFF64748B),
                                    size: 21,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        color: Color(0xFF475569),
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // Section 4: Frequently Asked Questions (only when non-empty)
                      if (faqs.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        const Text(
                          'Frequently Asked Questions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Column(
                          children: List.generate(displayedFaqs.length, (index) {
                            final faq = displayedFaqs[index];
                            final isExpanded = _expandedFaqIndices.contains(index);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  key: PageStorageKey('faq_$index'),
                                  initiallyExpanded: isExpanded,
                                  onExpansionChanged: (expanded) {
                                    setState(() {
                                      if (expanded) {
                                        _expandedFaqIndices.add(index);
                                      } else {
                                        _expandedFaqIndices.remove(index);
                                      }
                                    });
                                  },
                                  trailing: Icon(
                                    isExpanded ? Icons.remove : Icons.add,
                                    color: const Color(0xFF1E293B),
                                    size: 20,
                                  ),
                                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                                  title: Text(
                                    faq['question'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  children: [
                                    Text(
                                      faq['answer'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: Color(0xFF64748B),
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                        if (faqs.length > 4)
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() => _showAllFaqs = !_showAllFaqs);
                              },
                              child: Text(
                                _showAllFaqs ? 'Show less' : 'Show more',
                                style: const TextStyle(
                                  color: Color(0xFF00A859),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),

                // 2. Telegram-Style Floating Top Bar (Words and media scroll seamlessly underneath)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ValueListenableBuilder<double>(
                    valueListenable: _scrollProgress,
                    builder: (context, progress, _) {
                      return Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 6,
                          bottom: 10,
                          left: 16,
                          right: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94 + 0.06 * progress),
                          border: Border(
                            bottom: BorderSide(
                              color: const Color(0xFFE2E8F0).withValues(alpha: progress),
                              width: 1,
                            ),
                          ),
                          boxShadow: progress > 0.08
                              ? [
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.05 * progress),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Title
                            Expanded(
                              child: Text(
                                s.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  height: 1.25,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Green Add button
                            ElevatedButton(
                              onPressed: _isAdding
                                  ? null
                                  : () async {
                                      setState(() => _isAdding = true);
                                      HapticFeedback.lightImpact();
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
                                            title: 'Notice',
                                            message: appErr.userMessage,
                                          );
                                        }
                                      } finally {
                                        if (mounted) setState(() => _isAdding = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00A859),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                minimumSize: const Size(0, 38),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: _isAdding
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      inCart ? 'Added' : 'Add',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 8),
                            // Telegram-Style Circular "X" close button
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  context.go('/');
                                }
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
        error: (e, _) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
              onPressed: () => context.pop(),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.grey500),
                  const SizedBox(height: 12),
                  const Text(
                    'Unable to load service details',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(serviceDetailProvider(widget.id)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
