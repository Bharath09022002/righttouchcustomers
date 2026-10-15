import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/right_touch_header.dart';

class WarrantyInfoScreen extends ConsumerWidget {
  const WarrantyInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: const RightTouchTopAppBar(title: 'Warranty & Guarantee'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
        children: [
          // Hero Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      colors: [Color(0xFF064E3B), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFE8FAF2), Color(0xFFD1FAE5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC),
                width: 1.2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RightTouch 30-Day Guarantee',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF064E3B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete doorstep peace of mind on all service repairs, installations, and genuine product deliveries.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E3A2B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 1: 30-Day Doorstep Service Guarantee
          _buildInfoCard(
            context,
            isDark: isDark,
            icon: Icons.replay_circle_filled_rounded,
            title: '30-Day Free Re-Service',
            description:
                'If the exact same issue reoccurs within 30 days of service completion, a senior certified technician will visit and resolve it at ₹0 extra cost.',
            bulletPoints: const [
              'Zero technician dispatch or diagnostic fees',
              'Priority slot assignment within 24 hours',
              'Post-service quality check on all repairs',
            ],
          ),

          const SizedBox(height: 16),

          // Section 2: Genuine Parts Assurance
          _buildInfoCard(
            context,
            isDark: isDark,
            icon: Icons.shield_outlined,
            title: '100% Genuine Spare Parts',
            description:
                'We source directly from original equipment manufacturers. Every replacement part comes with itemized digital billing and manufacturer warranty.',
            bulletPoints: const [
              'Direct brand procurement (Exide, Luminous, Microtek, Havells)',
              'Up to 12 months manufacturer warranty on replaced components',
              'No counterfeit or unverified third-party components',
            ],
          ),

          const SizedBox(height: 16),

          // Section 3: Manufacturer Product Warranties
          _buildInfoCard(
            context,
            isDark: isDark,
            icon: Icons.inventory_2_outlined,
            title: 'Manufacturer Product Warranty',
            description:
                'All equipment and appliances purchased through RightTouch include full manufacturer warranty coverage registered automatically with your digital invoice.',
            bulletPoints: const [
              'Solar Panels: 10–25 Years performance warranty',
              'Inverters & UPS: 2–5 Years replacement warranty',
              'Solar Batteries: 3–5 Years warranty coverage',
              'RightTouch handles warranty claims & doorstep service coordination',
            ],
          ),

          const SizedBox(height: 20),

          // Section 4: How to claim
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to Claim Warranty',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                _buildStepRow(
                  number: '1',
                  title: 'Select Job or Order',
                  description: 'Open Bookings or Help Desk and choose your past booking.',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildStepRow(
                  number: '2',
                  title: 'Tap "Report Issue"',
                  description: 'Describe the symptom or upload a photo of the defect.',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildStepRow(
                  number: '3',
                  title: 'Doorstep Resolution',
                  description: 'A technician arrives at your selected slot to fix the issue.',
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: () => context.push('/reports'),
              icon: const Icon(Icons.headset_mic_outlined, size: 20),
              label: const Text(
                'Raise a Warranty Claim',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String description,
    required List<String> bulletPoints,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B) : const Color(0xFFE8FAF2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF16A34A), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          for (final bullet in bulletPoints) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bullet,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String number,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF16A34A),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
