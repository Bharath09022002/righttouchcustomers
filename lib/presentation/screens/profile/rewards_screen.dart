import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/guest_login_placeholder.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (auth.isGuest) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('RightTouch Rewards'),
          centerTitle: false,
        ),
        body: const GuestLoginPlaceholder(
          icon: Icons.stars_rounded,
          title: 'Sign In to View Rewards',
          subtitle:
              'Log in with your mobile number to view your earned cashback coins, transaction history, and redemption balance.',
          primaryButtonText: 'Log In / Sign Up',
        ),
      );
    }

    final balanceAsync = ref.watch(rewardBalanceProvider);
    final historyAsync = ref.watch(rewardHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'RightTouch Rewards',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Reconcile Balance',
            onPressed: () async {
              try {
                await ref.read(rewardRepoProvider).reconcile();
                ref.invalidate(rewardBalanceProvider);
                ref.invalidate(rewardHistoryProvider);
                if (context.mounted) {
                  showSuccess(
                    context,
                    title: 'Balance Reconciled',
                    message: 'Your reward balance and transactions have been synced.',
                  );
                }
              } catch (_) {
                ref.invalidate(rewardBalanceProvider);
                ref.invalidate(rewardHistoryProvider);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Balance',
            onPressed: () {
              ref.invalidate(rewardBalanceProvider);
              ref.invalidate(rewardHistoryProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(rewardBalanceProvider);
          ref.invalidate(rewardHistoryProvider);
          await Future.wait([
            ref.read(rewardBalanceProvider.future),
            ref.read(rewardHistoryProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
          children: [
            // Hero Balance Card
            balanceAsync.when(
              data: (balance) => _buildHeroCard(context, balance),
              loading: () => Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => _buildHeroCard(
                context,
                const RewardBalanceModel(),
              ),
            ),

            const SizedBox(height: 18),

            // How Rewards Work Info Box
            _buildHowItWorksCard(),

            const SizedBox(height: 22),

            // Ledger / History Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reward Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                historyAsync.maybeWhen(
                  data: (items) => Text(
                    '${items.length} ${items.length == 1 ? "record" : "records"}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // History Transactions
            historyAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEF3C7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.stars_rounded,
                            size: 32,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No coin transactions yet',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Coins will be automatically credited to your wallet whenever you complete and pay for a service booking.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final tx = items[i];
                    return _buildTransactionCard(tx);
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Failed to load reward history: $err',
                        style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Hero Balance Card ---
  Widget _buildHeroCard(BuildContext context, RewardBalanceModel balance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF064E3B), // Deep Forest Emerald
            Color(0xFF0F766E), // Teal Accent
            Color(0xFF134E4A),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33064E3B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFBBF24), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFFFBBF24),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'RightTouch Coins',
                    style: TextStyle(
                      color: Color(0xFFD1FAE5),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Text(
                  '100 Coins = ₹1.00',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${balance.availableCoins}',
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Coins',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFA7F3D0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '≈ ₹${balance.rupees.toStringAsFixed(2)} Cashback Value',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6EE7B7),
                  ),
                ),
              ),
              if (balance.reservedCoins > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '(${balance.reservedCoins} reserved)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Lifetime Earned', '+${balance.lifetimeEarned}', const Color(0xFF6EE7B7)),
                Container(width: 1, height: 26, color: Colors.white.withValues(alpha: 0.15)),
                _buildStatItem('Redeemed', '${balance.lifetimeRedeemed}', Colors.white70),
                Container(width: 1, height: 26, color: Colors.white.withValues(alpha: 0.15)),
                _buildStatItem('Expired', '${balance.lifetimeExpired}', Colors.white54),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFFD1FAE5),
          ),
        ),
      ],
    );
  }

  // --- How It Works Card ---
  Widget _buildHowItWorksCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'How RightTouch Rewards Work',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRuleRow(
            icon: Icons.payments_outlined,
            title: 'Earn on Completed Bookings',
            subtitle: 'Coins automatically credit after technician completion and payment.',
          ),
          const SizedBox(height: 8),
          _buildRuleRow(
            icon: Icons.currency_rupee_rounded,
            title: 'Transparent Coin Value',
            subtitle: '100 Coins equal ₹1.00 directly in cash savings.',
          ),
          const SizedBox(height: 8),
          _buildRuleRow(
            icon: Icons.shield_outlined,
            title: 'Reliable Ledger',
            subtitle: 'Every coin credit or debit is permanently recorded and visible here.',
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF16A34A)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.35),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                TextSpan(text: subtitle),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Transaction Card ---
  Widget _buildTransactionCard(RewardTransactionModel tx) {
    final isEarn = tx.type == 'EARN';
    final isRedeem = tx.type == 'REDEEM';
    final isReversal = tx.type == 'REVERSAL';

    final Color badgeColor = isEarn
        ? const Color(0xFF16A34A)
        : (isRedeem ? const Color(0xFFD97706) : (isReversal ? Colors.red : const Color(0xFF64748B)));

    final String prefix = isEarn ? '+' : (isRedeem || isReversal ? '-' : '');

    String when = '';
    if (tx.createdAt != null) {
      try {
        when = timeago.format(tx.createdAt!);
      } catch (_) {}
    }

    final titleText = tx.note.isNotEmpty
        ? tx.note
        : (isEarn
            ? 'Service Reward Earned'
            : (isRedeem ? 'Coins Redeemed' : (isReversal ? 'Reward Reversal' : 'Coins Expired')));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEarn
                  ? Icons.arrow_downward_rounded
                  : (isRedeem ? Icons.arrow_upward_rounded : Icons.history_rounded),
              color: badgeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (when.isNotEmpty) ...[
                      Text(
                        when,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 6),
                      const Text('•', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      'Bal: ${tx.balanceAfterCoins} coins',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$prefix${tx.coins} Coins',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                  color: badgeColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '≈ ₹${tx.rupees.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
