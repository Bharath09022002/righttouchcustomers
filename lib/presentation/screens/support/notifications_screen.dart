import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/widgets/ui.dart';
import '../../providers/providers.dart';
import '../../widgets/guest_login_placeholder.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth.isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const GuestLoginPlaceholder(
          icon: Icons.notifications_none_outlined,
          title: 'Sign In to View Notifications',
          subtitle: 'Please log in with your phone number to receive alerts on technician arrival, booking updates, and exclusive offers.',
          primaryButtonText: 'Log In / Sign Up',
        ),
      );
    }

    final n = ref.watch(notificationListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(gatewayProvider).markAllRead();
              ref.invalidate(notificationListProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: n.when(
        data: (list) {
          if (list.isEmpty) return const EmptyState(icon: Icons.notifications_outlined, title: 'All caught up', subtitle: 'Booking updates, offers and payment alerts appear here.');
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final x = list[i];
              String when = '';
              try {
                if (x.createdAt != null) when = timeago.format(DateTime.parse(x.createdAt.toString()));
              } catch (_) {}
              return Card(
                child: ListTile(
                  leading: Icon(x.read ? Icons.notifications_outlined : Icons.notifications_active, color: x.read ? null : const Color(0xFF16A34A)),
                  title: Text(x.title, style: TextStyle(fontWeight: x.read ? FontWeight.w500 : FontWeight.w800)),
                  subtitle: Text('${x.body}\n$when'),
                  isThreeLine: true,
                  onTap: () async {
                    await ref.read(gatewayProvider).markRead(x.id);
                    ref.invalidate(notificationListProvider);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: RtLoader()),
        error: (e, _) => ErrorView(message: '$e', onRetry: () => ref.invalidate(notificationListProvider)),
      ),
    );
  }
}
