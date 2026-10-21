import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_feedback.dart';
import '../../providers/providers.dart';
import '../../widgets/right_touch_header.dart';
import '../../../core/widgets/app_image.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final u = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cartCount = ref.watch(cartProvider).maybeWhen(
          data: (items) => items.fold<int>(0, (sum, it) => sum + it.qty),
          orElse: () => 0,
        );

    final isGuest = auth.isGuest && (u == null || u.id == 'guest_user' || u.id == 'guest');
    final userName = isGuest
        ? 'Guest Explorer'
        : ((u?.fullName.isNotEmpty == true)
            ? u!.fullName
            : ((u?.fname.isNotEmpty == true) ? '${u!.fname} ${u.lname}'.trim() : 'Customer'));
    final userEmail = isGuest
        ? Env.supportEmail
        : ((u?.email.isNotEmpty == true) ? u!.email : (u != null ? 'No email registered' : ''));
    final userPhone = isGuest
        ? Env.supportPhone
        : ((u?.mobile.isNotEmpty == true)
            ? u!.mobile
            : ((auth.mobile?.isNotEmpty == true) ? auth.mobile! : 'Not available'));
    final initial = isGuest ? 'G' : (userName.isNotEmpty ? userName[0].toUpperCase() : 'C');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const RightTouchTopAppBar(title: 'Profile'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 40),
        children: [
          // User Profile Card
          _buildUserProfileCard(
            context,
            isDark: isDark,
            isGuest: isGuest,
            userName: userName,
            userEmail: userEmail,
            userPhone: userPhone,
            initial: initial,
          ),

          const SizedBox(height: 14),

          // Shopping Cart & Checkout Card
          _buildCartCheckoutCard(context, isDark: isDark, cartCount: cartCount),

          const SizedBox(height: 20),

          // Account & Preferences Group
          _buildSectionHeader(
            title: 'Account & Preferences',
            subtitle: 'Manage your account settings',
            onViewAll: () => context.push('/account-settings'),
          ),
          const SizedBox(height: 10),
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
                subtitle: 'Updates on technician arrival, offers & more',
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
                icon: Icons.star_rate_rounded,
                title: 'My Ratings & Reviews',
                subtitle: 'Manage reviews for completed services & products',
                onTap: () => context.push('/ratings'),
              ),
              _buildListTile(
                context,
                icon: Icons.stars_rounded,
                title: 'RightTouch Rewards',
                subtitle: 'Cashback coins, earnings & redemption balance',
                onTap: () => context.push('/rewards'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Support & Legal Group
          _buildSectionHeader(
            title: 'Support & Legal',
            subtitle: "We're here to help you 24/7",
            onViewAll: () => context.push('/support-legal'),
          ),
          const SizedBox(height: 10),
          _buildCardGroup(
            isDark: isDark,
            children: [
              _buildListTile(
                context,
                icon: Icons.headset_mic_outlined,
                title: 'Help & Complaints Desk',
                subtitle: '24/7 doorstep resolution & support',
                onTap: () => context.push('/reports'),
              ),
              _buildListTile(
                context,
                icon: Icons.verified_user_outlined,
                title: 'RightTouch Guarantee & Warranty',
                subtitle: '30-Day doorstep re-service coverage',
                onTap: () => context.push('/warranty-info'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Need Help? Banner Card
          _buildNeedHelpBanner(context),

          const SizedBox(height: 22),

          // Action Buttons: Log Out & All Devices
          _buildActionButtons(context, ref),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // --- Profile Card ---
  Widget _buildUserProfileCard(
    BuildContext context, {
    required bool isDark,
    bool isGuest = false,
    required String userName,
    required String userEmail,
    required String userPhone,
    required String initial,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF064E3B), Color(0xFF1E293B)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8FAF2),
                  Color(0xFFF4FBF7),
                  Color(0xFFD8F5E7),
                ],
              ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF15803D) : const Color(0xFFB9F0D6),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A059669),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Info + Edit Profile
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with Camera Icon Overlay
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F059669),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Name, Email, Phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userPhone,
                      maxLines: 1,
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

              // Right Column: Edit Profile + Rewards Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: InkWell(
                      onTap: () {
                        if (isGuest) {
                          context.push('/login');
                        } else {
                          context.push('/edit-profile');
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isGuest ? const Color(0xFF16A34A) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isGuest ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isGuest ? Icons.login_rounded : Icons.edit,
                              size: 12,
                              color: isGuest ? Colors.white : const Color(0xFF0F172A),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isGuest ? 'Sign In' : 'Edit Profile',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isGuest ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: InkWell(
                      onTap: () {
                        if (isGuest) {
                          context.push('/login');
                        } else {
                          context.push('/rewards');
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFF59E0B),
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14D97706),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              size: 13,
                              color: Color(0xFFD97706),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Rewards',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

        ],
      ),
    );
  }

  // --- Shopping Cart & Checkout Card ---
  Widget _buildCartCheckoutCard(
    BuildContext context, {
    required bool isDark,
    required int cartCount,
  }) {
    return InkWell(
      onTap: () => context.push('/cart'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            // 3D Cart Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 64,
                height: 64,
                color: const Color(0xFFE8FAF2),
                child: const AppImage(
                  url: 'assets/images/cart_3d.jpg',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorWidget: Center(
                    child: Icon(Icons.shopping_cart_rounded, color: Color(0xFF16A34A), size: 30),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Middle Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shopping Cart & Checkout',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage items, apply coupons & checkout',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cartCount > 0
                            ? const Color(0xFFE8FAF2)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 11,
                            color: cartCount > 0
                                ? const Color(0xFF16A34A)
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cartCount > 0
                                ? '$cartCount item${cartCount > 1 ? "s" : ""} in cart'
                                : 'Cart is empty',
                            style: TextStyle(
                              fontSize: 10,
                              color: cartCount > 0
                                  ? const Color(0xFF16A34A)
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Chevron Button
            Container(
              width: 32,
              height: 32,
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

  // --- Section Header with View All ---
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required VoidCallback onViewAll,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: InkWell(
            onTap: onViewAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, color: Color(0xFF16A34A), size: 15),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Card Group Container ---
  Widget _buildCardGroup({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
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

  // --- List Tile Row with Mint Icon and Chevron Circle ---
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Mint Circle Icon Container
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B) : const Color(0xFFE8FAF2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF16A34A),
                size: 19,
              ),
            ),
            const SizedBox(width: 12),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Circular Chevron Button
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Need Help? Banner ---
  Widget _buildNeedHelpBanner(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/reports'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF15803D)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F064E3B),
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // Headset Badge (No human images as requested!)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0x2EFFFFFF),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Headline & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Need Help?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Chat with our support team',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFD1FAE5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // White Circular Arrow
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right,
                color: Color(0xFF065F46),
                size: 19,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Bottom Action Buttons ---
  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Log Out Button
        Expanded(
          child: OutlinedButton(
            onPressed: () => _confirmLogout(context, ref, allDevices: false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.logout_rounded, color: AppColors.danger, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Log Out',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // All Devices Button
        Expanded(
          child: OutlinedButton(
            onPressed: () => _confirmLogout(context, ref, allDevices: true),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.devices_outlined, color: Color(0xFF64748B), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'All Devices',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Dialogs & Actions ---
  Future<void> _confirmLogout(
    BuildContext context,
    WidgetRef ref, {
    required bool allDevices,
  }) async {
    final title = allDevices ? 'Log out of all devices?' : 'Log out?';
    final content = allDevices
        ? 'This will terminate all active sessions on other devices.'
        : 'Are you sure you want to log out of your account?';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(allDevices ? 'Log Out All' : 'Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout(allDevices: allDevices);
      if (context.mounted) {
        showSuccess(
          context,
          title: allDevices ? 'Logged Out All' : 'Logged Out',
          message: allDevices
              ? 'Logged out of all devices successfully.'
              : 'You have been logged out successfully.',
        );
        context.go('/login');
      }
    }
  }
}
