import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/right_touch_header.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  String _selectedFilter = 'All';

  void _showHelpSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'RightTouch Help & Support',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F8EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF00A859)),
              ),
              title: const Text('Call Customer Support', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Direct toll-free customer helpline', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(const ClipboardData(text: '+919894169716'));
                showSuccess(context, title: 'Number Copied', message: 'Support helpline copied to clipboard');
              },
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help_outline_rounded, color: Color(0xFF2563EB)),
              ),
              title: const Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Learn about technician visits & warranty', style: TextStyle(fontSize: 12)),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = ref.watch(myBookingsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: RightTouchTopAppBar(
        title: 'Bookings',
        extraActions: [
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _showHelpSheet();
              },
              customBorder: const CircleBorder(),
              child: Ink(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.headset_mic_outlined,
                  color: Color(0xFF0F172A),
                  size: 19,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myBookingsProvider),
        color: const Color(0xFF00A859),
        child: b.when(
          data: (list) {
            // Filter logic
            final filteredList = list.where((item) {
              if (_selectedFilter == 'All') return true;
              if (_selectedFilter == 'Active') {
                return item.status.toLowerCase() == 'pending' || item.status.toLowerCase() == 'confirmed';
              }
              if (_selectedFilter == 'Completed') {
                return item.status.toLowerCase() == 'completed';
              }
              if (_selectedFilter == 'Cancelled') {
                return item.status.toLowerCase() == 'cancelled';
              }
              return true;
            }).toList();

            final activeBookings = filteredList
                .where((item) =>
                    item.status.toLowerCase() == 'pending' ||
                    item.status.toLowerCase() == 'confirmed')
                .toList();

            final historyBookings = filteredList
                .where((item) =>
                    item.status.toLowerCase() == 'completed' ||
                    item.status.toLowerCase() == 'cancelled')
                .toList();

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                // Filter dropdown matching Image 3
                Row(
                  children: [
                    const Text(
                      'Filter: ',
                      style: TextStyle(
                        fontSize: 14.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F172A)),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        items: ['All', 'Active', 'Completed', 'Cancelled']
                            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedFilter = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Section 1: Active & Upcoming (Matching Image 3)
                const Text(
                  'Active & Upcoming',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),

                if (activeBookings.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'No active bookings right now',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else ...[
                  ...activeBookings.map((bk) => _buildBookingCard(bk)),
                ],

                const SizedBox(height: 24),

                // Section 2: History (Matching Image 3)
                const Text(
                  'History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),

                if (historyBookings.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'No booking history',
                      style: TextStyle(
                        fontSize: 14.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else ...[
                  ...historyBookings.map((bk) => _buildBookingCard(bk)),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error loading bookings: $e'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.refresh(myBookingsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel bk) {
    final isPending = bk.status.toLowerCase() == 'pending';
    final isCompleted = bk.status.toLowerCase() == 'completed';
    final isConfirmed = bk.status.toLowerCase() == 'confirmed';

    final tagBg = isPending
        ? const Color(0xFFFFF7ED)
        : isCompleted
            ? const Color(0xFFE8F8EE)
            : isConfirmed
                ? const Color(0xFFEFF6FF)
                : const Color(0xFFFEF2F2);

    final tagColor = isPending
        ? const Color(0xFFEA580C)
        : isCompleted
            ? const Color(0xFF16A34A)
            : isConfirmed
                ? const Color(0xFF2563EB)
                : const Color(0xFFDC2626);

    final tagBorder = isPending
        ? const Color(0xFFFED7AA)
        : isCompleted
            ? const Color(0xFFBBF7D0)
            : isConfirmed
                ? const Color(0xFFBFDBFE)
                : const Color(0xFFFECACA);

    final statusText = isPending
        ? 'Pending Technician'
        : isCompleted
            ? 'Completed'
            : isConfirmed
                ? 'Confirmed'
                : 'Cancelled';

    final statusIcon = isPending
        ? Icons.hourglass_top_rounded
        : isCompleted
            ? Icons.check_circle_rounded
            : isConfirmed
                ? Icons.verified_rounded
                : Icons.cancel_rounded;

    final dateText = bk.scheduledAt != null ? fmtDate(bk.scheduledAt) : 'Slot Scheduled';
    final serviceTitle = (bk.serviceName != null && bk.serviceName!.trim().isNotEmpty)
        ? bk.serviceName!
        : 'RightTouch Home Service';

    final shortId = bk.id.length > 8 ? bk.id.substring(bk.id.length - 8).toUpperCase() : bk.id.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/booking/${bk.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Booking ID Tag + Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tag_rounded, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 3),
                          Text(
                            'BK-$shortId',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF334155),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tagBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tagBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 13, color: tagColor),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                statusText,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: tagColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Middle Row: Service Image / Icon + Title + Schedule + Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Icon/Image Container
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: (bk.image != null && bk.image!.startsWith('http'))
                            ? CachedNetworkImage(
                                imageUrl: bk.image!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(
                                  child: Icon(Icons.build_circle_rounded, color: AppColors.primary, size: 28),
                                ),
                                errorWidget: (_, __, ___) => const Center(
                                  child: Icon(Icons.home_repair_service_rounded, color: AppColors.primary, size: 28),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.home_repair_service_rounded, color: AppColors.primary, size: 28),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            serviceTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF64748B)),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  dateText,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (bk.addressLine != null && bk.addressLine!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    bk.addressLine!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // Technician assignment banner
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        bk.technicianName != null ? Icons.verified_user_rounded : Icons.support_agent_rounded,
                        size: 14,
                        color: bk.technicianName != null ? AppColors.primary : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          bk.technicianName != null
                              ? 'Assigned Expert: ${bk.technicianName}'
                              : 'Technician assigned 2 hrs prior to slot',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: bk.technicianName != null ? FontWeight.w700 : FontWeight.w500,
                            color: bk.technicianName != null ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Bottom Row: Price & Action CTA (Flexible to prevent any RenderFlex overflow)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bk.amount != null ? 'Total Cost' : 'Service Type',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            bk.amount != null ? '₹${bk.amount!.toInt()}' : 'Doorstep Inspection',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: bk.amount != null ? const Color(0xFF0F172A) : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
