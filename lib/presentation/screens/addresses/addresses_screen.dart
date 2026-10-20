import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/storage/local_cache.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/guest_login_placeholder.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth.isGuest) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('My addresses'), backgroundColor: Colors.white, elevation: 0),
        body: const GuestLoginPlaceholder(
          icon: Icons.location_on_outlined,
          title: 'Sign In to View Addresses',
          subtitle: 'Please log in with your phone number to save, edit, and manage your delivery and service addresses.',
          primaryButtonText: 'Log In / Sign Up',
        ),
      );
    }

    final a = ref.watch(addressListProvider);
    final selected = ref.watch(selectedAddressProvider);

    Future<void> makeDefault(AddressModel x) async {
      try {
        await ref.read(addressRepoProvider).setDefault(x);
        await LocalCacheService.instance.cacheDefaultAddressId(x.id);
        ref.read(selectedAddressProvider.notifier).state = x;
        ref.invalidate(addressListProvider);
        if (context.mounted) {
          showSuccess(
            context,
            title: 'Default Address Set',
            message: '${x.type} is now your default address. It will remain selected until you change it.',
          );
        }
      } catch (e) {
        if (context.mounted) {
          final appErr = mapException(e);
          showError(context, title: 'Action Failed', message: appErr.userMessage);
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Addresses'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-address'),
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
        label: const Text('Add Address', style: TextStyle(fontWeight: FontWeight.w700)),
        icon: const Icon(Icons.add_location_alt_outlined),
      ),
      body: a.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.location_on_outlined,
              title: 'No addresses saved',
              subtitle: 'Add your home or work address for quick booking and technician service delivery.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final x = list[i];
              final isCurrentDefault = x.isDefault || selected?.id == x.id;

              return InkWell(
                onTap: () => makeDefault(x),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrentDefault ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                      width: isCurrentDefault ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isCurrentDefault
                            ? const Color(0xFF16A34A).withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.03),
                        blurRadius: isCurrentDefault ? 10 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Radio check indicator
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          isCurrentDefault
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isCurrentDefault
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF94A3B8),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Address info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  x.type.toLowerCase() == 'work'
                                      ? Icons.work_outline
                                      : Icons.home_outlined,
                                  size: 16,
                                  color: const Color(0xFF475569),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  x.type.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                if (isCurrentDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                    ),
                                    child: const Text(
                                      'DEFAULT',
                                      style: TextStyle(
                                        color: Color(0xFF059669),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              x.line,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${x.city}, ${x.state} - ${x.pincode}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Actions popup menu
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Color(0xFF64748B), size: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        itemBuilder: (_) => [
                          if (!isCurrentDefault)
                            const PopupMenuItem(
                              value: 'default',
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF16A34A)),
                                  SizedBox(width: 10),
                                  Text('Set as default'),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'use',
                            child: Row(
                              children: [
                                Icon(Icons.done, size: 18, color: Color(0xFF0F172A)),
                                SizedBox(width: 10),
                                Text('Select address'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'del',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                                SizedBox(width: 10),
                                Text('Delete', style: TextStyle(color: Color(0xFFDC2626))),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (v) async {
                          if (v == 'default' || v == 'use') {
                            await makeDefault(x);
                            if (v == 'use' && context.mounted) {
                              Navigator.pop(context);
                            }
                          } else if (v == 'del') {
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
                    ],
                  ),
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
