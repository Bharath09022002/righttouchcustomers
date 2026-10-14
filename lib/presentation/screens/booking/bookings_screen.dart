import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/ui.dart';
import '../../providers/providers.dart';
import '../../widgets/cards.dart';
import '../../widgets/right_touch_header.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(myBookingsProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const RightTouchTopAppBar(title: 'Bookings'),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myBookingsProvider),
        child: b.when(
          data: (list) {
            if (list.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.calendar_month_outlined,
                          size: 36,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Your schedule is clear!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Need trusted AC repair, plumbing, appliance care, or solar maintenance?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 22),
                      ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.go('/services');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.handyman_outlined, size: 18),
                        label: const Text(
                          'Explore Services',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BookingCard(b: list[i], onTap: () => context.push('/booking/${list[i].id}')),
              ),
            );
          },
          loading: () => const ListTileShimmer(count: 4),
          error: (e, _) => ErrorView(message: '$e', onRetry: () => ref.invalidate(myBookingsProvider)),
        ),
      ),
    );
  }
}
