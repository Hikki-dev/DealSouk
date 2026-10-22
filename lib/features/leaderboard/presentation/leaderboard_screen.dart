import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/features/requests/presentation/requests_providers.dart';
import 'package:dealsouk/features/leaderboard/presentation/leaderboard_providers.dart';
import 'package:dealsouk/features/profile/presentation/profile_providers.dart';
import 'package:dealsouk/features/tokens/presentation/tokens_providers.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/features/leaderboard/domain/leaderboard_user.dart';
import 'package:dealsouk/features/tokens/domain/user_badge.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/features/requests/presentation/request_board_view.dart';
import 'package:dealsouk/core/widgets/souk_widgets.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

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
    final l = AppLocalizations.of(context)!;
    final tokens = ref.watch(userTokensProvider);
    // R4: voucher redemption threshold is admin-configurable (FR-40/61) — read
    // it from settings instead of hardcoding 500 so the two can't drift.
    final voucherThreshold = ref.watch(adminSettingsProvider).voucherThreshold;
    final profile = ref.watch(userProfileProvider);
    final streak = ref.watch(streakProvider);
    final badges = ref.watch(badgesProvider);
    final dailyChallenge = ref.watch(dailyChallengeProvider);
    final stats = ref.watch(userStatsProvider);

    // FR-45: previous month's top 3 (Hall of Fame).
    final hallOfFame =
        ref.watch(hallOfFameProvider).asData?.value ??
        const <LeaderboardUser>[];

    // Use real leaderboard data; inject current user row if available
    final apiLeaderboard = ref.watch(leaderboardProvider);
    final leaderboard = apiLeaderboard.isEmpty
        ? <LeaderboardUser>[]
        : apiLeaderboard.map((user) {
            if (user.isCurrentUser) {
              return LeaderboardUser(
                rank: user.rank,
                name: l.leaderYouMarker(profile.name),
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
                        child: const DirectionalIcon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.forestDeep,
                          size: 18,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l.leaderRewardsTitle,
                        textAlign: TextAlign.center,
                        style: AppFonts.display(
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
                                l.leaderToggleStreaks,
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
                                l.leaderToggleRequestBoard,
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
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: 110 + MediaQuery.of(context).padding.bottom,
                ),
              ),
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
                                                    ? l.leaderRankNumber(
                                                        userRank,
                                                      )
                                                    : l.leaderRankUnknown,
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
                                                l.leaderDayStreak(5),
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
                                  Text(
                                    l.leaderTokensLabel,
                                    style: const TextStyle(
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
                              Text(
                                l.leaderVoucherName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text(
                                l.leaderTokenProgress(tokens, voucherThreshold),
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
                              value: (tokens / voucherThreshold).clamp(
                                0.0,
                                1.0,
                              ),
                              backgroundColor: Colors.grey.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (tokens >= voucherThreshold) ...[
                            ElevatedButton.icon(
                              onPressed: () {
                                // Deduct tokens and log transaction
                                ref
                                    .read(userTokensProvider.notifier)
                                    .deductTokens(voucherThreshold);
                                ref
                                    .read(userTransactionsProvider.notifier)
                                    .addTransaction(
                                      -voucherThreshold,
                                      l.leaderVoucherRedeemed,
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
                                    final l = AppLocalizations.of(context)!;
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
                                          Text(
                                            l.leaderVoucherClaimedTitle,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            l.leaderVoucherClaimedBody,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
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
                                            child: Text(l.leaderBackToRewards),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ).whenComplete(() {
                                  ref
                                      .read(navbarVisibleProvider.notifier)
                                      .show();
                                });
                              },
                              icon: const Icon(
                                Icons.confirmation_num_outlined,
                                size: 18,
                              ),
                              label: Text(l.leaderClaimVoucher),
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
                                    l.leaderEarnMoreTokens(
                                      voucherThreshold - tokens,
                                    ),
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
                        l.leaderShopperBadges,
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
                        .map(
                          (badge) => _liveBadgeCard(
                            badge,
                            theme,
                            tokens: tokens,
                            approvedSubmissions:
                                stats?.approvedSubmissions ?? 0,
                            currentStreak: streak.currentStreak,
                            accuracyRating: stats?.accuracyRating ?? 100,
                          ),
                        )
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
                        l.leaderTodaysChallenges,
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
                                      ? l.leaderChallengeDone(
                                          dailyChallenge.bonusTokens,
                                        )
                                      : l.leaderChallengeBonus(
                                          dailyChallenge.bonusTokens,
                                        ),
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
                              l.leaderChallengeProgress(
                                dailyChallenge.progressCount,
                                dailyChallenge.targetCount,
                              ),
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
                        l.leaderDubaiLeaderboard,
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

              if (hallOfFame.isNotEmpty)
                SliverToBoxAdapter(child: _hallOfFameCard(hallOfFame, theme)),

              // Clear the floating glass navbar (height + margin + safe area)
              // so the last card rests fully visible instead of under the bar.
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: 110 + MediaQuery.of(context).padding.bottom,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // FR-45: Hall of Fame — previous month's top 3 sourcers.
  Widget _hallOfFameCard(List<LeaderboardUser> hof, ThemeData theme) {
    final l = AppLocalizations.of(context)!;
    const medals = ['🥇', '🥈', '🥉'];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.amberLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.amberAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                l.leaderHallOfFame,
                style: AppFonts.display(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            l.leaderTopChampions,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          ...List.generate(hof.length, (i) {
            final user = hof[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Text(
                    i < medals.length ? medals[i] : '${i + 1}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  Text(
                    '${user.tokens} 🪙',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.forestDeep,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Clean monochrome line icon per badge — replaces the emoji set, which read
  /// as generic/AI. One restrained icon language across all badges.
  IconData _badgeIcon(String id) {
    switch (id) {
      case 'first_submission':
        return Icons.sell_outlined;
      case 'streak_7':
        return Icons.local_fire_department_outlined;
      case 'streak_30':
        return Icons.calendar_today_outlined;
      case 'first_request':
        return Icons.search_rounded;
      case 'accuracy_90':
        return Icons.verified_outlined;
      case 'voucher_earned':
        return Icons.card_giftcard_outlined;
      default:
        return Icons.workspace_premium_outlined;
    }
  }

  Widget _liveBadgeCard(
    UserBadge badge,
    ThemeData theme, {
    required int tokens,
    required int approvedSubmissions,
    required int currentStreak,
    required double accuracyRating,
  }) {
    final unlocked = badge.unlocked;
    const accent = AppTheme.forestDeep;
    return GestureDetector(
      onTap: () => _showBadgeDetails(
        badge,
        tokens: tokens,
        approvedSubmissions: approvedSubmissions,
        currentStreak: currentStreak,
        accuracyRating: accuracyRating,
      ),
      child: Container(
        width: 132,
        // Directional margin: cards flow start→end, mirrored under Arabic RTL.
        margin: const EdgeInsetsDirectional.only(end: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: unlocked
                ? accent.withValues(alpha: 0.22)
                : const Color(0xFFEDEDED),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: unlocked
                    ? accent.withValues(alpha: 0.08)
                    : const Color(0xFFF4F4F4),
                shape: BoxShape.circle,
              ),
              // Locked badges show a single lock glyph — unambiguous, no overlay.
              child: Icon(
                unlocked ? _badgeIcon(badge.id) : Icons.lock_outline_rounded,
                size: 22,
                color: unlocked ? accent : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: unlocked ? AppTheme.textDark : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                height: 1.3,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(
    UserBadge badge, {
    required int tokens,
    required int approvedSubmissions,
    required int currentStreak,
    required double accuracyRating,
  }) {
    final progress = _badgeProgress(
      badge.id,
      tokens: tokens,
      approvedSubmissions: approvedSubmissions,
      currentStreak: currentStreak,
      accuracyRating: accuracyRating,
    );
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: badge.unlocked
                          ? AppTheme.forestDeep.withValues(alpha: 0.09)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      badge.unlocked
                          ? _badgeIcon(badge.id)
                          : Icons.lock_outline_rounded,
                      color: badge.unlocked
                          ? AppTheme.forestDeep
                          : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badge.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          badge.unlocked ? 'Unlocked' : 'Still locked',
                          style: TextStyle(
                            color: badge.unlocked
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                progress.message,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.value,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.forestDeep,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                progress.label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      },
    );
  }

  _BadgeProgress _badgeProgress(
    String badgeId, {
    required int tokens,
    required int approvedSubmissions,
    required int currentStreak,
    required double accuracyRating,
  }) {
    switch (badgeId) {
      case 'first_submission':
        return _BadgeProgress(
          value: approvedSubmissions >= 1 ? 1 : 0,
          label: '$approvedSubmissions / 1 approved price',
          message: approvedSubmissions >= 1
              ? 'Nice. Your first approved price is done.'
              : 'Submit one clear shelf price. Once an admin approves it, this badge unlocks and your tokens arrive.',
        );
      case 'streak_7':
        return _BadgeProgress(
          value: (currentStreak / 7).clamp(0.0, 1.0),
          label: '$currentStreak / 7 days',
          message:
              'Share at least one approved price each day for 7 days in a row.',
        );
      case 'streak_30':
        return _BadgeProgress(
          value: (currentStreak / 30).clamp(0.0, 1.0),
          label: '$currentStreak / 30 days',
          message:
              'Keep the habit going: one approved price per day for 30 days.',
        );
      case 'first_request':
        return const _BadgeProgress(
          value: 0,
          label: 'Fulfill 1 request',
          message:
              'Open the Active Request Board, pick a shopper request, and submit that price.',
        );
      case 'accuracy_90':
        return _BadgeProgress(
          value: (accuracyRating / 90).clamp(0.0, 1.0),
          label: '${accuracyRating.round()}% / 90% accuracy',
          message:
              'Keep prices accurate and photos clear. Stay at 90% accuracy or higher.',
        );
      case 'voucher_earned':
        return _BadgeProgress(
          value: (tokens / 500).clamp(0.0, 1.0),
          label: '$tokens / 500 tokens',
          message:
              'Earn 500 tokens from approved prices and bonuses to unlock your first voucher.',
        );
      default:
        return const _BadgeProgress(
          value: 0,
          label: 'Keep contributing',
          message: 'Keep sharing useful prices to unlock this badge.',
        );
    }
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

class _BadgeProgress {
  final double value;
  final String label;
  final String message;

  const _BadgeProgress({
    required this.value,
    required this.label,
    required this.message,
  });
}
