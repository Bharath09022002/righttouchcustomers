import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/right_touch_header.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: const RightTouchTopAppBar(title: 'Account & Preferences'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildCardGroup(
            isDark: isDark,
            children: [
              _buildListTile(
                context,
                icon: Icons.location_on_outlined,
                title: 'Saved Addresses',
                subtitle: 'Manage delivery & service locations',
                onTap: () => context.push('/addresses'),
              ),
              _buildListTile(
                context,
                icon: Icons.credit_card_outlined,
                title: 'Payment Receipts & History',
                subtitle: 'Invoices, Razorpay transactions & bills',
                onTap: () => context.push('/payments'),
              ),
              _buildListTile(
                context,
                icon: Icons.notifications_none_outlined,
                title: 'Notifications',
                subtitle: 'Technician arrival, order updates & alerts',
                onTap: () => context.push('/notifications'),
              ),
              _buildListTile(
                context,
                icon: Icons.request_quote_outlined,
                title: 'Product Quotations & Orders',
                subtitle: 'Custom equipment quotes, status & orders',
                onTap: () => context.push('/quotations'),
              ),
              _buildListTile(
                context,
                icon: Icons.person_outline_rounded,
                title: 'Edit Profile Information',
                subtitle: 'Name, phone number & contact details',
                onTap: () => context.push('/edit-profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardGroup({required bool isDark, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                indent: 64,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B) : const Color(0xFFE8FAF2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF16A34A), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right,
                size: 18,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
