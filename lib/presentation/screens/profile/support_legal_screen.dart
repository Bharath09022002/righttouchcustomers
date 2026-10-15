import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/env.dart';
import '../../widgets/right_touch_header.dart';

class SupportLegalScreen extends ConsumerWidget {
  const SupportLegalScreen({super.key});

  Future<void> _callSupport() async {
    final uri = Uri.parse('tel:${Env.supportPhone.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _emailSupport() async {
    final uri = Uri.parse('mailto:${Env.supportEmail}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: const RightTouchTopAppBar(title: 'Support & Legal'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Section 1: Customer Support
          Text(
            'Customer Assistance',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          _buildCardGroup(
            isDark: isDark,
            children: [
              _buildListTile(
                context,
                icon: Icons.headset_mic_outlined,
                title: 'Help & Complaints Desk',
                subtitle: 'Raise and track support tickets & issues',
                onTap: () => context.push('/reports'),
              ),
              _buildListTile(
                context,
                icon: Icons.verified_user_outlined,
                title: 'RightTouch Guarantee & Warranty',
                subtitle: '30-day doorstep re-service coverage details',
                onTap: () => context.push('/warranty-info'),
              ),
              _buildListTile(
                context,
                icon: Icons.phone_in_talk_outlined,
                title: 'Call Customer Support',
                subtitle: Env.supportPhone,
                onTap: _callSupport,
              ),
              _buildListTile(
                context,
                icon: Icons.email_outlined,
                title: 'Email Support Team',
                subtitle: Env.supportEmail,
                onTap: _emailSupport,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Section 2: Legal & Compliance
          Text(
            'Terms & Compliance',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          _buildCardGroup(
            isDark: isDark,
            children: [
              _buildListTile(
                context,
                icon: Icons.gavel_outlined,
                title: 'Terms of Service',
                subtitle: 'User agreement, booking conditions & terms',
                onTap: () => _showTermsSheet(context),
              ),
              _buildListTile(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'How we protect and manage your personal data',
                onTap: () => _showPrivacySheet(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTermsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Service',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            const Text(
              'RightTouch provides doorstep repair, installation, and maintenance services. '
              'All bookings are subject to technician availability in your service zone. '
              'Standard payment terms apply upon job completion unless prepaid online.',
              style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            const Text(
              'We value your privacy. RightTouch collects your phone number, delivery address, '
              'and booking details strictly to dispatch certified technicians and manage orders. '
              'We never sell your data to third parties.',
              style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
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
