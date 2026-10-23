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
import 'package:dealsouk/features/tokens/domain/daily_challenge.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/features/requests/presentation/request_board_view.dart';
import 'package:dealsouk/core/design/design.dart';
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

    final summary = _summaryCard(
      l,
      profile.name,
      profile.avatarUrl,
      tokens,
      voucherThreshold,
      userRank,
      streak.currentStreak,
    );
    final challenge = _challengeCard(l, dailyChallenge);
    final badgeRow = _badgeSection(
      l,
      badges,
      tokens: tokens,
      approved: stats?.approvedSubmissions ?? 0,
      streak: streak.currentStreak,
      accuracy: stats?.accuracyRating ?? 100,
    );
    final board = _boardSection(l, rankedLeaderboard, hallOfFame);
    final wide = context.isExpanded;

    final Widget content;
    if (_showRequestBoard) {
      content = const RequestBoardView();
    } else if (wide) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                summary,
                const SizedBox(height: 20),
                challenge,
                const SizedBox(height: 24),
                badgeRow,
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(flex: 5, child: board),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          summary,
          const SizedBox(height: 16),
          challenge,
          const SizedBox(height: 24),
          badgeRow,
          const SizedBox(height: 24),
          board,
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: PageContainer(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l.leaderRewardsTitle,
                      style: AppFonts.display(
                        fontSize: wide ? 32 : 26,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: DsSegmented(
                        labels: [
                          l.leaderToggleStreaks,
                          l.leaderToggleRequestBoard,
                        ],
                        selected: _showRequestBoard ? 1 : 0,
                        onChanged: (i) =>
                            setState(() => _showRequestBoard = i == 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  content,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Tokens, rank and voucher progress ───────────────────────────────────
  Widget _summaryCard(
    AppLocalizations l,
    String name,
    String avatarUrl,
    int tokens,
    int threshold,
    int rank,
    int streakDays,
  ) {
    final canClaim = tokens >= threshold;
    return DsCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DsAvatar(name, size: 56, photoUrl: avatarUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.display(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        DsTag(
                          rank > 0
                              ? l.leaderRankNumber(rank)
                              : l.leaderRankUnknown,
                          tone: DsTone.warn,
                          icon: Icons.stars_rounded,
                        ),
                        if (streakDays > 0)
                          DsTag(
                            l.leaderDayStreak(streakDays),
                            tone: DsTone.warn,
                            icon: Icons.local_fire_department_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$tokens',
                    style: AppFonts.display(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.forestDeep,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    l.leaderTokensLabel,
                    style: AppFonts.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.leaderVoucherName,
                  style: AppFonts.body(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              Text(
                l.leaderTokenProgress(tokens, threshold),
                style: AppFonts.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.forestDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DsProgressBar(value: tokens / threshold, height: 12),
          const SizedBox(height: 14),
          if (canClaim)
            DsButton(
              label: l.leaderClaimVoucher,
              style: DsButtonStyle.accent,
              icon: Icons.confirmation_num_outlined,
              onPressed: () => _claimVoucher(l, threshold),
            )
          else
            DsBanner(l.leaderEarnMoreTokens(threshold - tokens)),
        ],
      ),
    );
  }

  void _claimVoucher(AppLocalizations l, int threshold) {
    // Deduct tokens and log transaction
    ref.read(userTokensProvider.notifier).deductTokens(threshold);
    ref
        .read(userTransactionsProvider.notifier)
        .addTransaction(-threshold, l.leaderVoucherRedeemed);

    ref.read(navbarVisibleProvider.notifier).hide();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppTheme.background,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 520),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final l = AppLocalizations.of(context)!;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.good,
                  size: 64,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.leaderVoucherClaimedTitle,
                textAlign: TextAlign.center,
                style: AppFonts.display(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.leaderVoucherClaimedBody,
                textAlign: TextAlign.center,
                style: AppFonts.body(
                  fontSize: 15,
                  height: 1.4,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 20),
              DsCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Decorative barcode lines.
                    ExcludeSemantics(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(24, (i) {
                            final w = (i % 3 == 0)
                                ? 4.0
                                : (i % 2 == 0)
                                ? 2.0
                                : 1.0;
                            return Container(
                              width: w,
                              height: 48,
                              margin: EdgeInsets.only(
                                right: (i % 4 == 0) ? 3.0 : 1.5,
                              ),
                              color: AppTheme.ink,
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SelectableText(
                      'DS-50-UCOOP-8X92',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: AppTheme.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              DsButton(
                label: l.leaderBackToRewards,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      ref.read(navbarVisibleProvider.notifier).show();
    });
  }

  // ── Daily challenge ─────────────────────────────────────────────────────
  Widget _challengeCard(AppLocalizations l, DailyChallenge c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsSectionHeader(l.leaderTodaysChallenges),
        const SizedBox(height: 8),
        DsCard(
          onTap: () => context.push('/submit-price'),
          semanticLabel: c.description,
          color: c.completed ? AppTheme.goodLight : Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.completed
                          ? AppTheme.forestDeep
                          : AppTheme.limeAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      c.completed
                          ? Icons.check_rounded
                          : Icons.flag_circle_outlined,
                      color: c.completed ? Colors.white : AppTheme.ink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      c.description,
                      style: AppFonts.body(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DsTag(
                c.completed
                    ? l.leaderChallengeDone(c.bonusTokens)
                    : l.leaderChallengeBonus(c.bonusTokens),
                tone: c.completed ? DsTone.good : DsTone.warn,
              ),
              if (!c.completed) ...[
                const SizedBox(height: 12),
                DsProgressBar(
                  value: c.progressCount / c.targetCount,
                  color: AppTheme.forestDeep,
                ),
                const SizedBox(height: 6),
                Text(
                  l.leaderChallengeProgress(c.progressCount, c.targetCount),
                  style: AppFonts.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Badges ──────────────────────────────────────────────────────────────
  Widget _badgeSection(
    AppLocalizations l,
    List<UserBadge> badges, {
    required int tokens,
    required int approved,
    required int streak,
    required double accuracy,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsSectionHeader(l.leaderShopperBadges),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final b in badges)
                  _liveBadgeCard(
                    b,
                    tokens: tokens,
                    approvedSubmissions: approved,
                    currentStreak: streak,
                    accuracyRating: accuracy,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Leaderboard + Hall of Fame ──────────────────────────────────────────
  Widget _boardSection(
    AppLocalizations l,
    List<LeaderboardUser> ranked,
    List<LeaderboardUser> hallOfFame,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsSectionHeader(l.leaderDubaiLeaderboard),
        const SizedBox(height: 8),
        for (final user in ranked)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _rankRow(user),
          ),
        if (hallOfFame.isNotEmpty) ...[
          const SizedBox(height: 12),
          _hallOfFameCard(hallOfFame),
        ],
      ],
    );
  }

  Widget _rankRow(LeaderboardUser user) {
    final isMe = user.isCurrentUser;
    return DsCard(
      selected: isMe,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _getRankColor(user.rank),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${user.rank}',
              style: AppFonts.display(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.body(
                fontSize: 16,
                fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                color: isMe ? AppTheme.forestDeep : AppTheme.ink,
              ),
            ),
          ),
          if (user.streak > 0) ...[
            const Icon(
              Icons.local_fire_department_rounded,
              color: AppTheme.warnText,
              size: 18,
            ),
            Text(
              '${user.streak}',
              style: AppFonts.body(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.warnText,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            '${user.tokens}',
            style: AppFonts.display(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.bolt_rounded, color: AppTheme.amberAccent),
        ],
      ),
    );
  }

  // FR-45: Hall of Fame — previous month's top 3 sourcers.
  Widget _hallOfFameCard(List<LeaderboardUser> hof) {
    final l = AppLocalizations.of(context)!;
    const medals = ['🥇', '🥈', '🥉'];
    return DsCard(
      color: AppTheme.amberLight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏆  ${l.leaderHallOfFame}',
            style: AppFonts.display(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l.leaderTopChampions,
            style: AppFonts.body(fontSize: 14, color: AppTheme.textLight),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < hof.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Text(
                    i < medals.length ? medals[i] : '${i + 1}',
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hof[i].name,
                      style: AppFonts.body(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                  Text(
                    '${hof[i].tokens} 🪙',
                    style: AppFonts.body(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.forestDeep,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Clean monochrome line icon per badge.
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
    UserBadge badge, {
    required int tokens,
    required int approvedSubmissions,
    required int currentStreak,
    required double accuracyRating,
  }) {
    final unlocked = badge.unlocked;
    return Container(
      width: 148,
      margin: const EdgeInsetsDirectional.only(end: 10),
      child: DsCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        semanticLabel: '${badge.name}, ${unlocked ? 'unlocked' : 'locked'}',
        onTap: () => _showBadgeDetails(
          badge,
          tokens: tokens,
          approvedSubmissions: approvedSubmissions,
          currentStreak: currentStreak,
          accuracyRating: accuracyRating,
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: unlocked ? AppTheme.emeraldLight : AppTheme.sand2,
                shape: BoxShape.circle,
              ),
              child: Icon(
                unlocked ? _badgeIcon(badge.id) : Icons.lock_outline_rounded,
                size: 26,
                color: unlocked ? AppTheme.forestDeep : AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.body(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: unlocked ? AppTheme.ink : AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.body(
                fontSize: 12,
                height: 1.3,
                color: AppTheme.textLight,
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
        return AppTheme.sand2;
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
