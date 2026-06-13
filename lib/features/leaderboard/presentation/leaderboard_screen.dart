import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dealsouk/features/requests/presentation/requests_providers.dart';
import 'package:dealsouk/features/leaderboard/presentation/leaderboard_providers.dart';
import 'package:dealsouk/features/profile/presentation/profile_providers.dart';
import 'package:dealsouk/features/tokens/presentation/tokens_providers.dart';
import 'package:dealsouk/features/leaderboard/domain/leaderboard_user.dart';
import 'package:dealsouk/features/tokens/domain/user_badge.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/features/requests/presentation/request_board_view.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  bool _showRequestBoard = false;

  @override
  void initState() {
    super.initState();
    // Fetch real data on screen open
    Future.microtask(() {
      ref.read(leaderboardProvider.notifier).fetch();
      ref.read(priceRequestsProvider.notifier).fetchBoard();
      ref.read(dailyChallengeProvider.notifier).fetchToday();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = ref.watch(userTokensProvider);
    final transactions = ref.watch(userTransactionsProvider);
    final profile = ref.watch(userProfileProvider);
    final streak = ref.watch(streakProvider);
    final badges = ref.watch(badgesProvider);
    final dailyChallenge = ref.watch(dailyChallengeProvider);

    // Use real leaderboard data; inject current user row if available
    final apiLeaderboard = ref.watch(leaderboardProvider);
    final leaderboard = apiLeaderboard.isEmpty
        ? <LeaderboardUser>[]
        : apiLeaderboard.map((user) {
            if (user.isCurrentUser) {
              return LeaderboardUser(
                rank: user.rank,
                name: '${profile.name} (You)',
                tokens: tokens > 0 ? tokens : user.tokens,
                isCurrentUser: true,
                streak: streak.currentStreak,
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
          streak: user.streak,
        );
      },
    );

    // Find current user's rank (handle empty/not found safely)
    final userRow = rankedLeaderboard.cast<LeaderboardUser?>().firstWhere(
      (u) => u != null && u.isCurrentUser,
      orElse: () => null,
    );
    final int userRank = userRow?.rank ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Clean Premium White/Light-Green Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          context.canPop() ? context.pop() : context.go('/'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE8EEE4),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.forestDeep,
                          size: 18,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Rewards & Leaderboard',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          color: AppTheme.forestDeep,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 40,
                    ), // Spacer to balance the back button
                  ],
                ),
              ),
            ),

            // Segmented Mode Toggle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _showRequestBoard = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_showRequestBoard
                                  ? AppTheme.forestDeep
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Leaderboard & Streaks',
                                style: TextStyle(
                                  color: !_showRequestBoard
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showRequestBoard = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _showRequestBoard
                                  ? AppTheme.forestDeep
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Active Request Board',
                                style: TextStyle(
                                  color: _showRequestBoard
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_showRequestBoard) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              const SliverToBoxAdapter(child: RequestBoardView()),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ] else ...[
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
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
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
                                child: ClipOval(
                                  child: profile.avatarUrl.isNotEmpty
                                      ? Image.network(
                                          profile.avatarUrl,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  CircleAvatar(
                                                    radius: 30,
                                                    backgroundColor: theme
                                                        .colorScheme
                                                        .primary
                                                        .withValues(alpha: 0.1),
                                                    child: Text(
                                                      profile.name.isNotEmpty
                                                          ? profile.name[0]
                                                          : 'H',
                                                      style: TextStyle(
                                                        color: theme
                                                            .colorScheme
                                                            .primary,
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                        )
                                      : CircleAvatar(
                                          radius: 30,
                                          backgroundColor: theme
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.1),
                                          child: Text(
                                            profile.name.isNotEmpty
                                                ? profile.name[0]
                                                : 'H',
                                            style: TextStyle(
                                              color: theme.colorScheme.primary,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.name,
                                      style: const TextStyle(
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
                                            color: AppTheme.amberAccent
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                                userRank > 0
                                                    ? 'Rank #$userRank'
                                                    : 'Rank —',
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
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                ref.read(navbarVisibleProvider.notifier).hide();
                                showModalBottomSheet(
                                  context: context,
                                  useRootNavigator: true,
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
                                        MediaQuery.of(
                                              context,
                                            ).viewInsets.bottom +
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
                                              borderRadius:
                                                  BorderRadius.circular(2.5),
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
                                              borderRadius:
                                                  BorderRadius.circular(16),
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
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            style: ElevatedButton.styleFrom(
                                              minimumSize: const Size(
                                                double.infinity,
                                                50,
                                              ),
                                            ),
                                            child: const Text(
                                              'Back to Rewards',
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ).whenComplete(() {
                                  ref.read(navbarVisibleProvider.notifier).show();
                                });
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
                        'Shopper Badges',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Badges horizontal slider (live from badgesProvider)
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: badges
                        .map((badge) => _liveBadgeCard(badge, theme))
                        .toList(),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () => context.push('/submit-price'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: dailyChallenge.completed
                            ? const Color(0xFFE8F5E9)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: dailyChallenge.completed
                              ? AppTheme.forestDeep
                              : const Color(0xFFE8EEE4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: dailyChallenge.completed
                                      ? AppTheme.forestDeep
                                      : AppTheme.limeAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  dailyChallenge.completed
                                      ? Icons.check_rounded
                                      : Icons.flag_circle_outlined,
                                  color: dailyChallenge.completed
                                      ? Colors.white
                                      : AppTheme.forestDeep,
                                  size: 17,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  dailyChallenge.description,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.amberAccent.withValues(
                                    alpha: 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  dailyChallenge.completed
                                      ? 'Done! +${dailyChallenge.bonusTokens}T'
                                      : '+${dailyChallenge.bonusTokens} bonus tokens',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFC77C02),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!dailyChallenge.completed) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value:
                                    (dailyChallenge.progressCount /
                                            dailyChallenge.targetCount)
                                        .clamp(0.0, 1.0),
                                backgroundColor: Colors.grey.shade100,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.forestDeep,
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${dailyChallenge.progressCount}/${dailyChallenge.targetCount} done • Tap to submit a price',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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

                            // Streak flame
                            if (user.streak > 0) ...[
                              const Icon(
                                Icons.local_fire_department,
                                color: Colors.orange,
                                size: 14,
                              ),
                              Text(
                                '${user.streak}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
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
          ],
        ),
      ),
    );
  }

  Widget _liveBadgeCard(UserBadge badge, ThemeData theme) {
    return Opacity(
      opacity: badge.unlocked ? 1.0 : 0.45,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(right: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: badge.unlocked
                ? AppTheme.amberAccent.withValues(alpha: 0.5)
                : Colors.grey.shade200,
          ),
        ),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: badge.unlocked
                          ? AppTheme.amberLight
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  if (!badge.unlocked)
                    const Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                badge.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: badge.unlocked ? AppTheme.textDark : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
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
