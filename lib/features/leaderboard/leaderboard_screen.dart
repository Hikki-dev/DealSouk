import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/state.dart';
import '../../core/mock_data/mock_data.dart';
import '../../core/models/models.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/souk_widgets.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = ref.watch(userTokensProvider);
    final transactions = ref.watch(userTransactionsProvider);

    // Initial leaderboard list from mock data
    final baseLeaderboard = MockData.initialLeaderboard;
    // Replace the current user tokens dynamically in the leaderboard list
    final leaderboard = baseLeaderboard.map((user) {
      if (user.isCurrentUser) {
        // Find Hessa's rank dynamically. We can recalculate it or just display rank #7
        return LeaderboardUser(
          rank: user.rank,
          name: user.name,
          tokens: tokens,
          isCurrentUser: true,
        );
      }
      return user;
    }).toList();

    // Sort leaderboard by tokens descending, update ranks
    leaderboard.sort((a, b) => b.tokens.compareTo(a.tokens));
    final rankedLeaderboard = List<LeaderboardUser>.generate(
      leaderboard.length,
      (index) {
        final user = leaderboard[index];
        return LeaderboardUser(
          rank: index + 1,
          name: user.name,
          tokens: user.tokens,
          isCurrentUser: user.isCurrentUser,
        );
      },
    );

    // Find current user's rank
    final int userRank = rankedLeaderboard
        .firstWhere((u) => u.isCurrentUser)
        .rank;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Dark forest header with scallop trim ──
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: AppTheme.forestDeep,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + 14,
                    16,
                    16,
                  ),
                  child: const Text(
                    'Rewards & Ranks',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Stack(
                  children: [
                    Container(height: 18, color: AppTheme.background),
                    ClipPath(
                      clipper: const ScallopClipper.down(scallopRadius: 9),
                      child: Container(height: 18, color: AppTheme.forestDeep),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),

          // Top Profile Card Deck
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.06),
                      theme.colorScheme.primary.withValues(alpha: 0.01),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              child: Text(
                                'H',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hessa Al Maktoum',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.amberAccent.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.stars,
                                            color: AppTheme.amberAccent,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Rank #$userRank',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFC77C02),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.local_fire_department,
                                            color: Colors.orange,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '5 Day Streak',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$tokens',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.primary,
                                  height: 1.1,
                                ),
                              ),
                              const Text(
                                'Tokens',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // Progress Card to next voucher
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'AED 50 Union Coop Voucher',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            '$tokens / 500 T',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (tokens / 500).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (tokens >= 500) ...[
                        ElevatedButton.icon(
                          onPressed: () {
                            // Deduct tokens and log transaction
                            ref
                                .read(userTokensProvider.notifier)
                                .deductTokens(500);
                            ref
                                .read(userTransactionsProvider.notifier)
                                .addTransaction(
                                  -500,
                                  'Redeemed AED 50 Union Coop Voucher',
                                );

                            // Show claimed code popup
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.white,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(28),
                                ),
                              ),
                              builder: (context) {
                                return Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    24.0,
                                    24.0,
                                    24.0,
                                    MediaQuery.of(context).viewInsets.bottom +
                                        32.0,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(
                                            2.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 54,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Voucher Claimed!',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Show the barcode or code below to the cashier at any Union Coop checkout in Dubai.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            // Mock Barcode Lines
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: List.generate(24, (
                                                index,
                                              ) {
                                                final double width =
                                                    (index % 3 == 0)
                                                    ? 4.0
                                                    : (index % 2 == 0)
                                                    ? 2.0
                                                    : 1.0;
                                                final double spacing =
                                                    (index % 4 == 0)
                                                    ? 3.0
                                                    : 1.5;
                                                return Container(
                                                  width: width,
                                                  height: 48,
                                                  margin: EdgeInsets.only(
                                                    right: spacing,
                                                  ),
                                                  color: Colors.black87,
                                                );
                                              }),
                                            ),
                                            const SizedBox(height: 12),
                                            const SelectableText(
                                              'DS-50-UCOOP-8X92',
                                              style: TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 2,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(
                                            double.infinity,
                                            50,
                                          ),
                                        ),
                                        child: const Text('Back to Rewards'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          icon: const Icon(
                            Icons.confirmation_num_outlined,
                            size: 18,
                          ),
                          label: const Text('Claim Voucher Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.amberAccent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Earn ${500 - tokens} more tokens to redeem your voucher.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Achievement Badges Row Label
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: AppTheme.amberAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sourcer Badges',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Badges horizontal slider
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _badgeCard(
                    Icons.workspace_premium,
                    'First Submission',
                    'Awarded on first pricing upload',
                    theme,
                  ),
                  _badgeCard(
                    Icons.local_fire_department,
                    '7 Day Streak',
                    'Submitted daily for a week',
                    theme,
                  ),
                  _badgeCard(
                    Icons.verified_user,
                    'Verified Sourcer',
                    'Over 95% price accuracy rating',
                    theme,
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.flag_circle_outlined,
                    color: AppTheme.forestDeep,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Today\'s Challenges',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _challengeCard(
                    Icons.receipt_long_outlined,
                    'Upload 2 receipts',
                    '+30 tokens',
                    '1 / 2 done',
                  ),
                  _challengeCard(
                    Icons.storefront_outlined,
                    'Visit one nearby store',
                    '+20 tokens',
                    'Dubai Marina',
                  ),
                  _challengeCard(
                    Icons.verified_outlined,
                    'Verify 3 fresh prices',
                    '+25 tokens',
                    'Expires tonight',
                  ),
                ],
              ),
            ),
          ),

          // Hall of Fame Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 10.0),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: AppTheme.amberAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Last Month\'s Champions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _hallOfFameCard(
                    2,
                    'Meera',
                    '980',
                    const Color(0xFFC0C0C0),
                    theme,
                  ),
                  const SizedBox(width: 8),
                  _hallOfFameCard(
                    1,
                    'Khalid',
                    '1,240',
                    const Color(0xFFFFD700),
                    theme,
                  ),
                  const SizedBox(width: 8),
                  _hallOfFameCard(
                    3,
                    'Ahmed',
                    '750',
                    const Color(0xFFCD7F32),
                    theme,
                  ),
                ],
              ),
            ),
          ),

          // Leaderboard Label
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.leaderboard_rounded,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Dubai Leaderboard',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Leaderboard list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final user = rankedLeaderboard[index];
                final isMe = user.isCurrentUser;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isMe
                      ? theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.25,
                        )
                      : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isMe
                          ? theme.colorScheme.primary
                          : Colors.grey.shade100,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        // Rank Circle
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _getRankColor(user.rank),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${user.rank}',
                            style: TextStyle(
                              color: user.rank <= 3
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Name
                        Expanded(
                          child: Text(
                            user.name,
                            style: TextStyle(
                              fontWeight: isMe
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isMe
                                  ? theme.colorScheme.primary
                                  : Colors.black87,
                            ),
                          ),
                        ),

                        // Tokens display
                        Row(
                          children: [
                            Text(
                              '${user.tokens}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.bolt,
                              color: AppTheme.amberAccent,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: rankedLeaderboard.length),
            ),
          ),

          // Token History Section Label
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Token History',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Token transactions list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final tx = transactions[index];
                final isPositive = tx.amount > 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(
                      tx.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      tx.timestampLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    trailing: Text(
                      isPositive ? '+${tx.amount}' : '${tx.amount}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: isPositive
                            ? AppTheme.emeraldPrimary
                            : Colors.red,
                      ),
                    ),
                  ),
                );
              }, childCount: transactions.length),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _hallOfFameCard(
    int rank,
    String name,
    String tokenStr,
    Color medalColor,
    ThemeData theme,
  ) {
    final isFirst = rank == 1;
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isFirst ? 20 : 16,
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: medalColor.withValues(alpha: 0.35),
            width: isFirst ? 1.5 : 1,
          ),
          boxShadow: isFirst
              ? [
                  BoxShadow(
                    color: medalColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: medalColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: medalColor.computeLuminance() > 0.55
                      ? AppTheme.forestDeep
                      : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: isFirst ? 13 : 12,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt, size: 10, color: AppTheme.amberAccent),
                const SizedBox(width: 2),
                Text(
                  tokenStr,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeCard(
    IconData icon,
    String title,
    String subtitle,
    ThemeData theme,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(right: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.amberLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.amberAccent, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _challengeCard(
    IconData icon,
    String title,
    String reward,
    String status,
  ) {
    return Container(
      width: 162,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppTheme.limeAccent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.forestDeep, size: 17),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                reward,
                style: const TextStyle(
                  color: AppTheme.forestDeep,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey.shade100;
    }
  }
}
