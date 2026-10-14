import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/ui/app_feedback.dart';
import '../../providers/providers.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(addressListProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('My addresses'), backgroundColor: Colors.white, elevation: 0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-address'),
        label: const Text('Add address'),
        icon: const Icon(Icons.add),
      ),
      body: a.when(
        data: (list) {
          if (list.isEmpty) return const EmptyState(icon: Icons.location_on_outlined, title: 'No addresses', subtitle: 'Save home / work addresses for faster booking + GPS zone checks.');
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final x = list[i];
              return Card(
                child: ListTile(
                  leading: Icon(x.type.toLowerCase() == 'work' ? Icons.work_outline : Icons.home_outlined),
                  title: Text('${x.type} • ${x.line}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  subtitle: Text('${x.city}, ${x.state} ${x.pincode}${x.isDefault ? ' • DEFAULT' : ''}'),
                  trailing: PopupMenuButton(
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'use', child: Text('Use for booking')),
                      PopupMenuItem(value: 'default', child: Text('Set default')),
                      PopupMenuItem(value: 'del', child: Text('Delete')),
                    ],
                    onSelected: (v) async {
                      if (v == 'use') {
                        ref.read(selectedAddressProvider.notifier).state = x;
                        Navigator.pop(context);
                      } else if (v == 'default') {
                        try {
                          await ref.read(addressRepoProvider).setDefault(x);
                          ref.invalidate(addressListProvider);
                          if (context.mounted) {
                            showSuccess(context, title: 'Default Address', message: '${x.type} set as default address.');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            final appErr = mapException(e);
                            showError(context, title: 'Action Failed', message: appErr.userMessage);
                          }
                        }
                      } else {
                        if (x.isDefault) {
                          showError(
                            context,
                            title: 'Default Address',
                            message: 'This is currently your default address. Please set another address as default first before deleting.',
                          );
                          return;
                        }
                        try {
                          await ref.read(addressRepoProvider).remove(x.id);
                          ref.invalidate(addressListProvider);
                          if (context.mounted) {
                            showSuccess(context, title: 'Address Removed', message: 'Address removed successfully.');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            final raw = e.toString().replaceAll('ApiException:', '').trim();
                            final msg = raw.isNotEmpty && !raw.contains('Instance of')
                                ? raw
                                : mapException(e).userMessage;
                            showError(context, title: 'Action Failed', message: msg);
                          }
                        }
                      }
                    },
                  ),
                  onTap: () {
                    ref.read(selectedAddressProvider.notifier).state = x;
                    showSuccess(context, title: 'Address Selected', message: '${x.type} selected for booking.');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: RtLoader()),
        error: (e, _) => ErrorView(message: '$e', onRetry: () => ref.invalidate(addressListProvider)),
      ),
    );
  }
}
