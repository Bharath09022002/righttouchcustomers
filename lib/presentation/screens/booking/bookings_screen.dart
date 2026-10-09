import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ui.dart';
import '../../providers/providers.dart';
import '../../widgets/cards.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(myBookingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My bookings')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myBookingsProvider),
        child: b.when(
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(icon: Icons.receipt_long_outlined, title: 'No bookings yet', subtitle: 'Book plumbing, cleaning, electrical & more from home.');
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
